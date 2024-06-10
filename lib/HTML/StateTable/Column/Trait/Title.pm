package HTML::StateTable::Column::Trait::Title;

use HTML::StateTable::Constants qw( NUL );
use HTML::StateTable::Types     qw( CodeRef Str );
use Ref::Util                   qw( is_coderef );
use Moo::Role;

=pod

=encoding utf-8

=head1 Name

HTML::StateTable::Column::Trait::Title - Title column trait

=head1 Synopsis

   with 'HTML::StateTable::Column::Trait::Title';

=head1 Description

Title column trait

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item has_title

Predicate for the private C<_title> attribute which has an initial arg of
C<title>. Can be a string or a code reference

=cut

has '_title' => is => 'ro', isa => CodeRef|Str, init_arg => 'title',
   predicate => 'has_title';

=back

=head1 Subroutines/Methods

=over 3

=item title( $renderer )

If the column C<has_title> returns its value. Passes the column object into
the call to C<_title> if it is a code reference

=cut

sub title {
   my ($self, $renderer) = @_;

   return $self->has_title ? $self->_title_content : undef;
}

sub _title_content {
   my $self = shift;

   return is_coderef $self->_title ? $self->_title->($self)
      : defined $self->_title ? $self->_title
      : NUL;
}

use namespace::autoclean;

1;

__END__

=back

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Moo::Role>

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

Peter Flanigan, C<< <lazarus@roxsoft.co.uk> >>

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
