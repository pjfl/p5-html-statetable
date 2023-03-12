package HTML::StateTable::View::Download;

use Encode                      qw( encode_utf8 );
use HTML::StateTable::Constants qw( DOT EXCEPTION_CLASS EXTENSION_TYPE
                                    ITERATOR_DOWNLOAD_KEY TRUE TYPE_EXTENSION );
use HTML::StateTable::Util      qw( dquote throw );
use Ref::Util                   qw( is_coderef is_hashref is_globref is_ref
                                    is_scalarref );
use Scalar::Util                qw( blessed );
use Unexpected::Functions       qw( Unspecified );
use Moo;

sub process {
   my ($self, $context) = @_;

   my $config = $context->stash->{ITERATOR_DOWNLOAD_KEY()};

   throw Unspecified, ['config'] unless defined $config && is_hashref $config;

   my $filename = $config->{filename};

   throw Unspecified, ['filename'] if !$filename && !$config->{no_filename};

   my $mime_type = $self->_get_mime_type($config, $filename);

   throw Unspecified, ['mime_type'] unless $mime_type;

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
   return TRUE;
}

sub guess_object_type {
   my ($self, $obj) = @_;

   return unless defined $obj;

   my $is_blessed = blessed $obj;

   return
      is_globref($obj) || ($is_blessed && $obj->isa('GLOB'))  ? 'filehandle'
      : $is_blessed && $obj->can('next')                      ? 'iterator'
      : !is_ref($obj) || (!$is_blessed && is_scalarref($obj)) ? 'string'
      : is_coderef($obj)                                      ? 'coderef'
      : undef;
}

sub output_coderef {
   my ($self, $context, $code) = @_;

   $code->($self, $context);
   return;
}

sub output_filehandle {
   my ($self, $context, $fh) = @_;

   throw 'File handle is not a glob' unless $fh->isa('GLOB');

   $context->response->body($fh);
   return;
}

sub output_iterator {
   my ($self, $context, $iter, $config) = @_;

   throw "Iterator does not have a 'next' method" unless $iter->can('next');

   my $ending = $config->{line_ending};

   while (defined(my $chunk = $iter->next)) {
      $chunk .= $ending if defined $ending;

      $context->response->write(encode_utf8($chunk));
   }

   return;
}

sub output_string {
   my ($self, $context, $string) = @_;

   $string = ${$string} if is_scalarref($string) && !blessed($string);

   $context->response->write(encode_utf8($string));
   return;
}

# Private methods
sub _get_mime_type {
   my ($self, $config, $filename) = @_;

   my $mime_type = $config->{mime_type};

   if ($filename) {
      my $ext = $config->{extension};

      $filename .= DOT . $ext if $ext;

      if (!$ext && $mime_type && $filename !~ m{ \. [^.]{2,4} \z }mx) {
         $filename .= DOT . TYPE_EXTENSION->{$mime_type};
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

   my @headers = ('Content-Type' => "${mime_type}; charset=utf-8");

   if ($filename) {
      push @headers, 'Content-Disposition',
         'attachment; filename=' . dquote $filename;
   }

   $context->response->header(@headers);
}

use namespace::autoclean;

1;
