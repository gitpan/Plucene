#!/usr/bin/perl

# This tests that Unicode data can be written and retrieved successfully.

use strict;
use warnings;

use Test::More tests => 2;

use Plucene::TestCase;

SKIP: {
	skip "Encode works on 5.7 or greater", 2 if $] >= 5.007;
	$ANALYZER = "Plucene::Analysis::WhitespaceAnalyzer";

	new_index {
		add_document(text => "bar foo baz");
		add_document(text => "bar f\x{f2}o baz");
		add_document(text => "bar f\x{14d}o baz");
	};

	my $hits = search("text:f\x{14d}o");
	my @ids = sort map $_->{id}, @{ $hits->{hit_docs} };
	is_deeply(\@ids, [2], "Right documents");
	$hits = search("text:f\x{f2}o");
	@ids = sort map $_->{id}, @{ $hits->{hit_docs} };
	is_deeply(\@ids, [1], "Right documents");
}
