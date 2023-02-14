package HTML::StateTable::Serialise::JSON;

use namespace::autoclean;

use HTML::StateTable::Constants qw( FALSE TRUE );
use HTML::StateTable::Types     qw( Bool HashRef Object Str );
use HTML::StateTable::Util      qw( json_bool );
use JSON::MaybeXS;
use Moo;

extends qw( HTML::StateTable::Serialiser::Base );

has 'serialise_as_hashref' => is => 'ro', isa => Bool, default => TRUE;

has 'serialise_record_key' => is => 'ro', isa => Str, default => 'name';

has '_json' => is => 'ro', isa => Object, default => sub { JSON::MaybeXS->new };

has '_tags' =>
   is      => 'rwp',
   isa     => HashRef,
   default => sub { {} };

around 'serialise' => sub {
   my ($orig, $self) = @_;

   if ($self->serialise_as_hashref) {
      my $total = $self->table->no_count ? q() : $self->table->row_count;

      $self->writer('{"total-records":"' . $total . '","records":');
   }

   $self->writer('[');

   my $index = $orig->($self);

   $self->writer(']');

   $self->writer('}') if $self->serialise_as_hashref;

   return $index;
};

around 'serialise_row' => sub {
   my ($orig, $self, $row, $index) = @_;

   $self->_set_tags($self->_extract_tags($row));

   my $data = $orig->($self, $row, $index);

   $data->{_highlight} = json_bool $self->table->highlight_row($row)
      if $self->table->does('HTML::StateTable::Role::HighlightRow');

   $data->{_inactive} = json_bool $self->table->is_row_active($row)
      if $self->table->does('HTML::StateTable::Role::Active');

   $row = $self->_json->encode($data);

   $row = ",${row}" unless $index == 0;

   return $row;
};

sub skip_serialise_cell {
   my ($self, $cell) = @_;

   return $cell->column->append_to || $self->column->hidden($self->table);
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
   my %tags = ();

   for my $cell (grep { !$_->hidden && $_->unfiltered_value } $row->cells) {
      my $column = $cell->column;

      $tags{$column->append_to} = [ split m{ \| }mx, $cell->unfiltered_value ]
         if $column->append_to && $displayable->columns->{$column->name};
   }

   return \%tags;
}

sub _store_value_as_hash {
   my ($store, $key, $value) = @_;

   if (is_hashref $store) { $store->{$key} = $value }
   else { $store = { $key => $value, value => $store } }

   return $store;
}

1;
