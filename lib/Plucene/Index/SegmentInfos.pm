package Plucene::Index::SegmentInfos;

=head1 NAME

Plucene::Index::SegmentInfos - A collection of SegmentInfo objects

=head1 SYNOPSIS

	my $segmentinfos = Plucene::Index::SegmentInfos->new;

	$segmentinfos->read($dir);
	$segmentinfos->write($dir);

	$segmentinfos->add_element(Plucene::Index::SegmentInfo $segment_info);

	my Plucene::Index::SegmentInfo @segment_info 
		= $segmentinfos->segments; 

=head1 DESCRIPTION

This is a collection of Plucene::Index::SegmentInfo objects

=head1 METHODS

=cut

use strict;
use warnings;

use Carp;
use File::Spec::Functions qw(catfile);

use Plucene::Index::SegmentInfo;
use Plucene::Store::InputStream;
use Plucene::Store::OutputStream;

=head2 new

	my $segmentinfos = Plucene::Index::SegmentInfos->new;

This will create a new (empty) Plucene::Index::SegmentInfos object.

=cut

sub new { bless { segments => [] }, shift }

=head2 read

	$segmentinfos->read($dir);

This will read the segments file from the passed directory.

=cut

sub read {
	my ($self, $directory) = @_;
	my $stream =
		Plucene::Store::InputStream->new(catfile($directory, "segments"));

	my $count    = $stream->read_int;
	my $segments = $stream->read_int;
	my @segs;
	push @segs, new Plucene::Index::SegmentInfo({
			name      => $stream->read_string,
			doc_count => $stream->read_int,
			dir       => $directory
		})
		for (1 .. $segments);
	$self->{segments} = \@segs;
	$self->{counter}  = $count;
}

=head2 write

	$segmentinfos->write($dir);

This will write the segments info file out.

=cut

sub write {
	my ($self, $directory) = @_;
	my $segfile = catfile($directory, "segments");
	my $output = Plucene::Store::OutputStream->new($segfile . ".new");
	$output->write_int($self->{counter});
	$output->write_int(scalar @{ $self->{segments} });
	for my $seg ($self->segments) {
		$output->write_string($seg->name);
		$output->write_int($seg->doc_count);
	}
	$output->close;
	rename($segfile . ".new", $segfile);
}

=head2 add_element

	$segmentinfos->add_element(Plucene::Index::SegmentInfo $segment_info);

This will add the passed Plucene::Index::SegmentInfo object..

=cut

sub add_element {
	my ($self, $seg) = @_;
	push @{ $self->{segments} }, $seg;
}

=head2 info

	my Plucene::Index::SegmentInfo $info 
		= $segmentinfos->info($segment_no);

This will return the Plucene::Index::SegmentInfo object at the passed 
segment number.

=cut

sub info {
	my ($self, $seg_no) = @_;
	return $self->{segments}->[$seg_no];
}

=head2 segments

	my Plucene::Index::SegmentInfo @segment_info 
		= $segmentinfos->segments; 

This returns all the Plucene::Index::SegmentInfo onjects in this segment.

=cut

sub segments { @{ shift->{segments} } }

1;
