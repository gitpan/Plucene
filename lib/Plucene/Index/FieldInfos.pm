package Plucene::Index::FieldInfos;

=head1 NAME 

Plucene::Index::FieldInfos - a collection of FieldInfo objects

=head1 SYNOPSIS

	my $fis = Plucene::Index::FieldInfos->new($dir_name);
	my $fis = Plucene::Index::FieldInfos->new($dir_name, $file);

	$fis->add(Plucene::Document $doc, $indexed);
	$fis->add(Plucene::Index::FieldInfos $other_fis, $indexed);
	$fis->add($name, $indexed);

	$fis->write($path);

	my @fields = $fis->fields;

	my $field_number = $fis->field_number($name);
	my   $field_info = $fis->field_info($name);
	my   $field_name = $fis->field_name($number);
	my   $num_fields = $fis->size;
	

=head1 DESCRIPTION

This is a collection of field info objects, which happen to live in 
the field infos file. 

=head1 METHODS

=cut

use strict;
use warnings;

use Carp qw(confess cluck);
use File::Spec::Functions qw(catfile);

use Plucene::Document;
use Plucene::Document::Field;
use Plucene::Index::FieldInfo;
use Plucene::Store::InputStream;
use Plucene::Store::OutputStream;

=head2 new

	my $fis = Plucene::Index::FieldInfos->new($dir_name);
	my $fis = Plucene::Index::FieldInfos->new($dir_name, $file);

This will create a new Plucene::Index::FieldInfos object with the passed
directory and optional filename.
	
=cut

sub new {
	my ($class, $dir, $file) = @_;
	my $self = bless {}, $class;
	if ($file) {
		$self->_read(Plucene::Store::InputStream->new(catfile($dir, $file)));
	} else {
		$self->_add_internal("", 0);
	}
	return $self;
}

=head2 add

	$fis->add(Plucene::Document $doc, $indexed);
	$fis->add(Plucene::Index::FieldInfos $other_fis, $indexed);
	$fis->add($name, $indexed);

This will add the fields from a Plucene::Document or a 
Plucene::Index::FieldsInfos to the field infos file.

It is also possible to pass the name of a field and have it added
to the file.
	
=cut

sub add {
	my ($self, $obj, $indexed) = @_;
	if ( UNIVERSAL::isa($obj, "Plucene::Document")
		or UNIVERSAL::isa($obj, "Plucene::Index::FieldInfos")) {
		$self->add($_->name, $_->is_indexed) for $obj->fields;
		return;
	}
	if (ref $obj) { confess "Don't yet know how to handle a $obj" }
	my $name = $obj;                       # For clarity. :)
	my $fi   = $self->field_info($name);
	if (!$fi) { $self->_add_internal($name, $indexed); }
	else { $fi->is_indexed($indexed); }
}

sub _add_internal {
	my ($self, $name, $indexed) = @_;
	my $fi = Plucene::Index::FieldInfo->new({
			name       => $name,
			is_indexed => $indexed,
			number     => 0
		});
	push @{ $self->{bynumber} }, $fi;
	$fi->number($#{ $self->{bynumber} });
	$self->{byname}{$name} = $fi;
}

=head2 field_number

	my $field_number = $fis->field_number($name);

This will return the field number of the field with $name. If there is 
no match, then -1 is returned.
	
=cut

sub field_number {
	my ($self, $name) = @_;
	return -1 unless defined $name;
	my $field = $self->{byname}{$name};
	return $field ? $field->number : -1;
}

=head2 fields

	my @fields = $fis->fields;

This will return all the fields.

=cut

sub fields { return @{ shift->{bynumber} } }

=head2 field_info

	my $field_info = $fis->field_info($name);

This will return the field info for the field called $name.

=cut

sub field_info {

	# Please ensure nothing in the code tries passing this a number. :(
	my ($self, $name) = @_;
	return $self->{byname}{$name};
}

=head2 field_name

	my $field_name = $fis->field_name($number);

This will return the field name for the field whose number is $number.

=cut

sub field_name {
	my ($self, $number) = @_;
	return $self->{bynumber}[$number]->name;
}

=head2 size 

	my $num_fields = $fis->size;

This returns the number of field info objects.

=cut

sub size { return scalar shift->fields }

=head2 write

	$fis->write($path);

This will write the field info objects to $path.

=cut

# Called by DocumentWriter->add_document and
# SegmentMerger->merge_fields
sub write {
	my ($self, $path) = @_;
	my $output = Plucene::Store::OutputStream->new($path);
	$output->write_vint(scalar @{ $self->{bynumber} });
	for my $fi (@{ $self->{bynumber} }) {
		$output->write_string($fi->name);
		$output->print(chr($fi->is_indexed ? 1 : 0));
	}
}

sub _read {
	my ($self, $stream) = @_;
	cluck("read called without stream") unless $stream;
	my $size = $stream->read_vint;
	$self->_add_internal($stream->read_string, $stream->read_byte)
		for 1 .. $size;
}

1;
