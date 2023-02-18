package HTML::StateTable::Constants;

use strictures;

use Sub::Exporter -setup => {
	exports => [
      qw( COL_INFO_TYPE_ATTR COLUMN_ALIAS COLUMN_META COLUMN_META_CONFIG
          ENCODE_ENTITIES EXCEPTION_CLASS EXTENSION_TYPE FALSE INDENT_CHARS
          ITERATOR_DOWNLOAD_KEY NUL QUERY_KEY RENDERER_CLASS RENDERER_PREFIX
          SERIALISE_COLUMN_ATTR SERIALISE_TABLE_KEY SERIALISE_TABLE_VIEW
          SPC TABLE_META TABLE_META_CONFIG TRIGGER_CLASS TRUE TYPE_EXTENSION )
      ],
};

sub COL_INFO_TYPE_ATTR () { 'data_type' }

sub COLUMN_ALIAS () { 'hst_' }

sub COLUMN_META () { '_html_statetable_column_meta' }

sub COLUMN_META_CONFIG () { () }

sub ENCODE_ENTITIES () { q(<>&") }

my $exception_class = 'File::DataClass::Exception';

sub Exception_Class { # Validating accessor/mutator for class attribute
   my ($self, $class) = @_;

   return $exception_class unless defined $class;

   die "Class '${class}' is not loaded or has no 'throw' method"
      unless $class->can('throw');

   return $exception_class = $class;
}

sub EXCEPTION_CLASS () { __PACKAGE__->Exception_Class }

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

sub FALSE () { 0 }

sub INDENT_CHARS () { q() }

sub ITERATOR_DOWNLOAD_KEY () { '_iterator_download' }

sub NUL () { q() }

sub QUERY_KEY () { 'table_name' }

sub RENDERER_CLASS () { 'EmptyDiv' }

sub RENDERER_PREFIX () { 'HTML::StateTable::Renderer' }

sub SERIALISE_COLUMN_ATTR () {
   return qw( cell_traits css_class filterable label
              name options searchable sort_column sortable width );
}

sub SERIALISE_TABLE_KEY () { '_serialise_table' }

sub SERIALISE_TABLE_VIEW () { 'SerialiseTable' }

sub SPC () { q( ) }

sub TABLE_META () { '_html_statetable_meta' }

sub TABLE_META_CONFIG () { () }

sub TRIGGER_CLASS () { 'state-table' }

sub TRUE () { 1 }

sub TYPE_EXTENSION () { my $map = EXTENSION_TYPE; return { reverse %{$map} } }

1;
