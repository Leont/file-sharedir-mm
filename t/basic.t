use strict;
use warnings;

use Test::More tests => 4;
use Test::TempDir::Tiny qw(tempdir);
use Path::Tiny qw(path);
use Capture::Tiny qw( capture );
use Env qw(@PERL5LIB);

# ABSTRACT: Test basic behaviour

my $install = tempdir('install');
my $pwd     = Path::Tiny->cwd;

# Make sure install target is prepped.
unshift @PERL5LIB, $install, $pwd->child('lib');
$ENV{PERL_MM_OPT} = "INSTALL_BASE=$install";

# Prep the source tree
my $source = tempdir('source');

path($source)->child('lib')->mkpath;
path($source)->child('lib/TestDist.pm')->spew("package TestDist;\n\$VERSION = '1.000';\n1;\n");

my $share = path($source)->child('share');
$share->child('dots/.dotdir')->mkpath;
$share->child('dots/.dotdir/normalfile')->spew("This is a normal file");
$share->child('dots/.dotdir/.dotfile')->spew("This is a dotfile");
$share->child('dots/.dotfile')->spew("This is a dotfile");
$share->child('normalfile')->spew("This is a normal file");

path($source)->child('Makefile.PL')->spew(<<'MAKEFILE');

use strict;
use warnings;
use 5.008;

use ExtUtils::MakeMaker;

my %Args = (
  ABSTRACT => "Test Module",
  AUTHOR   => "Kent Fredric",
  CONFIGURE_REQUIRES => {
    "ExtUtils::MakeMaker" => 0,
    "File::ShareDir::MM" =>  0,
  },
  DISTNAME => "TestDist",
  EXE_FILES => [],
  LICENSE => "perl",
  NAME => "TestDist",
  PREREQ_PM => {},
  postamble => {
    share => 1,
  },
);

delete $Args{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%Args);

package MY;

use File::ShareDir::MM 'postamble';

MAKEFILE

chdir $source;
END { chdir $pwd }

sub run_ok {
    my ( $out, $err, $exit ) = &capture( $_[1] );
    note explain { 'stdout' => $out, 'stderr' => $err, exit => $exit };
    return cmp_ok( $exit, '==', 0, "Run OK: $_[0]" );
}

# Testing happens here:
SKIP: {

    run_ok( "Configure" => sub { system $^X, 'Makefile.PL' } )
      or skip "as configure should pass first", 3;

    run_ok( "Make" => sub { system 'make' } )
      or skip "as make should pass first", 2;

    run_ok( "Make Install" => sub { system 'make', 'install' } )
      or skip "as make install should pass first", 1;

    ok(
        path($install)->child(
            'lib/perl5/auto/share/dist/TestDist/share/dots/.dotdir/.dotfile')
          ->exists,
        'dotfile in a dotdir installed'
    );
}
done_testing;
