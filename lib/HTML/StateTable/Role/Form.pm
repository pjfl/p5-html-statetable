package HTML::StateTable::Role::Form;

use HTML::StateTable::Constants qw( FALSE NUL TRUE );
use HTML::StateTable::Types     qw( ArrayRef HashRef Str Undef URI );
use HTML::StateTable::Util      qw( json_bool );
use Ref::Util                   qw( is_arrayref is_hashref );
use Scalar::Util                qw( blessed );
use Moo::Role;

=pod

=encoding utf-8

=head1 Name

HTML::StateTable::Role::Form - Wraps the table in form

=head1 Synopsis

   use Moo;
   extends 'HTML::StateTable';
   with 'HTML::StateTable::Role::Form';

=head1 Description

Wraps the table in a form so that user input can be posted back to the server

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item form_action

An immutable action path string. Then endpoint to send the form to

=cut

has 'form_action' => is => 'ro', isa => Str, default => 'api/table_action';

=item form_buttons

A lazy immutable array or hash reference. Definitions for the form buttons

=cut

has 'form_buttons' =>
   is      => 'lazy',
   isa     => ArrayRef[HashRef|Str]|HashRef[ArrayRef[HashRef|Str]],
   default => sub { [] };

=item form_confirm_message

An immutable string. The default "are you sure message"

=cut

has 'form_confirm_message' => is => 'ro', isa => Str,
   default => 'Are you sure you want to *';

=item form_control_location

An immutable array reference or string. Defaults to C<Credit>. The location or
locations of form buttons

=cut

has 'form_control_location' =>
   is      => 'ro',
   isa     => ArrayRef[Str]|Str,
   default => 'Credit';

=back

=head1 Subroutines/Methods

Defines the following methods;

=over 3

=item BUILD

Runs after the table constructs. If we have context add C<form> to the
list of serialisable table roles

=cut

after 'BUILD' => sub {
   my $self = shift;

   $self->add_role('form', __PACKAGE__) if $self->has_context;

   return;
};

=item serialise_form

Returns a hash reference of keys and values serialised for and sent to the JS
running in the browser. JSON booleans are correctly marked

=cut

sub serialise_form {
   my $self = shift;
   my $name = $self->name;

   return {
      buttons  => $self->_serialise_buttons,
      confirm  => $self->form_confirm_message,
      location => { control => $self->form_control_location },
      url      => $self->context->uri_for_action($self->form_action, [$name]),
   };
}

# Private methods
sub _serialise_buttons {
   my $self = shift;
   my $list = $self->form_buttons;

   return $self->_serialise_button_list($list) if is_arrayref $list;

   my $buttons = {};

   for my $key (keys %{$list}) {
      $buttons->{$key} = $self->_serialise_button_list($list->{$key});
   }

   return $buttons;
}

sub _serialise_button_list {
   my ($self, $list) = @_;

   my $buttons = [];

   for my $button (@{$list}) {
      my $copy = $button;

      if (is_hashref $button) {
         $copy = { %{$button} };

         if (exists $copy->{selection} && $copy->{selection} =~ m{ \d }mx) {
            if ($copy->{selection}) { $copy->{selection} = 'selection' }
            else { delete $copy->{selection} }
         }
      }

      push @{$buttons}, $copy;
   }

   return $buttons;
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
