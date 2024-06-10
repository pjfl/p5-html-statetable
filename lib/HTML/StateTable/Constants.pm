package HTML::StateTable::Constants;

use strictures;

use HTML::StateTable::Exception;

use Sub::Exporter -setup => { exports => [ qw(
 CELL_TRAIT_PREFIX COL_INFO_TYPE_ATTR COLUMN_ALIAS COLUMN_META
 COLUMN_TRAIT_PREFIX COMMA DOT DQUOTE EOL
 EXCEPTION_CLASS EXTENSION_TYPE FALSE ITERATOR_DOWNLOAD_KEY
 MAX_FILTER_ROWS NUL PIPE QUERY_KEY RENDERER_CLASS RENDERER_PREFIX
 SERIALISE_COLUMN_ATTR SERIALISE_TABLE_KEY SERIALISE_TABLE_VIEW SERIALISERS
 SPC TABLE_META TRIGGER_CLASS TRUE TYPE_EXTENSION
)]};

=pod

=encoding utf-8

=head1 Name

HTML::StateTable::Constants - Constants used by this distribution

=head1 Synopsis

   use HTML::StateTable::Constants;

=head1 Description

Constants definitions

=head1 Configuration and Environment

Defines the following constants;

=over 3

=item CELL_TRAIT_PREFIX

Namespace prefix for cell traits

=cut

sub CELL_TRAIT_PREFIX () { 'HTML::StateTable::Cell::Trait' }

=item COL_INFO_TYPE_ATTR

The data type attribute name in the L<DBIx::Class> result column info

=cut

sub COL_INFO_TYPE_ATTR () { 'data_type' }

=item COLUMN_ALIAS

Prefix for the names of generated columns which makes the distinct from
the column name

=cut

sub COLUMN_ALIAS () { 'hst_' }

=item COLUMN_META

The name of the class attribute containing the column meta object

=cut

sub COLUMN_META () { '_html_statetable_column_meta' }

=item COLUMN_TRAIT_PREFIX

Namespace prefix for column traits

=cut

sub COLUMN_TRAIT_PREFIX () { 'HTML::StateTable::Column::Trait' }

=item COMMA

The comma character

=cut

sub COMMA () { q(,) }

=item DOT

The period character

=cut

sub DOT () { q(.) }

=item DQUOTE

The double quote character

=cut

sub DQUOTE () { q(") }

=item EOL

Line ending characters used in CSV file output

=cut

sub EOL () { "\r\n" }

=item EXCEPTION_CLASS

The exception class used when raising an exception

=cut

sub EXCEPTION_CLASS () { __PACKAGE__->Exception_Class }

=item EXTENSION_TYPE

A map of file name extensions to mime types

=cut

sub EXTENSION_TYPE () {
   return {
      'tar.gz' => 'application/x-tar',
      csv      => 'text/csv',
      doc      => 'application/msword',
      docx     => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      eml      => 'message/rfc822',
      gif      => 'image/gif',
      gz       => 'application/x-tar',
      htm      => 'text/html',
      html     => 'text/html',
      ics      => 'text/calendar',
      jpg      => 'image/jpeg',
      json     => 'application/json',
      other    => 'octet-stream',
      pdf      => 'application/pdf',
      png      => 'image/png',
      ppt      => 'application/vnd.ms-powerpoint',
      tsv      => 'text/tab-separated-values',
      txt      => 'text/plain',
      vcs      => 'text/calendar',
      xls      => 'application/vnd.ms-excel',
      xlsx     => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      xml      => 'text/xml',
      zip      => 'application/zip',
   };
}

=item FALSE

Boolean false

=cut

sub FALSE () { 0 }

=item ITERATOR_DOWNLOAD_KEY

The context stash key used to supply the downloader with configuration options

=cut

sub ITERATOR_DOWNLOAD_KEY () { '_iterator_download' }

=item MAX_FILTER_ROWS

The maximum number of rows to return in response to a filter values request

=cut

sub MAX_FILTER_ROWS () { 500 }

=item NUL

The null (zero length) string

=cut

sub NUL () { q() }

=item PIPE

The pipe character

=cut

sub PIPE () { q(|) }

=item QUERY_KEY

The name of the query parameter containing the table name

=cut

sub QUERY_KEY () { 'table_name' }

=item RENDERER_CLASS

The name of the default renderer class

=cut

sub RENDERER_CLASS () { 'EmptyDiv' }

=item RENDERER_PREFIX

Namespace prefix for the renderer classes

=cut

sub RENDERER_PREFIX () { 'HTML::StateTable::Renderer' }

=item SERIALISE_COLUMN_ATTR

List of column names to serialise

=cut

sub SERIALISE_COLUMN_ATTR () {
   return qw( cell_traits filterable label min_width name options
              searchable sort_column sortable title width );
}

=item SERIALISE_TABLE_KEY

The context stash key used to supply the serialiser with configuration options

=cut

sub SERIALISE_TABLE_KEY () { '_serialise_table' }

=item SERIALISE_TABLE_VIEW

Default view name that is used to serialise the table

=cut

sub SERIALISE_TABLE_VIEW () { 'serialise_table' }

=item SERIALISERS

Lookup hash reference mapping serialiser formats to classes

=cut

sub SERIALISERS () { { csv => 'CSV', json => 'JSON' } }

=item SPC

The space character

=cut

sub SPC () { q( ) }

=item TABLE_META

The name of the class attribute containing the table meta object

=cut

sub TABLE_META () { '_html_statetable_meta' }

=item TRIGGER_CLASS

CSS class name used by the empty div renderer to trigger the JS

=cut

sub TRIGGER_CLASS () { 'state-table' }

=item TRUE

Boolean true

=cut

sub TRUE () { 1 }

=item TYPE_EXTENSION

Reverse of the extension type map

=cut

sub TYPE_EXTENSION () { my $map = EXTENSION_TYPE; return { reverse %{$map} } }

=back

=head1 Subroutines/Methods

Defines the following class methods;

=over 3

=item Exception_Class( $class )

Validating accessor/mutator for the class attribute of the same name. This
value is returned by the C<EXCEPTION_CLASS> constant

=cut

my $exception_class = 'HTML::StateTable::Exception';

sub Exception_Class {
   my ($self, $class) = @_;

   return $exception_class unless defined $class;

   die "Class '${class}' is not loaded or has no 'throw' method"
      unless $class->can('throw');

   return $exception_class = $class;
}

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
