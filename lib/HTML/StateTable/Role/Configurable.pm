package HTML::StateTable::Role::Configurable;

use utf8; # -*- coding: utf-8; -*-

use HTML::StateTable::Constants qw( DOT FALSE TRUE );
use HTML::StateTable::Types     qw( Bool HashRef Str );
use Moo::Role;

=pod

=encoding utf-8

=head1 Name

HTML::StateTable::Role::Configurable - Persists table configuration options

=head1 Synopsis

   use Moo;
   extends 'HTML::StateTable';
   with 'HTML::StateTable::Role::Configurable';

=head1 Description

Persists table configuration options

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item configurable

An immutable boolean with a true default. If false the configuration options
will not be serialised and any persistent configuration will not be applied

=cut

has 'configurable' => is => 'ro', isa => Bool, default => TRUE;

=item configurable_action

An immutable required string with no default. This is an action path that is
passed to the C<uri_for_action> method on the C<context> object. The URI that
results is used by the front end JS to get, set, and clear persisted
configuration

=cut

has 'configurable_action' => is => 'ro', isa => Str, required => TRUE;

=item configurable_control_location

An immutable string that defaults to C<TopRight>. The location of the
configurable control displayed by the front end

=cut

has 'configurable_control_location' => is => 'ro', isa => Str,
   default => 'TopRight';

=item configurable_dialog_close

An immutable lazy string which defaults to C<X>. The default display character
used to close the preferences dialog

=cut

has 'configurable_dialog_close' => is => 'lazy', isa => Str, default => 'X';

=item configurable_dialog_title

An immutable string which defaults to C<Defaults>. Displayed in the title bar
of the preferences dialog

=cut

has 'configurable_dialog_title' => is => 'ro', isa => Str,
   default => 'Defaults';

=item configurable_label

An immutable lazy string which defaults to C<⚙>. Displayed as the open dialog
control for the preferences dialog

=cut

has 'configurable_label' => is => 'lazy', isa => Str, default => '⚙';

=item configurable_params

An immutable lazy hash reference which defaults to either the query parameter
C<config> (if present) or the options persisted in the database

=cut

has 'configurable_params' => is => 'lazy', isa => HashRef, default => sub {
   my $self = shift; return $self->param_value('config') || $self->_preference;
};

=back

=head1 Subroutines/Methods

Defines the following methods;

=over 3

=item BUILD

Executes after C<BUILD>. If the C<configurable> attribute is true and the table
has C<context> adds the C<serialise_configurable> method to the call chain
used to serialise the table description

=cut

after 'BUILD' => sub {
   my $self = shift;

   return unless $self->configurable && $self->has_context;

   $self->add_role('configurable', __PACKAGE__);
   return;
};

=item apply_params

Modifies the method in the L<HTML::StateTable> class. If the C<configurable>
attribute is true and the table has C<context> then the contents of the
C<configurable_params> attribute are applied to the current table object

=cut

around 'apply_params' => sub {
   my ($orig, $self) = @_;

   return $orig->($self) unless $self->configurable && $self->has_context;

   my $params = $self->configurable_params;

   return $orig->($self) unless scalar keys %{$params};

   $self->_apply_configurable_params($params);
   $orig->($self);
   return;
};

=item serialise_configurable

Returns a hash reference of configuration attributes consumed by the JS in
the front end

=cut

sub serialise_configurable {
   my $self   = shift;
   my $name   = $self->name;
   my $action = $self->configurable_action;

   return {
      'dialog-close' => $self->configurable_dialog_close,
      'dialog-title' => $self->configurable_dialog_title,
      'label'        => $self->configurable_label,
      'location'     => { control => $self->configurable_control_location },
      'url'          => $self->context->uri_for_action($action, [$name]),
   };
}

# Private methods
sub _apply_configurable_params {
   my ($self, $params) = @_;

   for my $column (@{$self->columns}) {
      my $col = $params->{columns}->{$column->name} or next;

      if (exists $col->{view}) {
         my $value = $col->{view} ? TRUE : FALSE;

         $self->displayable_columns->{$column->name} = $value;
      }

      if (exists $col->{download}) {
         my $value = $col->{download} ? TRUE : FALSE;

         $self->serialisable_columns->{$column->name} = $value;
      }
   }

   if ($self->sortable and my $sort = $params->{sort}) {
      unless ($self->param_value('sort')) {
         $self->sort_column($sort->{column});
         $self->sort_desc($sort->{desc} ? TRUE : FALSE);
      }
   }

   if (my $page_size = $params->{page_size}){
      $self->page_size($page_size) unless $self->param_value('page_size');
   }

   if (my $render_style = $params->{render_style}) {
      $self->render_style($render_style)
         unless $self->param_value('render_style');
   }

   return;
}

sub _preference {
   my $self = shift;

   return {} unless $self->has_context;

   my $rs      = $self->context->model('Preference');
   my $name    = 'table' . DOT . $self->name . DOT . 'preference';
   my $user_id = $self->context->session->id;
   my $pref    = $rs->find({ name => $name, user_id => $user_id });

   return $pref ? $pref->value : {};
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
