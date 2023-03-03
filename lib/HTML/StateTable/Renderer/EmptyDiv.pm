package HTML::StateTable::Renderer::EmptyDiv;

use HTML::StateTable::Constants qw( FALSE QUERY_KEY SERIALISE_COLUMN_ATTR
                                    TRIGGER_CLASS TRUE );
use HTML::StateTable::Types     qw( HashRef NonEmptySimpleStr );
use HTML::StateTable::Util      qw( json_bool );
use Ref::Util                   qw( is_coderef is_hashref );
use Type::Utils                 qw( class_type );
use JSON::MaybeXS;
use HTML::StateTable::Result::Dummy;
use Moo;

extends 'HTML::StateTable::Renderer';

# Public attributes
has '+container_tag' => default => 'div';

has '+data' => default => sub {
   my $self = shift;

   return {
      'class' => TRIGGER_CLASS,
      'data-table-config' => $self->_json->encode({
         columns    => $self->_serialise_columns,
         name       => $self->table->name,
         properties => $self->_serialise_properties,
         roles      => $self->_serialise_roles,
      }),
   };
};

has '_json' => is => 'ro', isa => class_type(JSON::MaybeXS::JSON),
   default => sub {
      return JSON::MaybeXS->new( convert_blessed => TRUE, utf8 => FALSE );
   };

has 'query_key' => is => 'lazy', isa => NonEmptySimpleStr, default => QUERY_KEY;

# Private attributes
has '_tags' =>
   is      => 'lazy',
   isa     => HashRef,
   default => sub {
      my $self = shift;
      my %tags = ();

      for my $column ($self->table->all_visible_columns) {
         $tags{$column->append_to} = TRUE if $column->append_to;
      }

      return \%tags;
   };

# Private functions
sub _trait_names ($$$) {
   my ($dummy_row, $column, $trait) = @_;

   my $cell = $column->create_cell($dummy_row);

   return $cell->trait_names if $cell->can('trait_names');

   $trait =~ s{ \A .* :: }{}mx;

   return [$trait];
}

# Private methods
sub _boolify {
   my ($self, $column, $attribute, $value) = @_;

   my $attr_meta = $column->_get_meta->find_attribute_by_name($attribute);
   my $type      = $attr_meta->isa if defined $attr_meta;
   my $is_bool   = defined $type && $type =~ m{ Bool }mx ? TRUE : FALSE;

   if ($is_bool) { $value = json_bool $value }
   elsif (is_hashref $value) {
      $value = {
         map  { $_ => _boolify_if_option($column, $attribute, $_, $value->{$_})}
         grep { !is_coderef $value->{$_} } keys %{$value}
      };
   }

   return $value;
}

sub _boolify_if_option {
   my ($column, $attribute, $key, $value) = @_;

   if ($attribute eq 'options' && $column->is_boolean_option($key)) {
      $value = json_bool $value;
   }

   return $value;
}

sub _dummy_row {
   my $self   = shift;
   my $table  = $self->table;
   my $result = HTML::StateTable::Result::Dummy->new;

   return $table->row_class->new(table => $table, result => $result);
}

sub _serialise_columns {
   my $self      = shift;
   my $table     = $self->table;
   my $dummy_row = $self->_dummy_row;
   my @columns;

   for my $column ($table->all_visible_columns) {
      next if $column->append_to;

      my $displayed  = $table->is_displayable_column($column->name);
      my %attributes = ( displayed => json_bool $displayed );

      for my $attribute (SERIALISE_COLUMN_ATTR()) {
         next unless $column->can($attribute);

         my $value = _is_column_trait($attribute)
            ? $column->$attribute($self) : $column->$attribute;

         next unless defined $value;

         $attributes{$attribute}
            = $self->_boolify($column, $attribute, $value);
      }

      $attributes{cell_traits} = [
         map { @{ _trait_names $dummy_row, $column, $_ } }
               @{ delete $attributes{cell_traits} }
      ];

      $attributes{downloadable} = json_bool
         ($table->serialisable_columns->{$column->name} ? TRUE : FALSE);

      $attributes{has_tags} = json_bool TRUE
         if exists $self->_tags->{$column->name};

      push @columns, \%attributes;
   }

   return \@columns;
}

sub _is_column_trait {
   my $attr = shift;

   return TRUE if $attr eq 'searchable';
   return TRUE if $attr eq 'title';
   return FALSE;
}

sub _serialise_properties {
   my $self  = shift;
   my $table = $self->table;
   my $uri   = $table->request->uri;

   $uri->query_param($self->query_key => $table->name);

   my $data = {
      'data-url'        => $uri->as_string,
      'enable-paging'   => json_bool $table->paging,
      'no-count'        => json_bool $table->no_count,
      'no-data-message' => $table->empty_text,
      'page-size'       => $table->page_size,
      'max-page-size'   => $table->max_page_size,
      'sort-column'     => $table->sort_column_name,
      'sort-desc'       => json_bool $table->sort_desc,
      'verify-token'    => $table->context->verification_token,
   };

   if ($table->no_count) { $data->{'no-count'} = json_bool TRUE }
   else { $data->{'total-records'} = $table->row_count }

   return $data;
}

sub _serialise_roles {
   my $self  = shift;
   my $table = $self->table;
   my $roles = {};

   for my $role_name ($table->all_roles) {
      next unless $table->does($table->get_role($role_name));

      my $method = "serialise_${role_name}";

      if (defined(my $value = $table->$method)) {
         $roles->{$role_name} = $value;
      }
   }

   return $roles;
}

use namespace::autoclean;

1;
