#!/usr/bin/perl -w

=head1 NAME 

t/compatibility01.t - Plucene <=> Lucene compatibility tests

=head1 DESCRIPTION

This will write an index using Lucene.pm, and search it using both
Lucene and Plucene.

=cut

use strict;
use warnings;

use Lucene;
use Lucene::QueryParser;
use Plucene::Search::HitCollector;
use Plucene::Search::IndexSearcher;
use Plucene::Analysis::SimpleAnalyzer;
use Plucene::Document;
use Plucene::Document::Field;
use Plucene::Index::Writer;

use Test::More tests => 8;
use File::Path;

use constant DIRECTORY => "/tmp/testindex/$$";

BEGIN { mkpath DIRECTORY }
END   { rmtree DIRECTORY }

#------------------------------------------------------------------------------
# Helper stuff
#------------------------------------------------------------------------------

sub data {
	return [
		wsc => { name => "Writing Solid Code" },
		rap => { name => "Rapid Development" },
		gui => { name => "GUI Bloopers" },
		ora => { name => "Using Oracle 8i" },
		app => { name => "Advanced Perl Programming" },
		xpe => { name => "Extreme Programming Explained" },
		boo => { name => "Boo-Hoo" },
		dbs => { name => "Designing From Both Sides of the Screen" },
		dbi => { name => "Programming the Perl DBI" },
	];
}

#------------------------------------------------------------------------------
# Indexing
#------------------------------------------------------------------------------

sub index_documents_Java {
	my $lucy = shift;
	my @data = @{ data() };
	while (my ($id, $terms) = splice @data, 0, 2) {
		$lucy->begin_write;
		$lucy->add($id, $terms);
		$lucy->end_write;
	}
	return $lucy;
}

sub index_documents_Perl {
	my @data   = @{ data() };
	my $writer =
		Plucene::Index::Writer->new(DIRECTORY,
		Plucene::Analysis::SimpleAnalyzer->new(), 1);
	while (my ($id, $terms) = splice @data, 0, 2) {
		my $doc = Plucene::Document->new;
		$doc->add(Plucene::Document::Field->Keyword(id => $id));
		$doc->add(Plucene::Document::Field->UnStored(%$terms));
		$writer->add_document($doc);
	}
	$writer->optimize();    # THIS IS NOT AN OPTIONAL STEP
}

#------------------------------------------------------------------------------
# Searching
#------------------------------------------------------------------------------

sub search_Java {
	my ($lucy, $sstring) = @_;
	return $lucy->search($sstring);
}

sub search_Perl {
	my ($plucy, $sstring) = @_;
	my $query = (parse_query($sstring))->to_plucene;
	my @docs;
	my $hc = Plucene::Search::HitCollector->new(
		collect => sub {
			my ($self, $doc, $score) = @_;
			push @docs, $plucy->doc($doc);
		});
	$plucy->search_hc($query, $hc);
	my @as_string = map $_->string, map $_->fields, @docs;
	return @as_string;
}

#------------------------------------------------------------------------------
# Tests
#------------------------------------------------------------------------------

my $lucy = Lucene->create(DIRECTORY);
index_documents_Java($lucy);

{    # Java Search on Java Index
	my @docs = search_Java($lucy => "name:perl");
	is @docs, 2, "2 results for searching for perl";
	is_deeply \@docs, [ "app", "dbi" ], "The correct ones";
}

my $plucy = Plucene::Search::IndexSearcher->new(DIRECTORY);

{    # Perl Search on Java Index
	my @docs = search_Perl($plucy => "name:perl");
	is @docs, 2, "2 results for searching for perl";
	is_deeply \@docs, [ "app", "dbi" ], "The correct ones";
}

#------------------------------------------------------------------------------
# Clean everything up
#------------------------------------------------------------------------------

rmtree DIRECTORY;
mkpath DIRECTORY;

#------------------------------------------------------------------------------
# Tests with Perl Index
#------------------------------------------------------------------------------

eval {
	system("chmod", "g+s", DIRECTORY);
	index_documents_Perl();
	my $lucy = Lucene->open(DIRECTORY) or die "Can't open directory: $!\n";

	SKIP: {    # Java Search on Perl Index
		skip "Java search on perl index currently broken", 2;
		my @docs = search_Java($lucy => "name:perl");
		is @docs, 2, "2 results for Java searching Perl";
		is_deeply \@docs, [ "app", "dbi" ], "The correct ones";
	}

	my $plucy = Plucene::Search::IndexSearcher->new(DIRECTORY);

	{          # Perl Search on Perl Index
		my @docs = search_Perl($plucy => "name:perl");
		is @docs, 2, "2 results for Perl searching Perl";
		is_deeply \@docs, [ "app", "dbi" ], "The correct ones";
	}

};

fail $@ if $@;
