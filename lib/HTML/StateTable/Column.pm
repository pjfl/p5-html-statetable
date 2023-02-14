package HTML::StateTable::Column;

use namespace::autoclean;

use HTML::StateTable::Column::Meta;
use HTML::StateTable::Constants qw( COLUMN_ALIAS COLUMN_META
                                    COLUMN_META_CONFIG FALSE SPC TRUE );
use HTML::StateTable::Types     qw( ArrayRef Bool CodeRef HashRef
                                    NonEmptySimpleStr Options PositiveInt
                                    ScalarRef Str );
use Ref::Util                   qw( is_coderef );
use Type::Utils                 qw( class_type );
use Scalar::Util                qw( blessed );
use Sub::Install                qw( install_sub );
use Moo;
use MooX::HandlesVia;

has 'append_to' => is => 'ro', isa => Str;

has 'as' =>
   is      => 'lazy',
   isa     => NonEmptySimpleStr,
   default => sub {
      my $self = shift;
      my $as   = COLUMN_ALIAS . $self->name;

      $as =~ s{ \. }{_}gmx;

      return $as,
   };

has 'bind_values' => is => 'ro', isa => CodeRef;

has 'cell_traits' => is => 'ro', isa => ArrayRef[Str], default => sub { [] };

has 'displayed' => is => 'rw', isa => Bool, default => TRUE;

has 'hidden' => is => 'ro', isa => CodeRef|Bool, reader => '_get_hidden';

has 'link' =>
   is        => 'ro',
   isa       => class_type('URI')|CodeRef|Str,
   predicate => 'has_link';

has 'label' => is => 'lazy', isa => Str, default => sub {
   my $self = shift;

   return 'ID' if $self->name eq 'id';

   return join SPC, map { ucfirst } split m{ [\s]+ }mx, $self->name;
};

has 'name' => is => 'ro', isa => NonEmptySimpleStr, required => TRUE;

has 'options' =>
   is          => 'ro',
   isa         => Options,
   coerce      => TRUE,
   handles_via => 'Hash',
   handles     => {
      add_option  => 'set',
      all_options => 'keys',
      get_option  => 'get',
   },
   default     => sub { {} };

has 'position' => is => 'ro', isa => PositiveInt, default => 0;

has 'sort_column' =>
   is        => 'ro',
   isa       => ArrayRef[NonEmptySimpleStr]|NonEmptySimpleStr,
   predicate => 'has_sort_column';

has 'sortable' => is => 'ro', isa => Bool, default => FALSE;

has 'sql' =>
   is        => 'ro',
   isa       => CodeRef|HashRef|Str,
   predicate => 'is_generated';

has 'value' =>
   is      => 'lazy',
   isa     => CodeRef|ScalarRef|Str,
   default => sub { shift->name };

has '_boolean_options' =>
   is          => 'ro',
   isa         => HashRef,
   handles_via => 'Hash',
   handles     => { is_boolean_option => 'exists' },
   default     => sub { { check_all => TRUE } };

sub import {
   my ($class, @args) = @_;

   my $target = __PACKAGE__;
   my $attr   = COLUMN_META;

   return if $target->can($attr);

   my $config = { COLUMN_META_CONFIG, target => $target, @args };
   my $meta   = HTML::StateTable::Column::Meta->new($config);

   install_sub { as => $attr, into => $target, code => sub { $meta } };
}

sub hidden {
   my ($self, $table) = @_;

   my $hidden = $self->_get_hidden;

   return is_coderef $hidden ? !!$hidden->($table) : !!$hidden;
}

sub create_cell {
   my ($self, $row) = @_;

   my $cell_class = $row->table->cell_class;
   my $cell = $cell_class->new(column => $self, row => $row);

   Role::Tiny->apply_roles_to_object($cell, @{$self->cell_traits})
      if scalar @{$self->cell_traits};

   return $cell;
}

sub _get_meta {
   my $self  = shift;
   my $class = blessed $self || $self;
   my $attr  = COLUMN_META;

   return $class->$attr;
}

1;
