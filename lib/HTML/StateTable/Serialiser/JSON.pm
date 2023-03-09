package HTML::StateTable::Serialiser::JSON;

use HTML::StateTable::Constants qw( FALSE PIPE TRUE );
use HTML::StateTable::Types     qw( Bool HashRef Object Str );
use HTML::StateTable::Util      qw( json_bool );
use Ref::Util                   qw( is_hashref );
use JSON::MaybeXS;
use Moo;

extends qw'HTML::StateTable::Serialiser::Base';

has '+mime_type' => default => 'application/json';

has 'filter_column' => is => 'ro', isa => Str;

has 'serialise_as_hashref' => is => 'ro', isa => Bool, default => TRUE;

has 'serialise_meta' => is => 'ro', isa => Bool, default => FALSE;

has 'serialise_record_key' => is => 'ro', isa => Str, default => 'name';

has '_json' => is => 'ro', isa => Object, default => sub {
   return JSON::MaybeXS->new( convert_blessed => TRUE );
};

has '_tags' =>
   is      => 'rwp',
   isa     => HashRef,
   writer  => '_set_tags',
   default => sub { {} };

around 'serialise' => sub {
   my ($orig, $self) = @_;

   my $table = $self->table;

   return $self->_serialise_filter($table) if $self->filter_column;

   return $self->_serialise_meta($table) if $self->serialise_meta;

   if ($self->serialise_as_hashref) {
      my $total = $table->no_count ? q() : $table->row_count // q();

      $self->writer->('{"total-records":"' . $total . '","records":');
   }

   $self->writer->('[');

   my $index = $orig->($self);

   $self->writer->(']');

   $self->writer->('}') if $self->serialise_as_hashref;

   return $index;
};

around 'serialise_row' => sub {
   my ($orig, $self, $row, $index) = @_;

   $self->_set_tags($self->_extract_tags($row));

   my $data = $orig->($self, $row, $index);

   $data->{_highlight} = json_bool $self->table->highlight_row($row)
      if $self->table->does('HTML::StateTable::Role::HighlightRow');

   $data->{_inactive} = json_bool !$self->table->is_row_active($row)
      if $self->table->does('HTML::StateTable::Role::Active');

   $row = $self->_json->encode($data);

   $row = ",${row}" unless $index == 0;

   return $row;
};

sub skip_serialise_cell {
   my ($self, $cell) = @_;

   return $cell->column->append_to || $cell->column->hidden($self->table);
}

sub serialise_cell {
   my ($self, $cell, $data) = @_;

   my $column = $cell->column;
   my $key    = $self->serialise_record_key eq 'label'
      ? $column->label : $column->name;
   my $value  = $cell->serialise_value;

   $value = _store_value_as_hash($value, link => $cell->link->as_string)
      if $cell->has_link;

   $value = _store_value_as_hash($value, tags => $self->_tags->{$column->name})
      if exists $self->_tags->{$column->name};

   $data->{$key} = $value;
   return;
}

sub _extract_tags {
   my ($self, $row) = @_;

   my $displayable_columns = $self->table->displayable_columns;
   my $sep  = PIPE;
   my %tags = ();

   for my $cell (grep { !$_->hidden && $_->unfiltered_value } $row->cells) {
      my $column = $cell->column;
      my $value  = $cell->unfiltered_value;

      $tags{$column->append_to} = [ split m{ \Q$sep\E }mx, $value ]
         if $column->append_to && $displayable_columns->{$column->name};
   }

   return \%tags;
}

sub _serialise_filter {
   my ($self, $table) = @_;

   my $records = $table->filter_column_values($self->filter_column);

   $self->writer->($self->_json->encode({
      records => $records, 'total-records' => scalar @{$records},
   }));

   return TRUE;
}

sub _serialise_meta {
   my ($self, $table) = @_;

   $self->writer->($self->_json->encode({
      'column-order' => [ map { $_->name } @{$table->get_displayable_columns} ],
      displayed      => {
         map   { $_  => json_bool $table->displayable_columns->{$_}}
         keys %{$table->displayable_columns}
      },
      downloadable   => {
         map   { $_  => json_bool $table->serialisable_columns->{$_}}
         keys %{$table->serialisable_columns}
      },
      'page-size'    => $table->page_size,
      'sort-column'  => $table->sort_column_name,
      'sort-desc'    => json_bool $table->sort_desc,
   }));
   return TRUE;
}

sub _store_value_as_hash {
   my ($store, $key, $value) = @_;

   if (is_hashref $store) { $store->{$key} = $value }
   else { $store = { $key => $value, value => $store } }

   return $store;
}

use namespace::autoclean;

1;
