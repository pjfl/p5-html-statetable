package HTML::StateTable::Manager;

use namespace::autoclean;

use HTML::StateTable::Constants qw( EXCEPTION_CLASS FALSE QUERY_KEY
                                    SERIALISE_TABLE_KEY SERIALISE_TABLE_VIEW
                                    TRUE );
use HTML::StateTable::Types     qw( Str );
use HTML::StateTable::Util      qw( throw );
use File::DataClass::Functions  qw( ensure_class_loaded );
use Unexpected::Functions       qw( Unspecified );

use Moo;

has 'meta_key' => is => 'ro', isa => Str, default => 'table_meta';

has 'namespace' => is => 'ro', isa => Str, required => TRUE;

has 'query_key' => is => 'ro', isa => Str, predicate => 'has_query_key';

has 'renderer_class' =>
   is        => 'ro',
   isa       => Str,
   predicate => 'has_renderer_class';

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

sub new_with_context {
   my ($self, $name, $options) = @_; return $self->table($name, $options);
}

sub _get_class {
   my ($self, $name) = @_;

   my $class = $self->namespace . "::${name}";

   ensure_class_loaded $class;

   return $class;
}

sub _is_data_call {
   my ($self, $context) = @_;

   throw Unspecified, ['context'] unless $context;

   my $requested_with = $context->request->header('X-Requested-With')
      || $context->request->header('x-requested-with');

   return $requested_with && $requested_with eq 'XMLHttpRequest' ? TRUE : FALSE;
}

sub _renderer_class {
   my ($self, $context) = @_;

   if ($context) {
      my $params = $context->request->query_parameters;

      return $params->{renderer_class} if exists $params->{renderer_class};
   }

   return $self->renderer_class if $self->has_renderer_class;

   return;
}

sub _setup_view {
   my ($self, $table) = @_;

   my $context = $table->context;

   throw 'Undefined view [_1]', [$self->view_name]
      unless $context->view($self->view_name);

   my $params = $table->request->query_parameters;
   my $key    = $params->{$self->query_key} // q();

   if ($key eq $table->name) {
      $context->stash->{current_view} = $self->view_name;

      $context->stash->{$self->stash_key} = {
         format          => 'json',
         no_filename     => TRUE,
         serialiser_args => {
            disable_paging => FALSE,
            serialise_meta => $params->{$self->meta_key} ? TRUE : FALSE,
         },
         table           => $table,
      };
   }
}

1;
