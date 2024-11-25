package HTML::StateTable::Role::Reorderable;

use utf8; # -*- coding: utf-8; -*-

use HTML::StateTable::Constants qw( FALSE NUL TRUE );
use HTML::StateTable::Types     qw( Bool Str );
use Moo::Role;

=pod

=encoding utf-8

=head1 Name

HTML::StateTable::Role::Form - Allows columns to be reordered

=head1 Synopsis

   use Moo;
   extends 'HTML::StateTable';
   with 'HTML::StateTable::Role::Form';

=head1 Description

Allows columns to be reordered from the configurable features control form

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item reorderable

Am immutable boolean which default false. Set to true to enable this feature

=cut

has 'reorderable' => is => 'ro', isa => Bool, default => TRUE;

=item reorderable_label_title

An immutable string. The mouseover text to display when dragging and dropping
to reorder columns

=cut

has 'reorderable_label_title' => is => 'ro', isa => Str,
   default => 'Drag and drop to reorder columns';

=back

=head1 Subroutines/Methods

Defines the following methods;

=over 3

=item BUILD

Runs after the table constructs. If C<reorderable> is true and we does the
C<configurable> role add C<reorderable> to the list of serialisable table roles

=cut

after 'BUILD' => sub {
   my $self = shift;

   return unless $self->reorderable
      && $self->does('HTML::StateTable::Role::Configurable');

   $self->add_role('reorderable', __PACKAGE__);
   return;
};

=item sorted_columns

Wraps around the C<sorted_columns> method in the table class. Uses the
C<configurable_params> attribute from the C<configurable> role. This hash
reference contains the C<column_order> attribute which is used to order
the columns

=cut

around 'sorted_columns' => sub {
   my ($orig, $self, @columns) = @_;

   my $index    = 0;
   my $position = {};
   my $params   = $self->configurable_params;

   for my $column_name (@{$params->{column_order} // []}) {
      $position->{$column_name} = $index++;
   }

   return @columns unless scalar keys %{$position};

   return map { $_->[1] } sort { $a->[0] <=> $b->[0] }
          map { [ $position->{$_->name} // $index++, $_ ] } @columns;
};

=item serialise_reorderable

Returns a hash reference of keys and values serialised for and sent to the JS
running in the browser. JSON booleans are correctly marked

=cut

sub serialise_reorderable {
   my $self = shift;

   return {
      title => $self->reorderable_label_title,
   };
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
