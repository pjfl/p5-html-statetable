package HTML::StateTable::Column;

use HTML::StateTable::Column::Meta;
use HTML::StateTable::Constants qw( COLUMN_ALIAS COLUMN_META
                                    COLUMN_META_CONFIG CELL_TRAIT_PREFIX
                                    FALSE SPC TRUE );
use HTML::StateTable::Types     qw( ArrayRef Bool CodeRef HashRef
                                    NonEmptySimpleStr Options PositiveInt
                                    ScalarRef Str );
use Ref::Util                   qw( is_blessed_ref is_coderef );
use Type::Utils                 qw( class_type );
use Scalar::Util                qw( blessed );
use Sub::Install                qw( install_sub );
use Moo::Role ();
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

has 'hidden' =>
   is        => 'ro',
   isa       => CodeRef|Bool,
   predicate => 'has_hidden',
   reader    => '_get_hidden';

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
   my ($class, @args) = @_; return $class->import_meta(__PACKAGE__, @args);
}

sub create_cell {
   my ($self, $row) = @_;

   my $cell_class = $row->table->cell_class;
   my $cell = $cell_class->new(column => $self, row => $row);

   if (scalar @{$self->cell_traits}) {
      my @traits = map {
         ('+' eq substr $_, 0, 1) ? substr $_, 1 : CELL_TRAIT_PREFIX . "::${_}";
      } @{$self->cell_traits};

      Role::Tiny->apply_roles_to_object($cell, @traits);
   }

   return $cell;
}

sub hidden {
   my ($self, $table) = @_;

   my $hidden = $self->_get_hidden;

   return is_coderef $hidden ? !!$hidden->($table) : !!$hidden;
}

sub import_meta {
   my ($class, $target, @args) = @_;

   my $config = { COLUMN_META_CONFIG, target => $target, @args };
   my $meta   = HTML::StateTable::Column::Meta->new($config);
   my $attr   = COLUMN_META;
   {
      no strict 'refs'; return if *{ "${target}::${attr}" }{CODE};
   }
   install_sub { as => $attr, into => $target, code => sub { $meta } };
   return;
}

sub new_with_traits {
   my ($class, %args) = @_;

   my $traits = delete $args{traits} || [];

   $class = blessed $class if is_blessed_ref $class;

   $class = Moo::Role->create_class_with_roles($class, @{$traits})
      if scalar @{$traits};

   $class->import_meta($class);

   return $class->new(%args);
}

sub _get_meta {
   my $self  = shift;
   my $class = blessed $self || $self;
   my $attr  = COLUMN_META;

   return $class->$attr;
}

use namespace::autoclean;

1;
