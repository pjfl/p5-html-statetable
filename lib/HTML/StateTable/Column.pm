package HTML::StateTable::Column;

use HTML::StateTable::Constants qw( COLUMN_ALIAS COLUMN_META CELL_TRAIT_PREFIX
                                    FALSE SPC TRUE );
use HTML::StateTable::Types     qw( ArrayRef Bool CodeRef HashRef
                                    NonEmptySimpleStr Options PositiveInt
                                    ScalarRef Str );
use Ref::Util                   qw( is_blessed_ref is_coderef );
use Type::Utils                 qw( class_type );
use Scalar::Util                qw( blessed );
use Sub::Install                qw( install_sub );
use HTML::StateTable::Column::Meta;
use Moo::Role ();
use Moo;
use MooX::HandlesVia;

=pod

=encoding utf-8

=head1 Name

HTML::StateTable::Column - Column class

=head1 Synopsis

   use HTML::StateTable::Column;

=head1 Description

Table column class

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item append_to

An immutable string without default. If set if signifies the named column to
which this column will append it's values. Used by the
L<HTML::StateTable::Role::Tag> table role

=cut

has 'append_to' => is => 'ro', isa => Str;

=item as

A lazy non empty simple string whose default is created from the column name.
Used in the creation of a generated column value, see C<sql>

=cut

has 'as' =>
   is      => 'lazy',
   isa     => NonEmptySimpleStr,
   default => sub {
      my $self = shift;
      my $as   = COLUMN_ALIAS . $self->name;

      $as =~ s{ \. }{_}gmx;

      return $as,
   };

=item bind_values

An immutable code reference used in the creation of a generated column
value. See C<sql>

=cut

has 'bind_values' => is => 'ro', isa => CodeRef;

=item cell_traits

An immutable array reference of string with an empty array reference default

=cut

has 'cell_traits' => is => 'ro', isa => ArrayRef[Str], default => sub { [] };

=item displayed

A mutable boolean with a true default

=cut

has 'displayed' => is => 'rw', isa => Bool, default => TRUE;

=item filter

An immutable optional code reference that gets called if it's set to turn
C<unfiltered_value> on the cell object into a filtered one. The cell object
calls this passing in the value and the cell object reference

=item has_filter

Predicate

=cut

has 'filter' => is => 'ro', isa => CodeRef, predicate => 'has_filter';

=item hidden

An optional immutable boolean or code reference. If true the column is
hidden. If a code reference is set it will be called passing in the table
object

=item has_hidden

Predicate

=cut

has 'hidden' =>
   is        => 'ro',
   isa       => CodeRef|Bool,
   predicate => 'has_hidden',
   reader    => '_get_hidden';

=item link

An optional immutable C<URI>, or code reference, or string. If set the cell
value will display as a link

=item has_link

Predicate

=cut

has 'link' =>
   is        => 'ro',
   isa       => class_type('URI')|CodeRef|Str,
   predicate => 'has_link';

=item label

A lazy string which defaults to the column name with the first letter
capitalised

=cut

has 'label' => is => 'lazy', isa => Str, default => sub {
   my $self = shift;

   return 'ID' if $self->name eq 'id';

   return join SPC, map { ucfirst } split m{ [\s]+ }mx, $self->name;
};

=item min_width

Optional immutable string. Used to set a minimum width on the column when it
displays

=cut

has 'min_width' => is => 'ro', isa => Str;

=item name

A required immutable non empty simple string. The column name

=cut

has 'name' => is => 'ro', isa => NonEmptySimpleStr, required => TRUE;

=item options

An immutable hash reference which defaults to an empty hash reference

Handles C<add_option>, C<all_options>, and C<get_option> via the hash trait

=cut

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

=item position

A mutable positive integer with a default of zero. Columns are sorted into
order on this value

=cut

has 'position' => is => 'rw', isa => PositiveInt, default => 0;

=item serialised

A mutable boolean with a true default. If false this column will no longer
be serialised into the output

=cut

has 'serialised' => is => 'rw', isa => Bool, default => TRUE;

=item sort_column

An immutable array reference of non empty simple strings, or a non empty
simple string. The column to sort on

=item has_sort_column

Predicate

=cut

