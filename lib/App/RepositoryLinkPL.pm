package App::RepositoryLinkPL;

use 5.012;
use strict;
use warnings;

our $VERSION = '0.01';


1; # End of App::RepositoryLinkPL

__END__

=head1 NAME

App::RepositoryLinkPL - companion module for repositorylink-pl program

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

repositorylink-pl is a program to add repository link to Makefile.PL/Build.PL,
so it will be published via META.*.
It can clone repository from github, add link, do fork and pull
request or just add link to distribution in current directory
independently from repository type/location.

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 AUTHOR

Alexandr Ciornii, C<< <alexchorny at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-RepositoryLinkPL>.
I will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::RepositoryLinkPL


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-RepositoryLinkPL>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-RepositoryLinkPL>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-RepositoryLinkPL>

=item * Search CPAN

L<http://search.cpan.org/dist/App-RepositoryLinkPL/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015-2016 Alexandr Ciornii.

This program is released under the following license: GPL3


=cut
