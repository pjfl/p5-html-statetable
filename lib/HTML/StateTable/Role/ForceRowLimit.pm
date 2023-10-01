package HTML::StateTable::Role::ForceRowLimit;

use Moo::Role;

=pod

=encoding utf-8

=head1 Name

HTML::StateTable::Role::ForceRowLimit - Limits the number of rows selected

=head1 Synopsis

   use Moo;
   extends 'HTML::StateTable';
   with 'HTML::StateTable::Role::ForceRowLimit';

=head1 Description

Limits the number of rows selected

=head1 Configuration and Environment

Defines no attributes

=head1 Subroutines/Methods

Defines the following methods;

=over 3

=item force_row_limit

If displaying page one and there are fewer rows in the table than entries on
the page, limits the rows in the resultset

=cut

sub force_row_limit {
   my $self  = shift;

   return unless $self->page == 1;

   my $pager = $self->pager;
   my $rows  = $pager->entries_on_this_page;

   return unless $rows < $pager->entries_per_page;

   my $rs = $self->prepared_resultset;

   $self->{prepared_resultset} = $rs->search(undef, { rows => $rows });
   return;
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
