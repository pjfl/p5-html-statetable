use utf8; # -*- coding: utf-8; -*-
package HTML::StateTable::Role::Configurable;

use HTML::StateTable::Constants qw( EXCEPTION_CLASS FALSE TRUE );
use HTML::StateTable::Types     qw( Bool Str );
use JSON::MaybeXS               qw( decode_json );
use Unexpected::Functions       qw( throw );
use Try::Tiny;
use Moo::Role;

has 'configurable' => is => 'ro', isa => Bool, default => TRUE;

has 'configurable_control_location' => is => 'ro', isa => Str,
   default => 'TopRight';

after 'BUILD' => sub {
   my $self = shift;

   return unless $self->configurable && $self->has_context;

   $self->add_role('configurable', __PACKAGE__);

   if (my $params = $self->param_value('config') || $self->_preference) {
      $self->_apply_configurable_params($params);
   }

   return;
};

sub serialise_configurable {
   my $self = shift;

   return $self->configurable ? {
      label     => '⚙',
      location  => { control => $self->configurable_control_location },
      url       => $self->context->preference_url,
   } : undef;
}

sub _apply_configurable_params {
   my ($self, $json) = @_;

   my $config; try { $config = decode_json($json) } catch { warn "$_" };

   return unless scalar keys %{$config};

   for my $column (@{$self->columns}) {
      if (my $col = $config->{columns}->{$column->name}) {
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

   if ($self->sortable and my $sort = $config->{sort}) {
      unless ($self->param_value('sort')) {
         $self->sort_column($sort->{column});
         $self->sort_desc($sort->{desc} ? TRUE : FALSE);
      }
   }

   if (my $page_size = $config->{page_size}){
      $self->page_size($page_size) unless $self->param_value('page_size');
   }

   return;
}

sub _preference {
   my $self = shift;

   return unless $self->has_context;

   my $name = 'table.' . $self->name . '.preference';
   my $pref = $self->context->preference($name);

   return $pref ? $pref->value : undef;
}

use namespace::autoclean;

1;
