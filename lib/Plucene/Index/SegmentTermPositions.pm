package Plucene::Index::SegmentTermPositions;

=head1 NAME 

Plucene::Index::SegmentTermPositions - Segment term positions

=head1 SYNOPSIS

	# isa Plucene::Index::SegmentTermDocs

	$seg_term_poss->skipping_doc;

	my $next = $seg_term_poss->next_position;

=head1 DESCRIPTION

This is the segment term positions class.

=head1 METHODS

=cut

use strict;
use warnings;

use Carp;

use base 'Plucene::Index::SegmentTermDocs';

__PACKAGE__->mk_accessors(qw(prox_stream prox_count));

=head2 new

	my $seg_term_poss = Plucene::Index::SegmentTermPositions
		->new(Plucene::Index::SegmentReader $seg_reader);

=head2 prox_stream / prox_counbt

Get / set these attributes.

=cut

sub new {
	my $self = shift->SUPER::new(@_);
	$self->prox_stream($self->parent->prox_stream->clone);
	$self->prox_count($self->prox_count || 0);
	return $self;
}

sub _seek {
	my ($self, $ti) = @_;
	$self->SUPER::_seek($ti);
	if ($ti) { $self->prox_stream->seek($ti->prox_pointer, 0) }
	else { $self->{prox_count} = 0 }
}

=head2 next_position

	my $next = $seg_term_poss->next_position;

=cut

sub next_position {
	my $self = shift;
	$self->{prox_count}--;
	return $self->{position} += $self->prox_stream->read_vint;
}

=head2 skipping_doc

	$seg_term_poss->skipping_doc;

=cut

sub skipping_doc {
	my $self = shift;
	$self->prox_stream->read_vint for 1 .. $self->freq;
}

sub next {
	my $self = shift;
	$self->prox_stream->read_vint for 1 .. $self->prox_count;
	if ($self->SUPER::next()) {
		$self->prox_count($self->freq);
		$self->{position} = 0;
		return 1;
	}
	return;
}

=head2 read 

This should not be called

=cut

sub read { croak "'read' should not be called" }

1;
