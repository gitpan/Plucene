package Plucene::Store::InputStream;

=head1 NAME 

Plucene::Store::InputStream - a random-access input stream

=head1 SYNOPSIS

	# isa IO::File

=head1 DESCRIPTION

A random-access input stream.Used for all Plucene index input operations.

=head1 METHODS

=cut

use strict;
use warnings;

use Carp qw(confess);
use File::Spec::Functions;
use Cwd;
use IO::File;
use Class::HasA ([qw/ read seek tell getc print eof close /] => "fh");

=head2 new

=cut

sub new {
	my ($self, $filename, $mode) = @_;
	$self = ref $self || $self;
	$mode ||= "r";
	my $abs = canonpath($filename);
	my $fh = IO::File->new($abs, $mode) or die "$self, $mode: $filename $!";
	bless { fh => $fh, path => $abs, mode => $mode }, $self;
}

=head2 fh

The filehandle

=cut

sub fh { $_[0]->{fh} }

=head2 clone

This will return a clone of this stream.

=cut

sub clone {
	my $orig = shift;
	my $clone = $orig->new($orig->{path}, $orig->{mode});
	$clone->seek($orig->tell, 0);
	return $clone;
}

=head2 read_byte

This will read and return a single byte.

=cut

sub read_byte {
	my $self = shift;
	confess("Unexpectedly hit EOF") if $self->eof;
	my $pos  = $self->tell;
	my $byte = ord $self->getc;
	return $byte;
}

=head2 read_int

This will read four bytes and return an integer.

=cut

sub read_int {
	my $self = shift;
	my $buf  = "\0" x 4;
	$self->read($buf, 4);
	return unpack("N", $buf);
}

=head2 read_vint

This will read an integer stored in a variable-length format.

=cut

sub read_vint {
	my $self = shift;
	my $b    = $self->read_byte();
	my $i    = $b & 0x7F;
	for (my $s = 7 ; ($b & 0x80) != 0 ; $s += 7) {
		$b = $self->read_byte();
		$i |= ($b & 0x7F) << $s;
	}
	return $i;
}

=head2 read_vlong

This will read a long and stored in variable-length format

=cut

*read_vlong = *read_vint;    # Perl is type-agnostic. ;)

=head2 read_string

This will read a string.

=cut

sub read_string {
	my $self   = shift;
	my $length = $self->read_vint();
	my $utf8;
	$self->read($utf8, $length);
	use Encode qw(_utf8_on);    # Magic
	_utf8_on($utf8);
	return $utf8;
}

=head2 read_long

This will read eight bytes and return a long.

=cut

sub read_long {
	my $self  = shift;
	my $int_a = $self->read_int;
	my $int_b = $self->read_int;    # Order is important!
	return (($int_a << 32) | ($int_b & 0xFFFFFFFF));
}

1;
