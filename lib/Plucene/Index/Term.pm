package Plucene::Index::Term;

=head1 NAME 

Plucene::Index::Term - a word from text

=head1 SYNOPSIS

	my $term = Plucene::Index::Term->new({
			field => $field_name,
			text  => $text,
	});

	# with two Plucene::Index::Term objects you can do:
	
	if ($term1->eq($term2)) { ... }

	# etc
	
=head1 DESCRIPTION

A Term represents a word from text, and is the unit of search.  It is 
composed of two elements, the text of the word, as a string, and the 
name of the field that the text occured in, as a string.

Note that terms may represent more than words from text fields, but 
also things like dates, email addresses, urls, etc.

=head1 METHODS

=cut

use strict;
use warnings;
no warnings 'uninitialized';

use base 'Class::Accessor::Fast';
use Carp qw/croak/;

__PACKAGE__->mk_accessors(qw(field text));

sub _cmp {
	croak("Missing a Term object to compare:  @_") unless $_[0] and $_[1];
	($_[0]->field cmp $_[1]->field) || ($_[0]->text cmp $_[1]->text);
}

=head2 eq / ne / lt / gt / ge / le

Exactly what you would think they are.

=cut

sub eq { !_cmp(@_) }
sub ne { _cmp(@_) }
sub lt { _cmp(@_) == -1 }
sub gt { _cmp(@_) == 1 }
sub ge { _cmp(@_) >= 0 }
sub le { _cmp(@_) <= 0 }

1;
