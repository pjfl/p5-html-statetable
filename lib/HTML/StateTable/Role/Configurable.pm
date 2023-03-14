use utf8; # -*- coding: utf-8; -*-
package HTML::StateTable::Role::Configurable;

use HTML::StateTable::Constants qw( DOT FALSE TRUE );
use HTML::StateTable::Types     qw( Bool HashRef Str );
use Try::Tiny;
use Moo::Role;

has 'configurable' => is => 'ro', isa => Bool,
   default => TRUE;

has 'configurable_action' => is => 'ro', isa => Str,
   default => 'api/table_preference';

has 'configurable_control_location' => is => 'ro', isa => Str,
   default => 'TopRight';

has 'configurable_dialog_title' => is => 'ro', isa => Str,
   default => 'Defaults';

has 'configurable_label' => is => 'ro', isa => Str,
   default => '⚙';

has 'configurable_params' => is => 'lazy', isa => HashRef, default => sub {
   my $self = shift; return $self->param_value('config') || $self->_preference;
};

around '_apply_params' => sub {
   my ($orig, $self) = @_;

   return $orig->($self) unless $self->configurable && $self->has_context;

   my $params = $self->configurable_params;

   return $orig->($self) unless scalar keys %{$params};

   $self->_apply_configurable_params($params);
   $orig->($self);
   return;
};

after 'BUILD' => sub {
   my $self = shift;

   return unless $self->configurable && $self->has_context;

   $self->add_role('configurable', __PACKAGE__);
   return;
};

sub serialise_configurable {
   my $self   = shift;
   my $name   = $self->name;
   my $action = $self->configurable_action;

   return {
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
      if (my $col = $params->{columns}->{$column->name}) {
         if (exists $col->{view}) {
            my $value = $col->{view} ? TRUE : FALSE;

            $self->displayable_columns->{$column->name} = $value;
         }

         if (exists $col->{download}) {
            my $value = $col->{download} ? TRUE : FALSE;

            $self->serialisable_columns->{$column->name} = $value;
         }
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

   return;
}

sub _preference {
   my $self = shift;

   return unless $self->has_context;

   my $rs   = $self->context->model('Preference');
   my $name = 'table' . DOT . $self->name . DOT . 'preference';
   my $pref = $rs->find({ name => $name }, { key => 'preference_name' });

   return $pref ? $pref->value : {};
}

use namespace::autoclean;

1;