has 'sort_column' =>
   is        => 'ro',
   isa       => ArrayRef[NonEmptySimpleStr]|NonEmptySimpleStr,
   predicate => 'has_sort_column';

=item sortable

An immutable boolean which defaults false. If true this column is deemed
sortable

=cut

has 'sortable' => is => 'ro', isa => Bool, default => FALSE;

=item sql

An optional immutable code reference, or hash reference, or string. If set
the literal SQL is applied to the prepared resultset along with the
C<bind_values> and is selected as C<as>.

Has a predicate C<is_generated> which signifies this column value is to be
generated by including this SQL in the prepared resultset

=item is_generated

Predicate for the C<sql> attribute

=cut

has 'sql' =>
   is        => 'ro',
   isa       => CodeRef|HashRef|Str,
   predicate => 'is_generated';

=item value

A lazy code reference, or scalar reference, or string it defaults to the column
name. The value displayed in this column header

=cut

has 'value' =>
   is      => 'lazy',
   isa     => CodeRef|ScalarRef|Str,
   default => sub { shift->name };

=item width

Optional immutable string. Used to set a fixed width on the column when it
displays

=cut

has 'width' => is => 'ro', isa => Str;

# Private attributes
has '_boolean_options' =>
   is          => 'ro',
   isa         => HashRef,
   handles_via => 'Hash',
   handles     => { is_boolean_option => 'exists' },
   default     => sub {
      return { checkall => TRUE, notraits => TRUE, select_one => TRUE };
   };

=back

=head1 Subroutines/Methods

Defines the following methods;

=over 3

=item BUILD

Placeholder to be modified by applied traits

=cut

sub BUILD {}

=item create_cell( $row )

Creates and return a new instance of the cell class passing both column (self)
and row object references into the constructor. Also applies the cell traits to
the new cell object before returning it

=cut

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

=item hidden( $table )

Called by the cell object to determine if the column is hidden. Returns a
boolean

=cut

sub hidden {
   my ($self, $table) = @_;

   my $hidden = $self->_get_hidden;

   return is_coderef $hidden ? !!$hidden->($table) : !!$hidden;
}

=item import( @args )

Called automatically when this column class is used. This method calls
C<import_meta> to import the meta class into this column class

=cut

sub import {
   my ($class, @args) = @_; return $class->import_meta(__PACKAGE__, @args);
}

=item import_meta( $target, @args )

Installs an instance of the column meta object
L<HTML::StateTable::Column::Meta> into the C<target> class. The optional
C<args> are passed to the constructor for the meta object along with the
C<target> class

=cut

sub import_meta {
   my ($class, $target, @args) = @_;

   my $attr = COLUMN_META;
   {
      no strict 'refs'; return if *{ "${target}::${attr}" }{CODE};
   }
   my $config = { target => $target, @args };
   my $meta   = HTML::StateTable::Column::Meta->new($config);

   install_sub { as => $attr, into => $target, code => sub { $meta } };
   return;
}

=item new_with_traits( $class, %args )

Creates a new instance of C<class> which it returns. The C<traits> array
reference is delete from the optional C<args> and the list traits are applied
to C<class> before it is instantiated. That composite class has the column
meta object installed. The remaining attributes of the C<args> hash are
passed the object constructor

=cut

sub new_with_traits {
   my ($class, %args) = @_;

   my $traits = delete $args{traits} || [];

   $class = blessed $class if is_blessed_ref $class;

   $class = Moo::Role->create_class_with_roles($class, @{$traits})
      if scalar @{$traits};

   $class->import_meta($class);

   return $class->new(%args);
}

# Private methods
sub _get_meta {
   my $self  = shift;
   my $class = blessed $self || $self;
   my $attr  = COLUMN_META;

   return $class->$attr;
}

use namespace::autoclean;

1;

__END__

=back

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Moo>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module. Please report problems to
http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-StateTable.
Patches are welcome

=head1 Acknowledgements

Larry Wall - For the Perl programming language

=head1 Author

Peter Flanigan, C<< <pjfl@cpan.org> >>

=head1 License and Copyright

Copyright (c) 2024 Peter Flanigan. All rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>

This program is distributed in the hope that it will be useful,
but WITHOUT WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE

=cut

# Local Variables:
# mode: perl
# tab-width: 3
# End:
# vim: expandtab shiftwidth=3:
