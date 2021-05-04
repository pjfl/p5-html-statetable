package HTML::StateTable::Manager;

use namespace::autoclean;

use HTML::StateTable::Constants qw( QUERY_KEY SERIALISE_TABLE_KEY
                                    SERIALISE_TABLE_VIEW TRUE );
use HTML::StateTable::Types     qw( Str );
use HTML::StateTable::Util      qw( throw );
use File::DataClass::Functions  qw( ensure_class_loaded );
use Moo;

has 'meta_key' => is => 'ro', isa => Str, default => 'table_meta';

has 'namespace' => is => 'ro', isa => Str, required => TRUE;

has 'query_key' => is => 'ro', isa => Str, predicate => 'has_query_key';

has 'stash_key' =>
   is      => 'ro',
   isa     => Str,
   default => SERIALISE_TABLE_KEY;

has 'view_name' =>
   is      => 'ro',
   isa     => Str,
   default => SERIALISE_TABLE_VIEW;

sub table {
   my ($self, $name, $options) = @_;

   my $class = $self->_renderer_class($options->{context});

   $options->{renderer_class} = $class if $class;
   $options->{renderer_args}->{query_key} = $self->query_key
      if $self->has_query_key;

   my $table = $self->_get_class($name)->new($options);

   $self->_setup_view($table) if $self->_is_data_call($options->{context});

   return $table;
}

sub _get_class {
   my ($self, $name) = @_;

   my $class = $self->namespace . "::${name}";

   ensure_class_loaded $class;

   return $class;
}

sub _is_data_call {
   my ($self, $c) = @_;

   my $requested_with = $c->request->header('X-Requested-With');

   return $requested_with && $requested_with eq 'XMLHttpRequest' ? 1 : 0;
}

sub _renderer_class {
   my ($self, $c) = @_;

   my $params = $c->request->query_parameters;

   return exists $params->{renderer_class} ? $params->{renderer_class} : undef;
}

sub _setup_view {
   my ($self, $table) = @_;

   my $c = $table->context;

   throw 'Undefined view [_1]', [$self->view_name]
      unless $c->view($self->view_name);

   my $params = $table->request->query_parameters;
   my $key    = $params->{$self->query_key} // q();

   if ($key eq $table->name) {
      $c->stash->{current_view} = $self->view_name;

      $c->stash->{$self->stash_key} = {
         format          => 'json',
         no_filename     => 1,
         serialiser_args => {
            disable_paging       => 0,
            serialise_as_hashref => 1,
            serialise_meta       => $params->{$self->meta_key} ? 1 : 0,
            serialise_record_key => 'name',
         },
         table           => $table,
      };
   }
}

1;
