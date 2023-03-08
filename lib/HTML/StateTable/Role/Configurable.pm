use utf8; # -*- coding: utf-8; -*-
package HTML::StateTable::Role::Configurable;

use HTML::StateTable::Constants qw( DOT EXCEPTION_CLASS FALSE TRUE );
use HTML::StateTable::Types     qw( Bool Str );
use Unexpected::Functions       qw( throw );
use Try::Tiny;
use Moo::Role;

has 'configurable' => is => 'ro', isa => Bool, default => TRUE;

has 'configurable_control_location' => is => 'ro', isa => Str,
   default => 'TopRight';

has 'configurable_label' => is => 'ro', isa => Str, default => '⚙';

after 'BUILD' => sub {
   my $self = shift;

   return unless $self->configurable && $self->has_context;

   $self->add_role('configurable', __PACKAGE__);

   my $params = $self->param_value('config') || $self->_preference;

   if (scalar keys %{$params}) {
      $self->_apply_configurable_params($params);
      return;
   }
   else {
      for my $column ($self->_get_meta->all_columns) { $column->position(0) }
   }

   return;
};

sub serialise_configurable {
   my $self = shift;
   my $name = $self->name;
   (my $url = $self->context->table_preference_url) =~ s{ \* }{$name}mx;

   return {
      label    => $self->configurable_label,
      location => { control => $self->configurable_control_location },
      url      => $url,
   };
}

sub _apply_configurable_params {
   my ($self, $params) = @_;

   my $index = 0;
   my $position = {};

   for my $column_name (@{$params->{column_order} // []}) {
      $position->{$column_name} = $index++;
   }

   for my $column ($self->_get_meta->all_columns) {
      if (exists $position->{$column->name}) {
         $column->position($position->{$column->name});
      }
   }

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

   my $name = 'table' . DOT . $self->name . DOT . 'preference';
   my $pref = $self->context->preference($name);

   return $pref ? $pref->value : {};
}

use namespace::autoclean;

1;
