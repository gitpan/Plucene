package Plucene::Index::SegmentTermEnum;

=head1 NAME 

Plucene::Index::SegmentTermEnum - Segment term enum

=head1 SYNOPSIS

	my $seg_term_enum = Plucene::Index::SegmentTermsEnum
	 	->new(  Plucene::Store::InputStream $i, 
			Plucene::Index::FieldInfos  $fi, 
			$is_index);

	my $clone = $seg_term_info->clone;

	my Plucene::Index::Term $term = $seg_term_enum->read_term;

	$seg_term_info->seek($ptr, $position, $term, $term_info);
	$seg_term_enum->prev;
	$seg_term_enum->next;

=head1 DESCRIPTION

This is the segment term enum class.

=head1 METHODS

=cut

use strict;
use warnings;

use Carp qw/confess/;

use Plucene::Index::FieldInfos;
use Plucene::Index::TermInfo;
use Plucene::Index::Term;

use Class::HasA ([qw(doc_freq freq_pointer prox_pointer)] => "term_info");

use base 'Class::Accessor::Fast';

__PACKAGE__->mk_accessors(qw(term term_info index_pointer size position));

=head2 new

	my $seg_term_enum = Plucene::Index::SegmentTermsEnum
	 	->new(  Plucene::Store::InputStream $i, 
			Plucene::Index::FieldInfos  $fi, 
			$is_index);

=head2 term / term_info / index_pointer / size / position

Get / set these attributes.
			
=cut

# term_info must return a clone

sub new {
	my ($class, $i, $fis, $is_i) = @_;
	my $self = bless {
		input       => $i,
		field_infos => $fis,
		is_index    => $is_i,
		position    => -1,
		term        => Plucene::Index::Term->new(),
		term_info   => Plucene::Index::TermInfo->new(),
		size        => $i->read_int
	}, $class;
	confess("SIZE IS 0") unless $self->{size};
	$self;

}

=head2 clone

	my $clone = $seg_term_info->clone;

=cut

sub clone {
	my $self = shift;
	my $clone = bless { %$self, input => $self->{input}->clone, }, ref $self;
	if ($self->{term}) { $clone->{buffer} = $self->{term}->text }
	$clone;
}

=head2 seek

	$seg_term_info->seek($ptr, $position, $term, $term_info);

=cut

sub seek {
	my ($self, $ptr, $p, $t, $ti) = @_;
	$self->{input}->seek($ptr, 0);
	$self->{position} = $p;
	$self->{term}     = $t;
	undef $self->{prev};
	$self->{term_info}->copy_in($ti);
	$self->{buffer} = $t->text;
}

=head2 prev / next

	$seg_term_enum->prev;
	$seg_term_enum->next;

=cut

sub prev { return shift->{prev} }

sub next {
	my $self = shift;
	if ($self->{position}++ >= $self->{size} - 1) {
		undef $self->{term};
		return;
	}
	$self->{prev} = $self->{term};
	$self->{term} = $self->read_term();
	$self->doc_freq($self->{input}->read_vint);
	$self->{term_info}->{freq_pointer} += $self->{input}->read_vlong;
	$self->{term_info}->{prox_pointer} += $self->{input}->read_vlong;

	if ($self->{is_index}) {
		$self->{index_pointer} += $self->{input}->read_vlong;
	}
	return 1;
}

=head2 read_term

	my Plucene::Index::Term $term = $seg_term_enum->read_term;

=cut

sub read_term {
	my $self   = shift;
	my $start  = $self->{input}->read_vint();
	my $length = $self->{input}->read_vint();
	$self->{buffer} ||= " " x $length;
	$self->{input}->read(substr($self->{buffer}, $start, $length), $length);
	$self->{buffer} = substr($self->{buffer}, 0, $start + $length);
	my $field      = $self->{input}->read_vint();
	my $field_name = $self->{field_infos}->field_name($field);
	return Plucene::Index::Term->new({
			text  => $self->{buffer},
			field => $field_name,
		});
}

1;
