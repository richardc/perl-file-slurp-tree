package File::Slurp::Tree;
use strict;
use warnings;
use File::Find::Rule;
use File::Path qw( mkpath );
use File::Slurp qw( read_file );
use Exporter::Simple;

our $VERSION = 1.21;

=head1 NAME

File::Slurp::Tree - slurp and emit file trees as nested hashes

=head1 SYNOPSIS

 # (inefficiently) duplicate a file tree from path a to b
 use File::Slurp::Tree;
 my $tree = slurp_tree( "path_a" );
 spew_tree( "path_b" => $tree );

=head1 DESCRIPTION

File::Slurp::Tree provides functions for slurping and emitting trees
of files and directories.

 # an example of use in a test suite
 use Test::More tests => 1;
 use File::Slurp::Tree;
 is_deeply( slurp_tree( "t/some_path" ), { foo => {}, bar => "sample\n" },
            "some_path contains a directory called foo, and a file bar" );

The tree datastructure is a hash of hashes.  The keys of each hash are
names of directories or files.  Directories have hash references as
their value, files have a scalar which holds the contents of the file.

=head1 EXPORTED ROUTINES

=head2 slurp_tree( $path, %options )

return a nested hash reference containing everything within $path

%options may include the following keys:

=over

=item rule

a L<File::Find::Rule> object that will match the files and directories
in the path.  defaults to an empty rule (matches everything)

=back

=cut

sub slurp_tree :Exported {
    my $top = shift;
    my %args = @_;

    my $rule = $args{rule} || File::Find::Rule->new;

    my $tree = {};
    for my $file ( $rule->in( $top ) ) {
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

Creates a file tree as described by C<$tree> at C<$path>

=cut

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

None currently known.  If you find any please make use of
L<http://rt.cpan.org> by mailing your report to
bug-File-Slurp-Tree@rt.cpan.org, or contact me directly.

=head1 AUTHOR

Richard Clamp <richardc@unixbeard.net>

=head1 COPYRIGHT

Copyright (C) 2003 Richard Clamp.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<File::Slurp>, L<Test::More>

=cut
