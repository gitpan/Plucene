package Plucene::Index::SegmentMergeInfo;

=head1 NAME 

Plucene::Index::SegmentMergeInfo - Segment Merge information

=head1 SYNOPSIS

	my $seg_merge_info 
		= Plucene::Index::SegmentMergeInfo->new($b, $te, $r); 

	$seg_merge_info->next;

=head1 DESCRIPTION

This is the Plucene::Index::SegmentMergeInfo class.

=head1 METHODS

=cut

use strict;
use warnings;

use Plucene::Index::SegmentTermPositions;

use base 'Class::Accessor::Fast';

__PACKAGE__->mk_accessors(qw( base reader term_enum term postings doc_map));

use overload cmp => sub {
	my ($smi_a, $smi_b) = @_;
	$smi_a->term cmp $smi_b->term
		|| $smi_a->base <=> $smi_b->base;
	},
	fallback => 1;

=head2 new

	my $seg_merge_info = Plucene::Index::SegmentMergeInfo
		->new($base, Plucene::Index::TermEnum $te, $reader); 

This will create a new Plucene::Index::SegmentMergerInfo object.
		
=head2 base / reader / term_enum / term / postings / doc_map

Get / set these attributes.
		
=cut

sub new {
	my ($class, $b, $te, $r) = @_;
	my $self = $class->SUPER::new;
	$self->base($b);
	$self->reader($r);
	$self->term_enum($te);
	$self->term($te->term);
	$self->postings(Plucene::Index::SegmentTermPositions->new($r));
	if (my $del = $r->deleted_docs) {
		my $j;
		$self->doc_map([ map { $del->get($_) ? -1 : $j++ } 0 .. $r->max_doc ]);
	}
	return $self;
}

=head2 next

	$seg_merge_info->next;

=cut

sub next {
	my $self = shift;
	if ($self->term_enum->next) {
		$self->term($self->term_enum->term);
		return 1;
	}
	undef $self->{term};
	return;
}

1;
