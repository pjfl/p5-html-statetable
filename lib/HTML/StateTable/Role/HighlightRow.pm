package HTML::StateTable::Role::HighlightRow;

use Moo::Role;

=pod

=encoding utf-8

=head1 Name

HTML::StateTable::Role::HighlightRow - Mark rows for highlighting

=head1 Synopsis

   use Moo;
   extends 'HTML::StateTable';
   with 'HTML::StateTable::Role::HighlightRow';

   sub highlight_row {
      my ($self, $row) = @_;

      return 1 if $row->...;
      return 0;
   }

=head1 Description

When applied the C<highlight_row> method on the table object is called passing
in the row object. The boolean result is added to the data serialised to the
front end. The JS uses this boolean to add an additional class to the table row
which causes it to display with a highlight defined by the CSS

=head1 Configuration and Environment

Defines the no attributes

=head1 Subroutines/Methods

Defines the following methods;

=over 3

=item BUILD

Runs after the table constructs. Adds C<serialise_highlightrow> to
the C<serialise> call chain

=cut

after 'BUILD' => sub {
   my $self = shift;

   $self->add_role('highlightrow', __PACKAGE__);
};

=item serialise_highlightrow

Returns a hash reference of keys and values serialised for and sent to the JS
running in the browser. JSON booleans are correctly marked

=cut

sub serialise_highlightrow {
   return { 'role-name' => 'HighlightRow' };
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
