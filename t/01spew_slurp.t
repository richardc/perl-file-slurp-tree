#!perl -w
use strict;
use Test::More tests => 8;
use File::Slurp::Tree;
use File::Path qw( rmtree );

my $path = 't/sample';
my $tree = {
    subdir => {},
    file   => 'this is a test file',
};

eval { rmtree( $path ) };
ok( !-e $path, "no $path at start" );
ok( spew_tree( $path => $tree ), "spewed a tree" );

ok( -e $path, "now a $path" );
ok( -e "$path/file", "there's a file");
is( -s "$path/file", length $tree->{file}, " of the right size" );

ok( -e "$path/subdir", "and a subdirectory" );
is_deeply( [ <$path/subdir/*> ], [], " which is empty" );

is_deeply( slurp_tree( $path ), $tree, "and slurping works" );
