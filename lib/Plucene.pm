package Plucene;

=head1 NAME

Plucene - A Perl port of the Lucene search engine

=head1 SYNOPSIS

First, make your documents

	use Plucene::Document;
	use Plucene::Document::Field;

	my $doc = Plucene::Document->new;
	$doc->add(Plucene::Document::Field->Text("content", $content);
	$doc->add(Plucene::Document::Field->Text("author", "Your Name");
	...

Next, choose your analyser, and make an index writer.

	use Plucene::Index::Writer; 
	use Plucene::Analysis::SimpleAnalyzer;

	my $writer = Plucene::Index::Writer->new("my_index",
		Plucene::Analysis::SimpleAnalyzer->new(), 1);

Now write your documents into the index.

	$writer->add_document($doc);
	undef $writer; # close

When you come to search, parse the query and create a searcher:

	use Plucene::QueryParser;
	use Plucene::Analysis::SimpleAnalyzer;

	my $parser = Plucene::QueryParser->new({
		analyzer => Plucene::Analysis::SimpleAnalyzer->new(),
		default  => "text" # Default field for non-specified queries
	});
	my $query = $parser->parse('author:"Your Name"');

	my $searcher = Plucene::Search::IndexSearcher->new("my_index");

Decide what you're going to do with the results:

	use Plucene::Search::HitCollector;
	my @docs;
	my $hc = Plucene::Search::HitCollector->new(collect => sub {
		my ($self, $doc, $score)= @_;
		push @docs, $plucy->doc($doc);
	});

	$searcher->search_hc($query, $hc);

	# @docs is now a list of Plucene::Document objects.

=head1 DESCRIPTION

Plucene is a fully-featured and highly customizable search engine toolkit
based on the Lucene API. (L<http://jakarta.apache.org/lucene>)

It is not, in and of itself, a functional search engine - you are expected
to subclass and tie all the pieces together to suit your own needs.
The synopsis above gives a rough indication of how to use the engine
in simple cases. See L<Plucene::Simple> for one example of tying it
all together.

=head1 EXTENSIONS

Plucene comes shipped with some default Analyzsers. However it is
expected that users will want to create Analyzers to meet their own
needs. To avoid namespace corruption, anyone releasing such Analyzers
to CPAN (which is encouraged!) should place them in the namespace
Plucene::Plugin::Analyzer::.

=head1 DOCUMENTATION

Although most of the Perl modules should be well documented,
the Perl API mirrors Lucene's to such an extent that reading
Lucene's documentation will give you a good idea of how to do more
advanced stuff with Plucene. See particularly the ONJava articles
L<http://www.onjava.com/pub/a/onjava/2003/01/15/lucene.html> and
L<http://www.onjava.com/pub/a/onjava/2003/03/05/lucene.html>. These are
brilliant introductions to the concepts surrounding Lucene, how it works,
and how to extend it.

=head1 COMPATIBILITY

Plucene should be able to read index files created by Lucene,
but currently Lucene can not read indexes created or modified by
Plucene. (This is classed as a bug, and patches to fix it are welcome).

=head1 MISSING FEATURES

As this is an initial release, the following features have not yet been
implemented:

=over 3

=item *

Wildcard searches

=item *

Range searches

=back

=head1 MAILING LIST

Bug reports, patches, queries, discussion etc should be addressed to
the mailing list. More information on the list can be found at:

L<http://www.kasei.com/mailman/listinfo/plucene>

=head1 AUTHORS

Initial porting: Simon Cozens, C<simon@kasei.com> and Marc Kerr,
C<mwk@kasei.com>

Original Java Lucene by Doug Cutting and others.

=head1 THANKS

The development of Plucene was funded by Kasei L<http://www.kasei.com/>

=head1 LICENSE

This software is licensed under the same terms as Perl itself.

=cut

use strict;
use warnings;

our $VERSION = "1.20";

1;
