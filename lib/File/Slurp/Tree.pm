use strict;
package File::Slurp::Tree;
use File::Find::Rule;
use File::Path qw( mkpath );
use File::Slurp qw( read_file );
use Exporter::Simple;

our $VERSION = 1.21;

=head1 NAME

File::Slurp::Tree - slurp and emit file trees as nested hashes

=head1 SYNOPSIS

 # (inneficently) duplicate a file tree from path a to b
 use File::Slurp::Tree;
 my $tree = slurp_tree( "path_a" );
 spew_tree( "path_b" => $tree );

=head1 DESCRIPTION

File::Slurp::Tree provides functions for slurping and emitting trees
of files and directories.

It may be considered a testing tool, or simply something diagnostic:

 # an example of use in a testsuite
 use Test::More tests => 1;
 use File::Slurp::Tree;
 is_deeply( slurp_tree( "t/some_path" ), { foo => {} },
            "some_path just contains a directory called foo" );

 # as a diagnostic
 use File::Slurp::Tree;
 use YAML;
 print "Config directory contains:\n"
 print Dump slurp_tree "$ENV{HOME}/.app";

=head1 SUBROUTINES

=head2 slurp_tree( $path )

return a nested hash reference containing everything within $path

=cut

# slurp a file tree into a hash of hashes
sub slurp_tree :Exported {
    my $top = shift;

    my $tree = {};
    for my $file ( find( in => $top ) ) {
        next if $file eq $top;
        (my $rel = $file) =~ s{^\Q$top\E/}{};
        my @elems = split m{/}, $rel;

        # go to the top of the tree
        my $node = $tree;
        # and walk along the path
        while (my $elem = shift @elems) {
            # on the path || a dir
            if (@elems || -d $file) {
                $node = $node->{ $elem } ||= {};
            }
            else {
                # a file, slurp it
                $node->{ $elem } = read_file "$file";
            }
        }
    }
    return $tree;
}

=head2 spew_tree( $path => $tree )

=cut

# create a tree from a hash of hashes
sub spew_tree :Exported {
    my ($top, $tree) = @_;
    eval { mkpath( $top ) };
    for my $stem (keys %$tree) {
        if (ref $tree->{$stem}) { # directory
            spew_tree( "$top/$stem", $tree->{ $stem } );
        }
        else { # file
            open my $fh, ">$top/$stem";
            print $fh $tree->{ $stem } if defined $tree->{ $stem };
        }
    }
    return 1;
}

1;
__END__

=head1 BUGS

None currently known.  If you find any please either contact me
directly or make use of L<http://rt.cpan.org> by mailing your report
to bug-File-Slurp-Tree@rt.cpan.org

=head1 AUTHOR

Richard Clamp <richardc@unixbeard.net>

=head1 COPYRIGHT

Copyright (C) 2003 Richard Clamp.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

  L<File::Slurp>, L<Test::More>

=cut
