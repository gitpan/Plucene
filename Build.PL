#!/usr/bin/perl -w

use strict;
use warnings;

use Module::Build;

shift(@ARGV)
	if $ARGV[0] && $ARGV[0] eq 'Build';    # accomodate with CPAN autoinstall
use Module::Build;

Module::Build->new(
	create_makefile_pl => 'traditional',
	module_name        => 'Plucene',
	dist_version_from  => 'lib/Plucene.pm',
	requires           => {
		'Bit::Vector::Minimal'  => '1.0',
		'Carp'                  => '1.01',
		'Class::Accessor'       => '0.18',
		'Class::Accessor::Fast' => '0.02',
		'Class::HasA'           => '1.00',
		'Class::Virtual'        => '0.03',
		$] < 5.006 ? ('Encode' => '') : (),
		'File::Spec::Functions' => '1.2',
		'IO::File'              => '1.09',
		'IO::Handle'            => '1.21_00',
		'IO::Scalar'            => '2.104',
		'Lingua::Stem::En'      => '2.12',
		'List::Util'            => '1.13',
		'Memoize'               => '1.01',
		'Tie::Array::Sorted'    => '1.1',
		'Time::Piece'           => '1.08',
	},
	build_requires => {
		'File::Slurp'   => '2002.1031',
		'Test::Class'   => '0.03',
		'Test::Harness' => '2.30',
	},
)->create_build_script;
