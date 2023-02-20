package HTML::StateTable::View::IteratorDownload;

use HTML::StateTable::Constants qw( EXCEPTION_CLASS EXTENSION_TYPE
                                    ITERATOR_DOWNLOAD_KEY TYPE_EXTENSION );
use HTML::StateTable::Util      qw( quote_double throw );
use Ref::Util                   qw( is_coderef is_hashref is_globref is_ref
                                    is_scalarref );
use Scalar::Util                qw( blessed );
use Unexpected::Functions       qw( Unspecified );
use Moo;

sub process {
   my ($self, $context, $config) = @_;

   my $key = ITERATOR_DOWNLOAD_KEY;

   $config //= $context->stash->{$key};

   throw 'No config hashref in the [_1] stash key', [$key]
      unless defined $config && is_hashref $config;

   my $filename = $config->{filename};

   throw Unspecified, ['filename'] if !$filename && !$config->{no_filename};

   my $mime_type = $self->_get_mime_type($config, $filename);

   throw 'No mime type specified or inferrable' unless $mime_type;

   my $object = $config->{object} || throw Unspecified, ['object'];
   my $object_type = $config->{type}
      || $self->guess_object_type($object)
      || throw 'Unidentifiable object [_1]', [$object];
   my $output_method = "output_${object_type}";

   throw 'Unknown object type [_1]', [$object_type]
      unless $self->can($output_method);

   throw 'Can only use line_ending option with iterators'
      if $output_method ne 'output_iterator' && defined $config->{line_ending};

   $self->_set_response_headers($context, $mime_type, $filename);

   $self->$output_method($context, $object, $config);

   return 1;
}

sub guess_object_type {
   my ($self, $obj) = @_;

   return unless defined $obj;

   my $is_blessed = blessed $obj;
   my $type
      = is_globref($obj) || ($is_blessed && $obj->isa('GLOB')) ? 'filehandle'
      : $is_blessed && $obj->can('next')                       ? 'iterator'
      : !is_ref($obj) || (!$is_blessed && is_scalarref($obj))  ? 'string'
      : is_coderef($obj)                                       ? 'coderef'
      : undef;

   return $type;
}

sub output_filehandle {
   my ($self, $context, $fh) = @_;

   throw 'File handle provided to iterator download view is not a glob'
      unless $fh->isa('GLOB');

   $context->res->body($fh);
}

sub output_iterator {
   my ($self, $context, $iter, $config) = @_;

   throw "Iterator provided to download view does not have a 'next' method"
      unless $iter->can('next');

   my $ending = $config->{line_ending};

   while (defined(my $chunk = $iter->next)) {
      $chunk .= $ending if defined $ending;

      $context->res->write(encode_utf8($chunk));
   }
}

sub output_string {
   my ($self, $context, $string) = @_;

   $string = ${$string} if is_scalarref($string) && !blessed($string);

   $context->res->write(encode_utf8($string));
}

sub output_coderef {
   my ($self, $context, $code) = @_;

   $code->($self, $context);
}

sub _get_mime_type {
   my ($self, $config, $filename) = @_;

   my $mime_type = $config->{mime_type};

   if ($filename) {
      my $ext = $config->{extension};

      $filename .= ".${ext}" if $ext;

      if (!$ext && $mime_type && $filename !~ m{ \. [^.]{2,4} \z }mx) {
         $filename .= '.' . TYPE_EXTENSION->{$mime_type};
      }

      unless ($mime_type) {
         (my $file_ext = $filename) =~ s{ \A .* \. }{}mx;

         $mime_type ||= EXTENSION_TYPE->{lc $file_ext};

         $mime_type = EXTENSION_TYPE->{'other'} unless $mime_type;
      }
   }

   return $mime_type;
}

sub _set_response_headers {
   my ($self, $context, $mime_type, $filename) = @_;

   my @headers = (Content_Type => "${mime_type}; charset=utf-8");

   if ($filename) {
      push @headers,
         'Content_Disposition',
         'attachment; filename=' . quote_double $filename;
   }

   $context->res->header(@headers);
}

use namespace::autoclean;

1;
