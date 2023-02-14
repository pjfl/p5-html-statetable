package HTML::StateTable::Renderer::EmptyDiv;

use namespace::autoclean;

use HTML::StateTable::Constants qw( FALSE QUERY_KEY SERIALISE_COLUMN_ATTR
                                    TRIGGER_CLASS TRUE );
use HTML::StateTable::Types     qw( HashRef NonEmptySimpleStr );
use HTML::StateTable::Util      qw( json_bool );
use JSON                        qw( encode_json );
use Ref::Util                   qw( is_coderef is_hashref );
use HTML::StateTable::Result::Dummy;
use Moo;
use MooX::HandlesVia;

extends qw( HTML::StateTable::Renderer );

# Public attributes
has '+container_tag' => default => 'div';

has '+data' => default => sub {
   my $self = shift;
   my $data = {
      'data-c'          => TRIGGER_CLASS,
      'data-columns'    => encode_json($self->_serialise_columns),
      'data-name'       => $self->table->name,
      'data-properties' => encode_json($self->_serialise_properties),
   };

   $self->_serialise_roles($data);

   return $data;
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
   my $is_bool   = defined $type && $type->name =~ m{ Bool }mx ? TRUE : FALSE;

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

         my $value = $attribute eq 'searchable'
            ? $column->$attribute($self) : $column->$attribute;

         next unless defined $value;

         $attributes{$attribute}
            = $self->_boolify($column, $attribute, $value);
      }

      $attributes{traits} = [
         map { @{ _trait_names $dummy_row, $column, $_ } }
               @{ delete $attributes{cell_traits} }
      ];

      $attributes{has_tags} = json_bool TRUE
         if exists $self->_tags->{$column->name};

      push @columns, \%attributes;
   }

   return \@columns;
}

sub _serialise_properties {
   my $self  = shift;
   my $table = $self->table;
   my $uri   = $table->request->uri;

   $uri->query_param($self->query_key => $table->name);

   my $data = {
      'data-url'        => $uri->as_string,
      'enable-paging'   => json_bool $table->paging,
      'no-data-message' => $table->empty_text,
      'max-page-size'   => $table->max_page_size,
   };

   if ($table->no_count) { $data->{'no-count'} = json_bool TRUE }
   else { $data->{'total-records'} = $table->row_count }

   return $data;
}

sub _serialise_roles {
   my ($self, $data) = @_;

   my $table = $self->table;

   for my $role_name ($table->all_roles) {
      next unless $table->does($table->get_role($role_name));

      my $method = "serialise_${role_name}";

      if (defined(my $value = $table->$method)) {
         $data->{"data-role-${role_name}"} = encode_json($value);
      }
   }

   return;
}

1;
