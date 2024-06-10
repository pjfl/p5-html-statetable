package HTML::StateTable::Exception;

use Unexpected::Functions qw( has_exception );
use Moo;

extends q(Unexpected);
with    q(Unexpected::TraitFor::ErrorLeader);
with    q(Unexpected::TraitFor::ExceptionClasses);

=pod

=encoding utf-8

=head1 Name

HTML::StateTable::Exception - Exceptions used by this distribution

=head1 Synopsis

   use HTML::StateTable::Exception;

=head1 Description

Exception definitions

=head1 Configuration and Environment

Defines the following exceptions;

=over 3

=cut

my $class = __PACKAGE__;

has '+class' => default => $class;

=item HTML::StateTable::Exception

Parent for exceptions declared here

=cut

has_exception $class;

=item UnknownView

The named view is not known

=cut

has_exception 'UnknownView' => parents => [$class],
   error => 'View [_1] unknown';

use namespace::autoclean;

1;

__END__

=back

=head1 Subroutines/Methods

Defines no methods or functions

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Unexpected>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module. Please report problems to
http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-StateTable.
Patches are welcome

=head1 Acknowledgements

Larry Wall - For the Perl programming language

=head1 Author

Peter Flanigan, C<< <pjfl@cpan.org> >>

=head1 License and Copyright

Copyright (c) 2024 Peter Flanigan. All rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>

This program is distributed in the hope that it will be useful,
but WITHOUT WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE

=cut

# Local Variables:
# mode: perl
# tab-width: 3
# End:
# vim: expandtab shiftwidth=3:
