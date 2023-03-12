use utf8; # -*- coding: utf-8; -*-
package HTML::StateTable::Role::Filterable;

use HTML::StateTable::Constants qw( EXCEPTION_CLASS FALSE MAX_FILTER_ROWS
                                    SERIALISE_TABLE_KEY SERIALISE_TABLE_VIEW
                                    TRUE );
use HTML::StateTable::Types     qw( Str );
use HTML::StateTable::Util      qw( json_bool throw );
use Ref::Util                   qw( is_coderef );
use Unexpected::Functions       qw( UnknownView );
use Moo::Role;

has 'filterable_dialog_title' => is => 'ro', isa => Str,
   default => 'Filter';

has 'filterable_label' => is => 'ro', isa => Str,
   default => '⛢'; # ↣ ↓ ⛢ ∀

has 'filterable_message_label' => is => 'ro', isa => Str,
   default => 'Filtering on column';

has 'filterable_message_location' => is => 'ro', isa => Str,
   default => 'Title';

has 'filterable_remove_label' => is => 'ro', isa => Str,
   default => 'Show all';

has 'filterable_view_name' => is => 'ro', isa => Str,
   default => SERIALISE_TABLE_VIEW;

after 'BUILD' => sub {
   my $self = shift;

   return unless $self->has_context;

   $self->add_role('filterable', __PACKAGE__);

   my $view = $self->filterable_view_name;

   throw UnknownView, [$view] unless $self->context->view($view);

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

   return $rs->search({ -nest => \[$column->sql . ' = ?' => [sql => $value]]})
      if $column->is_generated;

   return $rs->search({ "${relation_name}.${filter_column}" => $value });
};

sub filter_column_values {
   my ($self, $column_name) = @_;

   return [] unless $column_name;

   my $column = $self->get_column($column_name);

   return [] unless $column && $column->filterable;

   my $rs = $self->resultset;

   delete $rs->{attrs}->{'+as'}; delete $rs->{attrs}->{'+select'};

   if ($column->has_filter_relation) {
      my ($related_rs, $relation)
         = $self->_get_related_rs($rs, $column->filter_relation);
      my $pkey    = $self->_get_result_source_pkey($related_rs);
      my @columns = map { "${relation}.${_}" } ($pkey, $column->filter_field);
      my $schema  = $related_rs->result_source->schema;
      my $order   = $schema->storage->sql_maker->_quote($columns[1]);

      shift @columns unless $column->filter_use_pkey;

      $rs = $related_rs->search(undef, {
         columns => [@columns], group_by => [@columns]
      });

      my $info = $rs->result_source->column_info($column->filter_field);

      $order = 'text' eq lc $info->{data_type} ? \qq{lower($order)} : \$order;
      $rs = $rs->search(undef, { order_by => $order });
   }
   else {
      if ($column->is_generated) {
         $rs = $self->_apply_column_sql($rs, $column)->search(undef, {
            columns => [], group_by => \$column->sql, order_by => \q{1},
         });
      }
      else {
         $rs = $rs->search(undef, {
            columns  => [$column->filter_column],
            distinct => TRUE,
            order_by => $column->filter_column,
         });
      }
   }

   $rs = $rs->search({}, { rows => MAX_FILTER_ROWS });

   return [$rs->get_column($column->filter_column)->all];
}

sub serialise_filterable {
   my $self = shift;

   return {
      'apply'         => { before => json_bool TRUE },
      'dialog-title'  => $self->filterable_dialog_title,
      'label'         => $self->filterable_label,
      'location'      => { messages => $self->filterable_message_location },
      'message-label' => $self->filterable_message_label,
      'remove-label'  => $self->filterable_remove_label,
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
