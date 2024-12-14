# Name

HTML::StateTable - Displays tables from DBIC resultsets and other iterators

# Synopsis

    package YourApp::Table::User;

    use HTML::StateTable::Constants qw( FALSE NUL SPC TABLE_META TRUE );
    use Moo;
    use HTML::StateTable::Moo;

    extends 'HTML::StateTable';
    with    'HTML::StateTable::Role::Configurable';
    with    'HTML::StateTable::Role::Searchable';
    with    'HTML::StateTable::Role::CheckAll';
    with    'HTML::StateTable::Role::Form';
    with    'HTML::StateTable::Role::Active';

    has '+form_buttons' => default => sub {
       return [{
          action    => 'user/remove',
          class     => 'remove-item',
          selection => 'select_one',
          value     => 'Remove User',
       }];
    };

    has '+icons' => default => sub {
       return shift->context->request->uri_for('img/icons.svg')->as_string;
    };

    set_table_name 'user';

    has_column 'id' =>
       cell_traits => ['Numeric'],
       label       => 'ID',
       width       => '3rem';

    has_column 'name' =>
       label      => 'User Name',
       link       => sub {
          my $self    = shift;
          my $context = $self->table->context;

          return  $context->uri_for_action('user/view', [$self->result->id]);
       },
       searchable => TRUE,
       sortable   => TRUE,
       title      => 'Sort by user',
       width      => '10rem';

    has_column 'role_id' =>
       cell_traits => ['Capitalise'],
       label       => 'Role',
       searchable  => TRUE,
       sortable    => TRUE,
       title       => 'Sort by role',
       value       => 'role.name';

    has_column 'timezone' =>
       value => sub {
          my $self    = shift;
          my $profile = $self->result->profile;

          return $profile ? $profile->preference('timezone') : local_tz;
       },
       width => '15rem';

    has_column 'check' =>
       cell_traits => ['Checkbox'],
       label       => SPC,
       value       => 'id';

    use namespace::autoclean -except => TABLE_META;

# Description

A rich description of the required table is serialised to the browser via the
data attributes of an empty HTML `div` element. The JS running in the browser
renders the table a fetches row data from the server which it also renders.
User interactions with the table result in mutated query parameters on the
request for row data to the server. New row data is rendered without any page
reload. Stateful

## JavaScript

Files `wcom-*.js` are included in the `share/js` directory of the source
tree. These will be installed to the `File::ShareDir` distribution level
shared data files. Nothing further is done with these files. They should be
concatenated in sort order by filename and the result placed under the
webservers document root. Link to this from the web applications pages. Doing
this is outside the scope of this distribution

When content is loaded the JS method
`WCom.Table.Renderer.manager.scan(content)` must be called to inflate the
otherwise empty HTML `div` element. The function
`WCom.Util.Event.onReady(callback)` is available to install the scan when the
page loads

## Styling

