package Plucene::Index::DocumentWriter;

=head1 NAME 

Plucen::Index::DocumentWriter - the document writer

=head1 SYNOPSIS

	my $writer = Plucene::Index::DocumentWriter
		->new($directory, $analyser, $max_field_length);

	$writer->add_document($segment, $doc);

=head1 DESCRIPTION

This is the document writer class.

=head2 METHODS

=cut

use strict;
use warnings;

use Plucene::Index::FieldInfos;
use Plucene::Index::FieldsWriter;
use Plucene::Index::Term;
use Plucene::Index::TermInfo;
use Plucene::Index::TermInfosWriter;
use Plucene::Search::Similarity;
use Plucene::Store::OutputStream;

use File::Spec::Functions qw(catfile);
use IO::Scalar;

=head2 new

	my $writer = Plucene::Index::DocumentWriter
		->new($directory, $analyser, $max_field_length);

This will create a new Plucene::Index::DocumentWriter object with the passed
in arguments.

=cut

sub new {
	my ($self, $d, $a, $mfl) = @_;
	bless {
		directory        => $d,
		analyzer         => $a,
		max_field_length => $mfl,
		postings         => {},
	}, $self;
}

=head2 add_document

	$writer->add_document($segment, $doc);

=cut

sub add_document {
	my ($self, $segment, $doc) = @_;
	my $fi = Plucene::Index::FieldInfos->new();
	$fi->add($doc);
	$fi->write(catfile($self->{directory}, $segment . ".fnm"));
	$self->{field_infos} = $fi;

	my $fw =
		Plucene::Index::FieldsWriter->new($self->{directory}, $segment, $fi);
	$fw->add_document($doc);
	$self->{postings}      = {};
	$self->{field_lengths} = [];
	$self->_invert_document($doc);
	my @postings = sort {

		#  $a->term->_cmp($b->term)
		$a->{term}->{field} cmp $b->{term}->{field}
			|| $a->{term}->{text} cmp $b->{term}->{text}
	} values %{ $self->{postings} };

	$self->_write_postings($segment, @postings);
	$self->_write_norms($doc, $segment);
}

sub _invert_document {
	my ($self, $doc) = @_;
	for my $field (grep $_->is_indexed, $doc->fields) {
		my $name = $field->name;
		my $fn   = $self->{field_infos}->field_number($name);
		my $pos  = $self->{field_lengths}->[$fn];
		if (!$field->is_tokenized) {
			$self->_add_position($name, $field->string, $pos++);
		} else {
			my $reader = $field->reader
				|| IO::Scalar->new(\$field->{string});
			my $stream = $self->{analyzer}->tokenstream({
					field  => $name,
					reader => $reader
				});
			while (my $t = $stream->next) {
				$self->_add_position($name, $t->text, $pos++);
				last if $pos > $self->{max_field_length};
			}
		}
		$self->{field_lengths}->[$fn] = $pos;
	}
}

sub _add_position {
	my ($self, $field, $text, $pos) = @_;
	my $ti = $self->{postings}->{"$field\0$text"};
	if ($ti) {
		$ti->{positions}->[ $ti->freq ] = $pos;
		$ti->{freq}++;
		return;
	}
	$self->{postings}->{"$field\0$text"} =
		Plucene::Index::Posting->new(
		Plucene::Index::Term->new({ field => $field, text => $text }), $pos);
}

sub _write_postings {
	my ($self, $segment, @postings) = @_;
	my $freq =
		Plucene::Store::OutputStream->new(
		catfile($self->{directory}, "$segment.frq"));
	my $prox =
		Plucene::Store::OutputStream->new(
		catfile($self->{directory}, "$segment.prx"));
	my $tis =
		Plucene::Index::TermInfosWriter->new($self->{directory}, $segment,
		$self->{field_infos});
	my $ti = Plucene::Index::TermInfo->new();

	for my $posting (@postings) {
		$ti->doc_freq(1);
		$ti->freq_pointer($freq->tell);
		$ti->prox_pointer($prox->tell);

		$tis->add($posting->term, $ti);
		my $f = $posting->freq;
		if ($f == 1) {    # Curious micro-optimization
			$freq->write_vint(1);
		} else {
			$freq->write_vint(0);
			$freq->write_vint($f);
		}
		my $last_pos  = 0;
		my $positions = $posting->positions;
		for my $j (0 .. $f) {
			my $pos = $positions->[$j] || 0;
			$prox->write_vint($pos - $last_pos);
			$last_pos = $pos;
		}
	}
	$tis->break_ref;
}

sub _write_norms {
	my ($self, $doc, $segment) = @_;
	for my $field (grep $_->is_indexed, $doc->fields) {
		my $fn = $self->{field_infos}->field_number($field->name);
		warn "Couldn't find field @{[ $field->name ]} in list [ @{[ map
			$_->name, $self->{field_infos}->fields]}]" unless $fn >= 0;
		my $norm =
			Plucene::Store::OutputStream->new(
			catfile($self->{directory}, "$segment.f$fn"));
		my $val      = $self->{field_lengths}[$fn];
		my $norm_val = Plucene::Search::Similarity->norm($val);
		$norm->print(chr($norm_val));
	}
}

package Plucene::Index::Posting;

use base 'Class::Accessor::Fast';

__PACKAGE__->mk_accessors(qw( term freq positions ));

sub new {
	my ($self, $term, $pos) = @_;
	return $self->SUPER::new({
			term      => $term,
			positions => [$pos],
			freq      => 1
		});
}

1;
