# Name

HTML::StateTable - One-line description of the modules purpose

# Synopsis

    use HTML::StateTable;
    # Brief but working code examples

# Description

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
- row\_class
- row\_count
- serialisable\_columns
- sort\_column\_name
- sort\_desc
- sortable
- sortable\_columns
- visisble\_columns

# Subroutines/Methods

Defines the following methods;

- BUILDARGS
- BUILD
- add\_role
- build\_prepared\_resultset
- get\_displayable\_columns
- get\_serialisable\_columns
- next\_result
- next\_row
- param\_value
- reset\_resultset
- serialiser
- sort\_column
- sorted\_columns

# Diagnostics

None

# Dependencies

- [Moo](https://metacpan.org/pod/Moo)

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

Copyright (c) 2021 Peter Flanigan. All rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See [perlartistic](https://metacpan.org/pod/perlartistic)

This program is distributed in the hope that it will be useful,
but WITHOUT WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE
