    use ExtUtils::MakeMaker;
    WriteMakefile
      ('DISTNAME' => 'Plucene',
       'VERSION' => '1.20',
       'PL_FILES' => {},
       'PREREQ_PM' => {
			'Memoize' => '1.01',
			'Tie::Array::Sorted' => '1.1',
			'File::Spec::Functions' => '1.1',
			'Encode::compat' => '0.05',
			'File::Slurp' => '2002.1031',
			'Class::Virtual' => '0.03',
			'Class::Accessor' => '0.18',
			'Carp' => '0',
			'Time::Piece' => '1.08',
			'Test::Harness' => '2.30',
			'IO::File' => '1.08',
			'List::Util' => '1.13',
			'IO::Handle' => '1.21_00',
			'Lingua::Stem::En' => '2.12',
			'Bit::Vector::Minimal' => '1.0',
			'Class::Accessor::Fast' => '0.02',
			'IO::Scalar' => '2.104',

		      },
      );
