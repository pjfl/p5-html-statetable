package HTML::StateTable::Column::Trait::Title;

use HTML::StateTable::Constants qw( NUL );
use HTML::StateTable::Types     qw( CodeRef Str );
use Ref::Util                   qw( is_coderef );
use Moo::Role;

has '_title' => is => 'ro', isa => CodeRef|Str, init_arg => 'title',
   predicate => 'has_title';

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

=pod

=encoding utf-8

=head1 Name

HTML::StateTable::Column::Trait::Title - One-line description of the modules purpose

=head1 Synopsis

   use HTML::StateTable::Column::Trait::Title;
   # Brief but working code examples

=head1 Description

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=back

=head1 Subroutines/Methods

=head1 Diagnostics

=head1 Dependencies

=over 3

=item L<Class::Usul>

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

Copyright (c) 2023 Peter Flanigan. All rights reserved

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
