package Plucene::Index::FieldsWriter;

=head1 NAME 

Plucene::Index::FieldsWriter - writes Fields to a Document

=head1 SYNOPSIS

	my $writer = Plucene::Index::FieldsWriter->new(
		$dir_name, $segment, $field_infos);

	$writer->add_document(Plucene::Document $doc);

=head1 DESCRIPTION

This class add documents to the appropriate files.

=head1 METHODS

=cut

use strict;
use warnings;

use File::Spec::Functions qw(catfile);

use Plucene::Store::OutputStream;
use Plucene::Index::FieldInfos;

=head2 new

	my $writer = Plucene::Index::FieldsWriter->new(
		$dir_name, $segment, $field_infos);

This will create a new Plucene::Index::FieldsWriter object with the passed
directory name, segment and field infos.
		
=cut

sub new {
	my ($self, $d, $segment, $fn) = @_;
	bless {
		field_infos   => $fn,
		segment       => $segment,
		fields_stream => (
			Plucene::Store::OutputStream->new(
				catfile($d, "$segment.fdt") || die $!
			)
		),
		index_stream => (
			Plucene::Store::OutputStream->new(
				catfile($d, "$segment.fdx") || die $!
			)
		),
	}, $self;
}

=head2 add_document

	$writer->add_document(Plucene::Document $doc);

This will add the passed Plucene::Document.

=cut

sub add_document {
	my ($self, $doc) = @_;
	$self->{index_stream}->write_long($self->{fields_stream}->tell);
	my $stored = 0;
	my @stored = grep $_->is_stored, $doc->fields;
	$self->{fields_stream}->write_vint(scalar @stored);
	for my $field (@stored) {
		$self->{fields_stream}
			->write_vint($self->{field_infos}->field_number($field->name));
		$self->{fields_stream}->print(chr($field->is_tokenized));
		$self->{fields_stream}->write_string($field->string);
	}
}

1;
