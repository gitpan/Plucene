package Plucene::Index::TermInfo;

=head1 NAME

Plucene::Index::TermInfo - Information on an index term

=head1 SYNOPSIS

	my $term_info = Plucene::Index::TermInfo->new({
			doc_freq     => $doc_freq,
			freq_pointer => $freq_pointer,
			prox_pointer => $prox_pointer,
	});

=head1 DESCRIPTION

This class holds information about an index term.

=head1 METHODS

=cut

use strict;
use warnings;

use Carp;

use base 'Class::Accessor';

=head2 doc_freq / freq_pointer / prox_pointer

Get / set term info.

=cut

__PACKAGE__->mk_accessors(qw( doc_freq freq_pointer prox_pointer ));

=head2 copy_in 

	$term_info1->copy_in($term_info2);

This will make $term_info1 be the same as $term_info2.
	
=cut

sub copy_in {
	my ($self, $other) = @_;
	Carp::confess("copy_in needs a Plucene::Index::TermInfo object")
		unless UNIVERSAL::isa($other, ref $self);
	$self->doc_freq($other->doc_freq);
	$self->freq_pointer($other->freq_pointer);
	$self->prox_pointer($other->prox_pointer);
}

1;
