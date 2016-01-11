use 5.012;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'App::RepositoryLinkPL',
    AUTHOR           => q{Alexandr Ciornii <alexchorny AT gmail.com>},
    VERSION_FROM     => 'lib/App/RepositoryLinkPL.pm',
    ABSTRACT_FROM    => 'lib/App/RepositoryLinkPL.pm',
    LICENSE          => 'GPL3',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.012,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'File::Slurp' => 0,
        'Text::FindIndent' => 0.08,
        'App::EUMM::Upgrade' => 0.25,
        'Github::Fork::Parent' => 0.24,
        'Module::Metadata' => 0,

        #github support
        'Git::Class' => 0.06,
        'Net::GitHub' => 0.74,
        'Config::Tiny' => 0,
    },
    'EXE_FILES' => [
      'repositorylink-pl',
    ],

    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'App-RepositoryLinkPL-*' },
);
