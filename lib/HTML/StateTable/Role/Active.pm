package HTML::StateTable::Role::Active;

use HTML::StateTable::Constants qw( FALSE TRUE );
use HTML::StateTable::Types     qw( Bool Str );
use HTML::StateTable::Util      qw( json_bool );
use Moo::Role;

=pod

=encoding utf-8

=head1 Name

HTML::StateTable::Role::Active - Allows for the viewing of inactive records

=head1 Synopsis

   use Moo;
   extends 'HTML::StateTable';
   with 'HTML::StateTable::Role::Active';

=head1 Description

Displays a checkbox which removes the requirement for the result to have a
column called active which is true

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item active_control_location

An immutable string which defaults to 'TopLeft'. Choose where to display
the show inactive checkbox

=cut

has 'active_control_location' => is => 'ro', isa => Str, default => 'TopLeft';

=item active_enabled

An immutable boolean which defaults true. If false the show inactive control
will not be displayed

=cut

has 'active_enabled' => is => 'ro', isa => Bool, default => TRUE;

=item active_label

An immutable string which defaults to 'View Inactive' the text displayed
with a checkbox on the control

=cut

has 'active_label' => is => 'ro', isa => Str, default => 'View Inactive';

=back

=head1 Subroutines/Methods

Defines the following methods;

=over 3

=item BUILD

Runs after the table constructs. If C<active_enabled> add C<active> to the
list of serialisable table roles

=cut

after 'BUILD' => sub {
   my $self = shift;

   return unless $self->active_enabled;

   $self->add_role('active', __PACKAGE__);
   return;
};

=item build_prepared_resultset

Wraps around the core table method an conditionally adds the resultset method
call to C<active>

=cut

around 'build_prepared_resultset' => sub {
   my ($orig, $self) = @_;

   my $rs = $orig->($self);

   return $rs->active
      if !$self->param_value('show_inactive') && $rs->can('active');

   return $rs;
};

=item is_row_active( $row )

If the C<row> result has an C<active> method call it and return the result,
otherwise return true

=cut

sub is_row_active {
   my ($self, $row) = @_;

   return $row->result->can('active') ? $row->result->active : TRUE;
}

=item serialise_active

Returns a hash reference of keys and values serialised for and sent to the JS
running in the browser. JSON booleans are correctly marked

=cut

sub serialise_active {
   my $self = shift;

   return {
      enabled  => json_bool $self->active_enabled,
      label    => $self->active_label,
      location => { control => $self->active_control_location },
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