A file `hstatetable-minimal.less` is included in the `share/less` directory
of the source tree.  This will be installed to [File::ShareDir](https://metacpan.org/pod/File%3A%3AShareDir) distribution
level shared data files. Nothing further is done with this file. It would need
compiling using the Node.js LESS compiler to produce a CSS file which should be
placed under the web servers document root and then linked to in the header of
the web applications pages. This is outside the scope of this distribution

## Example Usage

There is a simple [Catalyst](https://metacpan.org/pod/Catalyst) test application in the `t/lib` directory of the
source tree.

Catalyst components can create and stash a table object which are rendered
in the template by a call to the table objects `render` method

There is a repository for an example application on Github
(https://github.com/pjfl/p5-app-mcat). This contains a number of example tables
and the uses to which they can be put. That application uses [Web::Components](https://metacpan.org/pod/Web%3A%3AComponents)
which is also an Plack based MVC framework whose autoloaded components share
the same method signatures with [Catalyst](https://metacpan.org/pod/Catalyst)

# Configuration and Environment

Defines the following attributes;

- caption

    An mutable string with a null default. If set will display as the tables
    caption

- cell\_class

    A lazy loadable class that defaults to [HTML::StateTable::Cell](https://metacpan.org/pod/HTML%3A%3AStateTable%3A%3ACell)

- columns

    A lazy privately mutable array reference of `Column` objects in sorted order

- all\_columns

    Handled via array trait on `columns`

- context

    An optional `Context` object passed to the constructor. If supplied it is
    expected to contain a request object. Some table roles require this to
    function

- has\_context

    Predicate for the `context` attribute. Weakened reference

- displayable\_columns

    A lazy hash reference of booleans keyed by column name. Indicates that the
    column is displayable

- is\_displayable\_column

    Handled via the hash trait on `displayable_columns`

- empty\_text

    A string to display when there is no data

- icons

    An immutable string with a null default. URI of the SVG file containing named
    symbols. If not supplied default UTF-8 characters will be used instead

- is\_filtered

    A mutable boolean that defaults to false. Is set to true by the `Filterable`
    and `Searchable` table roles

- log

    Optional logging object used to log errors

- has\_log

    Predicate

- max\_page\_size

    A non zero positive integer that defaults to 100. The hard limit on the
    `page_size` attribute

- max\_width

    A string with a null default. Used to set the maximum width on the table

- name

    A non empty simple string that defaults to one supplied by the meta class

- no\_count

    A boolean which defaults to false. If set to true will prevent the counting
    of database table rows which in turn leads to the non displaying of the page
    count and the last link

- page

    A mutable non zero positive integer that defaults to 1. The number of the
    current page of data being displayed

- page\_control\_location

    An immutable non empty simple string which defaults to 'BottomLeft'. The
    location of the page control

- page\_manager

    An immutable simple string with a null default. Name of the JS page management
    object

- page\_size

    A mutable non zero positive integer which defaults to 20. The number of rows
    to be displayed per page. This is settable from preferences

- page\_size\_control\_location

    An immutable non empty simple string which defaults to 'BottomRight'. The
    location of the page size control

- pager

    The pager object on the prepared resultset. Lazy and immutable

- paging

    A mutable boolean which default to true. If false paging is disabled and no
    limit is placed on the number of rows retrieved from the database

- prepared\_resultset

    A required lazy `ResultSet` built from the `resultset` attribute. The builder
    method is `build_prepared_resultset`. The prepared resultset restricts the
    rows retrieved from the database to those requested by the `Searchable` and
    `Filterable` table roles

- has\_prepared\_resultset

    Predicate for `prepared_resultset`

- render\_style

    A mutable simple string which defaults to 'replace'. Used by the experimental
    animation feature to select which type of row replacement animation to use

- renderer

    The object used to render the table. Lazy and immutable

- renderer\_args

    A hash reference of arguments passed the renderer's constructor

- renderer\_class

    A lazy loadable class. The class name of the `renderer` object

- request

    A lazy weakened reference to the `Request` object supplied by the `context`

- resultset

    A [DBIx::Class::ResultSet](https://metacpan.org/pod/DBIx%3A%3AClass%3A%3AResultSet) object. Lazy and immutable

- row\_class

    A lazy loadable class which defaults to `HTML::StateTable::Row`. The class
    name for the row object

- row\_count

    The total row count as return by either the resultset pager object or the
    prepared resultset count depending on whether paging is enabled. Lazy immutable
    positive integer with no initialiser

- serialisable\_columns

    A lazy hash reference of booleans keyed by column name. Indicates that the
    column is serialisable

- is\_serialisable\_column

    Handled via the hash trait on `serialisable_columns`

- sort\_column\_name

    A mutable simple string which defaults to the first sortable column name

- sort\_desc

    A mutable boolean which defaults to false. If true the sort will be in
    descending order

- sortable

    A lazy boolean which is true if the number of sortable columns is greater
    than zero

- sortable\_columns

    A lazy array reference of `Column` objects with no initialiser

- title\_location

    Immutable string which defaults to `inner`. If set to `outer` causes the
    title and credit control divs to be rendered outside of the top and bottom
    control divs

- visisble\_columns

    A lazy array reference of `Column` objects that are not hidden

- all\_visible\_columns

    Handled via the array trait on `visible_columns`

# Subroutines/Methods

Defines the following methods;

- BUILDARGS

    Modifies the method in the base class. Allow the `renderer_class` to be
    specified without a fully qualified package name

- BUILD

    Called after object instantiation it applies parameters from the query string
    in the request object if context has been provided

- add\_role

        $table->add_role( $role_name, $class_name );

    Called by the applied table roles this method registers the role and it's
    class with the serialiser. Each table role is expected to implement a method
    called "serialise\_&lt;role\_name>"

- apply\_params

    If context is provided extracts query parameter values from the request and
    applies them to the table attributes. Query parameters are; `sort`, `desc`,
    `page`, and `page_size`

- build\_prepared\_resultset

    Applies column SQL, paging, and sorting to the supplied resultset

- get\_displayable\_columns

    Returns an array reference of displayable column objects

- get\_serialisable\_columns

    Returns an array reference of serialisable column objects

- next\_result

    Call `next` on the prepared resultset and returns the result

- next\_row

    Call `next_result` to obtain the next result object which is used to
    instantiate a row object which is returns

- param\_value

        $value = $table->param_value( $name );

    If context has been provided returns the named query parameter. Will look for
    "&lt;table name>\_&lt;param name>" in the query parameters and return it if it
    exists. If not will return "&lt;param name>" from the query parameters if that
    exists. If that does not exist then returns a null string

- reset\_resultset

    Resets the resultset so that `next` can be called again

- serialiser

        $serialiser = $table->serialiser( $moniker, \&writer, \%args );

    Returns the requested serialiser object. The `moniker` is the serialiser
    class without the prefix. The `writer` is a code reference that is called
    to write the serialised output. The `args` are passed to the constructor
    call for the serialiser object

- sort\_column

        $column = $table->sort_column( $column_name );

    Accessor mutator for `sort_column_name` attribute. Returns the current sort
    column object

- sorted\_columns

        @columns = $table->sorted_columns( @columns );

    Returns the supplied list of column objects sorted by their position attribute
    value

# Diagnostics

None

# Dependencies

See `dist.ini` for full list

- [Moo](https://metacpan.org/pod/Moo)
- [Unexpected](https://metacpan.org/pod/Unexpected)

# Incompatibilities

There are no known incompatibilities in this module

# Bugs and Limitations

There are no known bugs in this module. Please report problems to
http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-StateTable.
Patches are welcome

# Acknowledgements

Larry Wall - For the Perl programming language

# Author

Peter Flanigan, `<pjfl@cpan.org>`

# License and Copyright

Copyright (c) 2024 Peter Flanigan. All rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See [perlartistic](https://metacpan.org/pod/perlartistic)

This program is distributed in the hope that it will be useful,
but WITHOUT WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE
