package Plucene::Index::SegmentMerger;

=head1 NAME 

Plucene::Index::SegmentMerger - the Segment merger

=head1 SYNOPSIS

	my $merger = Plucene::Index::SegmentMerger->new();

	$merger->add(Plucene::Index::SegmentReader $reader);
	$merger->merge;

=head1 DESCRIPTION

This is the segment merger class.

=head1 METHODS

=cut

use strict;
use warnings;
no warnings 'uninitialized';

use Plucene::Index::FieldInfos;
use Plucene::Index::FieldsWriter;
use Plucene::Index::SegmentMergeInfo;
use Plucene::Index::TermInfosWriter;
use Plucene::Index::TermInfo;
use Plucene::Store::OutputStream;

use base 'Class::Accessor::Fast';

__PACKAGE__->mk_accessors(
	qw( dir name readers field_infos
		freq_output prox_output term_infos_writer queue )
);

=head2 new

	my $merger = Plucene::Index::SegmentMerger->new();

This will create a new Plucene::Index::SegmentMerger object.
	
=cut

sub new { shift->SUPER::new(@_, readers => []) }

=head2 add

	$merger->add(Plucene::Index::SegmentReader $reader);

=cut

sub add { push @{ $_[0]->{readers} }, $_[1] }

=head2 segment_reader

=cut

sub segment_reader { $_[0]->{readers}->[ $_[1] ] }

=head2 merge

	$merger->merge;

Perform the merging. After the merge, there will be no readers left
stored in the merger object.
	
=cut

sub merge {
	my $self = shift;
	$self->_merge_fields();
	$self->_merge_terms();
	$self->_merge_norms();
	$self->{readers} = [];
}

sub _merge_fields {
	my $self = shift;
	$self->{field_infos} = Plucene::Index::FieldInfos->new();
	$self->{field_infos}->add($_->field_infos) for @{ $self->{readers} };
	$self->{field_infos}->write("$self->{dir}/$self->{segment}.fnm");

	my $fw =
		Plucene::Index::FieldsWriter->new($self->{dir}, $self->{segment},
		$self->{field_infos});
	for my $reader (@{ $self->{readers} }) {
		$fw->add_document($_)
			foreach map $reader->document($_), grep !$reader->is_deleted($_),
			0 .. $reader->max_doc - 1;
	}
}

sub _merge_terms {
	my $self    = shift;
	my $segment = $self->{segment};
	$self->{freq_output} =
		Plucene::Store::OutputStream->new("$self->{dir}/$segment.frq");
	$self->{prox_output} =
		Plucene::Store::OutputStream->new("$self->{dir}/$segment.prx");
	$self->{term_infos_writer} =
		Plucene::Index::TermInfosWriter->new($self->{dir}, $segment,
		$self->{field_infos});
	$self->_merge_term_infos;
}

sub _merge_term_infos {
	my $self = shift;
	my $base = 0;

	my @queue;
	for my $reader (@{ $self->{readers} }) {
		my $smi =
			Plucene::Index::SegmentMergeInfo->new($base, $reader->terms, $reader);
		$base += $reader->num_docs;
		push @queue, $smi if $smi->next;
	}

	#  store every term in every reader/tmp segment in %pool
	my %pool;
	{
		my $index = 0;
		foreach my $smi (@queue) {
			while (my $term = $smi->term) {
				push(
					@{ $pool{ $term->{field} }->{ $term->{text} } },
					[ $term, $index, $smi->term_enum->term_info->clone ]);
				$smi->next;
			}
			++$index;
		}
	}

	# Now, by sorting our hash, we deal with each term in order:
	foreach my $field (sort keys %pool) {
		foreach my $term (sort keys %{ $pool{$field} }) {
			my @min = @{ $pool{$field}->{$term} };
			my ($fp, $pp) =
				($self->{freq_output}->tell, $self->{prox_output}->tell);

			# inlined append_postings
			my ($df, $last_doc);
			foreach my $item (@min) {
				my $smi      = $queue[ $item->[1] ];
				my $postings = $smi->postings;
				my $base     = $smi->base;
				my $docmap   = $smi->doc_map;
				my $ti       = $item->[2];
				$postings->seek($ti);
				while ($postings->next) {
					my $doc = $base + (
						$docmap
						? ($docmap->[ $postings->doc ] || 0)
						: $postings->doc
					);
					die "Docs out of order ($doc < $last_doc)" if $doc < $last_doc;
					my $doc_code = ($doc - $last_doc) << 1;
					$last_doc = $doc;
					my $freq = $postings->freq;
					if ($freq == 1) {
						$self->{freq_output}->write_vint($doc_code | 1);
					} else {
						$self->{freq_output}->write_vint($doc_code);
						$self->{freq_output}->write_vint($freq);
					}
					my $last_pos = 0;
					for (0 .. $freq - 1) {
						my $pos = $postings->next_position;
						$self->{prox_output}->write_vint($pos - $last_pos);
						$last_pos = $pos;
					}
					$df++;
				}    # end while there are postings
			}    # end foreach $smi (reader) that contains the current term

			# inlined _merge_term_info
			$self->{term_infos_writer}->add(
				$min[0]->[0],
				Plucene::Index::TermInfo->new({
						doc_freq     => $df,
						freq_pointer => $fp,
						prox_pointer => $pp
					}));
		}    # end foreach term
	}    # end foreach field

	$self->{term_infos_writer}->break_ref;
}

sub _merge_norms {
	my $self   = shift;
	my @fields = $self->{field_infos}->fields;
	for (0 .. $#fields) {
		my $fi = $fields[$_];
		next unless $fi->is_indexed;
		my $output =
			Plucene::Store::OutputStream->new(my $file =
				"$self->{dir}/$self->{segment}.f$_");
		for my $reader (@{ $self->{readers} }) {
			my $input = $reader->norm_stream($fi->name);
			for (0 .. $reader->max_doc - 1) {
				$output->print(chr($input ? $input->read_byte : 0))
					unless $reader->is_deleted($_);
			}
		}
	}
}

1;
