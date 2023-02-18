package HTML::StateTable::Renderer::Table;

use Scalar::Util qw( blessed );
use Moo;

extends 'HTML::StateTable::Renderer';

has '+rows' => default => sub {
   my $self  = shift;
   my $table = $self->table;
   my @rows  = ($self->_header_row);

   while (my $row = $table->next_row) { push @rows, $self->_row($row) }

   $table->reset_resultset;

   return scalar @rows ? [ $self->_html->tr(@rows) ] : [];
};

sub _header_row {
   my $self = shift;
   my $cols = $self->table->visible_columns;

   return [ $self->_html->th(map { $_->label } @{$cols}) ];
}

sub _row {
   my ($self, $row) = @_;

   my @cols = (map { $self->_cell($_) } @{$row->cell_list});

   return [ $self->_html->td(@cols) ];
}

sub _cell {
   my ($self, $cell) = @_;

   my $value = $cell->render_value;

   $value = $self->_html->a({ href => $cell->link->as_string }, $value)
      if $cell->has_link;

   return $value;
}

use namespace::autoclean;

1;

__END__

=pod

=encoding utf-8

=head1 Name

HTML::StateTable::Renderer::Table - One-line description of the modules purpose

=head1 Synopsis

   use HTML::StateTable::Renderer::Table;
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
