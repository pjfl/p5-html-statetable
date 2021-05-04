package HTML::StateTable::Types;

use strictures;

use Type::Library             -base, -declare =>
                          qw( Column Context DBIxClass DBIxClassResultSet
                              Element Iterable Options Renderer Request
                              ResultObject ResultRole ResultSet Row Table );
use Type::Utils           qw( as class_type coerce extends from
                              message subtype via where );
use Unexpected::Functions qw( inflate_message );

use namespace::clean -except => 'meta';

BEGIN { extends q(File::DataClass::Types) };

class_type Column,             { class => 'HTML::StateTable::Column' };
class_type Context,            { class => 'Catalyst' };
class_type DBIxClass,          { class => 'DBIx::Class' };
class_type DBIxClassResultSet, { class => 'DBIx::Class::ResultSet' };
class_type Element,            { class => 'HTML::Element' };
class_type Renderer,           { class => 'HTML::StateTable::Renderer' };
class_type Request,            { class => 'Catalyst::Request' };
class_type Row                 { class => 'HTML::StateTable::Row' };
class_type Table,              { class => 'HTML::StateTable' };

subtype Iterable => as Object, where {
      $_->can('next')
   && $_->can('pager')
   && $_->can('reset')
   && $_->can('search')
};

subtype Options => as HashRef;

coerce Options => from ArrayRef, via { { map { $_ => 1 } @{$_} } };

subtype ResultRole => as Object, where {
   $_->does('HTML::StateTable::Result::Role')
};

subtype ResultObject => as Object, where { DBIxClass | ResultRole };

subtype ResultSet => as Object, where { DBIxClassResultSet | Iterable };

1;
