package Plucene::Index::FieldInfo;

=head1 NAME 

Plucene::Index::FieldInfo - infomation on a Field in a Document

=head1 SYNOPSIS

	my $field_info = Plucene::Index::FieldInfo->new({
		name       => $name,
		is_indexed => $is_indexed,	
	});

=head1 DESCRIPTION

This holds information about a field.

=head1 METHODS

=cut

use strict;
use warnings;

use Carp qw(confess);

use base 'Class::Accessor::Fast';

=head2 name / is_indexed / number

Get / set these

=cut

__PACKAGE__->mk_accessors(qw(name is_indexed number));

=head2 new

	my $field_info = Plucene::Index::FieldInfo->new({
		name       => $name,
		is_indexed => $is_indexed,	
	});

This will create a new Plucene::Index::FieldInfo object using the passed
name and is_indexed flag.

=cut

1;
