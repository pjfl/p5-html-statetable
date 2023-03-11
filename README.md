# Name

HTML::StateTable - Displays tables from DBIC resultsets

# Synopsis

    use HTML::StateTable;

# Description

A rich description of the required table is serialised to the browser via the
data attributes of an empty `div` element. The JS running in the browser
renders the table a fetches row data from the server which it also renders.
User interactions with the table result in mutated query parameters on the
request for row data to the server. New row data is rendered without any page
reload

# Configuration and Environment

Defines the following attributes;

- cell\_class

    A lazy loadable class that defaults to [HTML::StateTable::Cell](https://metacpan.org/pod/HTML%3A%3AStateTable%3A%3ACell)

- columns

    A lazy privately mutable array reference of `Column` objects in sorted order

    Handles `all_columns` via array trait

- context

    An optional `Context` object passed to the constructor. If supplied it is
    expected to contain a request object. Some table roles require this to
    function

- displayable\_columns

    A lazy hash reference of booleans keyed by column name. Indicates that the
    column is displayable

    Handles `is_displayable_column` via the hash trait

- empty\_text

    A string to display when there is no data

- is\_filtered

    A mutable boolean that defaults to false. Is set to true by the `Filterable`
    and `Searchable` table roles

- max\_page\_size

    A non zero positive integer that defaults to 100. The hard limit on the
    `page_size` attribute

- name

    A non empty simple string that defaults to one supplied by the meta class

- no\_count

    A boolean which defaults to false. If set to true will prevent the counting
    of database table rows which in turn leads to the non displaying of the page
    count and the last link

- page

    A mutable non zero positive integer that defaults to 1. The number of the
    current page of data being displayed

- page\_size

    A mutable non zero positive integer which defaults to 20. The number of rows
    to be displayed per page. This is settable from preferences

- pager

    The pager object on the prepared resultset

- paging

    A mutable boolean which default to true. If false paging is disabled and no
    limit is placed on the number of rows retrieved from the database

- prepared\_resultset

    A required lazy `ResultSet` built from the `resultset` attribute. The
    builder method is `build_prepared_resultset`. The prepared resultset restricts
    the row retrieved from the database to those requested by the `Searchable` and
    `Filterable` table roles

- renderer

    The object used to render the table

- renderer\_args

    A hash reference of arguments passed the renderer's constructor

- renderer\_class

    A lazy loadable class. The class name of the `renderer` object

- request

    A lazy `Request` object supplied by the `context`

- resultset

    A [DBIx::Class::ResultSet](https://metacpan.org/pod/DBIx%3A%3AClass%3A%3AResultSet) object

- row\_class

    A lazy loadable class which defaults to `HTML::StateTable::Row`. The class
    name for the row object

- row\_count

    The total row count as return by either the resultset pager object or the
    prepared resultset count depending on whether paging is enabled

- serialisable\_columns

    A lazy hash reference of booleans keyed by column name. Indicates that the
    column is serialisable

    Handles `is_serialisable_column` via the hash trait

- sort\_column\_name

    A mutable simple string which defaults to the first sortable column name

- sort\_desc

    A mutable boolean which defaults to false. If true the sort will be in
    descending order

- sortable

    A lazy boolean which is true if the number of sortable columns is greater
    than zero

- sortable\_columns

    A lazy array reference of `Column` objects

- visisble\_columns

    A lazy array reference of `Column` objects that are not hidden.

    Handles `all_visible_columns` via the array trait

# Subroutines/Methods

Defines the following methods;

- BUILDARGS

    Modifies the method in the base class. Allow the renderer to be specified
    without a fully qualified package name

- BUILD

    Called after object instantiation it applys parameters from the query string
    in the request object if context has been provided

- add\_role( role\_name, class\_name )

    Called by the applied table roles this method registers the role and it's
    class with the serialiser. Each table role is expected to implement a method
    called "serialise\_&lt;role\_name>"

- build\_prepared\_resultset

    Applies column SQL, paging, and sorting to the supplied resultset

- get\_displayable\_columns

    Returns an array reference of displayable column objects

- get\_serialisable\_columns

    Returns an array reference of serialisable column objects

- next\_result

    Call `next` on the resultset and returns the result

- next\_row

    Call `next_result` to obtain the next result object which it uses to
    instantiate a row object which it returns

- param\_value( name )

    If context has been provided returns the named query parameter. Will look for
    "&lt;table name>\_&lt;param name>" in the query parameters and return it if it
    exists

- reset\_resultset

    Resets the resultset so that `next` can be called again

- serialiser( moniker, writer, args )

    Returns the requested serialiser object. The `moniker` is the serialiser
    class without the prefix. The `writer` is a code reference that is called
    to write the serialised output. The `args` are passed to the constructor
    call for the serialiser object

- sort\_column( column\_name )

    Accessor mutator for `sort_column_name` attribute. Returns the current sort
    column object

- sorted\_columns( @columns )

    Returns the list of column objects sorted by their position attriute value

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

Copyright (c) 2023 Peter Flanigan. All rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See [perlartistic](https://metacpan.org/pod/perlartistic)

This program is distributed in the hope that it will be useful,
but WITHOUT WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE
