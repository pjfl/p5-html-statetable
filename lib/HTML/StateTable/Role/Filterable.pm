package HTML::StateTable::Role::Filterable;

use HTML::StateTable::Constants qw( EXCEPTION_CLASS FALSE SERIALISE_TABLE_KEY
                                    SERIALISE_TABLE_VIEW TRUE );
use HTML::StateTable::Types     qw( Str );
use HTML::StateTable::Util      qw( json_bool );
use Ref::Util                   qw( is_coderef );
use Unexpected::Functions       qw( throw );
use Moo::Role;

has 'filterable_message_location' => is => 'ro', isa => Str,
   default => 'Title';

after 'BUILD' => sub {
   my $self = shift;

   return unless $self->has_context;

   $self->add_role('filterable', __PACKAGE__);

   my $view = SERIALISE_TABLE_VIEW;

   throw 'Undefined view [_1]', [$view] unless $self->context->view($view);

   if (my $column_name = $self->param_value('filter_column_values')) {
      $self->context->stash(
         view                  => $view,
         SERIALISE_TABLE_KEY() => {
            table              => $self,
            format             => 'json',
            no_filename        => TRUE,
            serialiser_args    => {
               disable_paging  => TRUE,
               filter_column   => $column_name
            },
         },
      );
   }

   return;
};

around 'build_prepared_resultset' => sub {
   my ($orig, $self) = @_;

   my $rs = $orig->($self);
   my $name = $self->param_value('filter_column');
   my $value = $self->param_value('filter_value');

   return $rs unless $name && $value;

   $self->is_filtered(TRUE);

   my $column = $self->get_column($name);

   if ($column->has_filter_value_map) {
      my $map = $column->filter_value_map;
      my %pam = reverse %{ is_coderef $map ? $map->($self) : $map };

      $value = $pam{$value} if exists $pam{$value};
   }

   my $relation_name = $rs->current_source_alias;
   my $filter_column = $column->filter_column if $column->has_filter_column;

   if ($column->has_filter_relation) {
      my ($related_rs, $name)
         = $self->_get_related_rs($rs, $column->filter_relation);

      $relation_name = $name;
      $filter_column = $self->_get_result_source_pkey($related_rs)
         if $column->filter_use_pkey;
   }

   return $rs->search({ "${relation_name}.${filter_column}" => $value })
      unless $column->is_generated;

   return $rs->search({ -nest => \[$column->sql . ' = ?' => [sql => $value]]});
};

sub filterable_column_values {
   my ($self, $column_name) = @_;

   my $rs = $self->resultset->search();

   return [$rs->get_column($column_name)->all];
}

sub serialise_filterable {
   my $self = shift;

   return {
      apply => { before => json_bool TRUE },
      location => { messages => $self->filterable_message_location }
   };
}

sub _get_related_rs {
   my ($self, $related_rs, $relation) = @_;

   my @relations  = split m{ \. }mx, $relation;

   for (@relations) { $related_rs = $related_rs->related_resultset($_) }

   return $related_rs, $relations[-1];
}

sub _get_result_source_pkey {
   my ($self, $rs) = @_;

   my @pkey = $rs->result_source->primary_columns;

   throw 'Related table filtering requires a single primary key'
      unless scalar @pkey == 1;

   return $pkey[0];
}

use namespace::autoclean;

1;
