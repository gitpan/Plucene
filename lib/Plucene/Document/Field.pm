package Plucene::Document::Field;

=head1 NAME 

Plucene::Document::Field - A field in a Plucene::Document

=head1 SYNOPSIS

	my $field = Plucene::Document::Field->Keyword($name, $string);
	my $field = Plucene::Document::Field->Text($name, $string);

	my $field = Plucene::Document::Field->UnIndexded($name, $string);
	my $field = Plucene::Document::Field->UnStored($name, $string);

=head1 DESCRIPTION

Each Plucene::Document is made up of Plucene::Document::Fields. Each of these
fields can be stored, indexed or tokenised.

=head1 METHODS

=cut

use strict;
use warnings;

use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors(
	qw(name string is_stored is_indexed is_tokenized reader));

use Carp qw(confess);

=head2 Keyword

	my $field = Plucene::Document::Field->Keyword($name, $string);

This will make a new Plucene::Document::Field object that is stored 
and indexed, but not tokenised..
	
=cut

sub Keyword {
	my ($self, $name, $string) = @_;
	return $self->new({
			name         => $name,
			string       => $string,
			is_stored    => 1,
			is_indexed   => 1,
			is_tokenized => 0
		});
}

=head2 UnIndexed

	my $field = Plucene::Document::Field->UnIndexded($name, $string);

This will make a new Plucene::Document::Field object that is stored, but 
not indexed or tokenised.
	
=cut

sub UnIndexed {
	my ($self, $name, $string) = @_;
	return $self->new({
			name         => $name,
			string       => $string,
			is_stored    => 1,
			is_indexed   => 0,
			is_tokenized => 0
		});
}

=head2 Text

	my $field = Plucene::Document::Field->Text($name, $string);

This will make a new Plucene::Document::Field object that is stored,
indexed and tokenised.
	
=cut

sub Text {
	my ($self, $name, $string) = @_;
	return $self->new({
			name         => $name,
			string       => $string,
			is_stored    => 1,
			is_indexed   => 1,
			is_tokenized => 1
		});
}

=head2 UnStored

	my $field = Plucene::Document::Field->UnStored($name, $string);

This will make a new Plucene::Document::Field object that isn't stored,
but is indexed and tokenised.

=cut

sub UnStored {
	my ($self, $name, $string) = @_;
	return $self->new({
			name         => $name,
			string       => $string,
			is_stored    => 0,
			is_indexed   => 1,
			is_tokenized => 1
		});
}

1;
