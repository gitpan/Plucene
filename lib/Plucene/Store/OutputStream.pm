package Plucene::Store::OutputStream;

=head1 NAME 

Plucene::Store::OutputStream - a random-access output stream

=head1 SYNOPSIS

	# isa Plucene::Store::InputStream

=head1 DESCRIPTION

This is an abstract class for output to a file in a Directory. 
A random-access output stream. 
Used for all Plucene index output operations.

=head1 METHODS

=cut

use strict;
use warnings;
no warnings 'uninitialized';

use base 'Plucene::Store::InputStream';    # And why not, indeed
use Encode qw(encode);
use constant BYTE => 2**8 - 1;
use constant INT  => 2**32 - 1;

=head2 new

Create a new Plucene::Store::OutputStream

=cut

sub new {
	my ($self, $file) = @_;
	shift->SUPER::new($file, "w");
}

=head2 write_byte

This will write a single byte.

=cut

sub write_byte {
	my ($self, $b) = @_;
	$self->print($b);
}

=head2 write_int

This will write an int as four bytes.

=cut

sub write_int {
	my ($self, $i) = @_;
	$self->print(pack("N", $i));
}

=head2 write_vint

This will write an int in a variable length format.

=cut

sub write_vint {
	my ($self, $i) = @_;
	$i += 0;
	while ($i & ~0x7f) {
		$self->print(chr(BYTE & (($i & 0x7f) | 0x80)));
		$i >>= 7;
	}
	$self->print(chr(BYTE & $i));
}

=head2 write_long

This will write a long as eight bytes.

=cut

sub write_long {
	my ($self, $i) = @_;
	$self->print(pack("NN", INT & ($i >> 32), INT & $i));
}

=head2 write_vlong

This will write a long in variable length format.

=cut

*write_vlong = *write_vint;

=head2 write_string

This will write a string.

=cut

sub write_string {
	my ($self, $s) = @_;
	$s = encode("utf8", $s) if $s =~ /[^\x00-\x7f]/;
	$self->write_vint(length $s);
	$self->print($s);
}

1;
