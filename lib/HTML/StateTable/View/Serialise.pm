package HTML::StateTable::View::Serialise;

use HTML::StateTable::Constants qw( DOT EXCEPTION_CLASS EXTENSION_TYPE FALSE
                                    ITERATOR_DOWNLOAD_KEY NUL
                                    SERIALISE_TABLE_KEY SERIALISERS TRUE
                                    TYPE_EXTENSION );
use Encode                      qw( encode_utf8 );
use HTML::StateTable::Util      qw( dquote throw );
use Ref::Util                   qw( is_coderef is_hashref is_globref is_ref
                                    is_scalarref );
use Scalar::Util                qw( blessed );
use Unexpected::Functions       qw( Unspecified );

use Moo;

=pod

=encoding utf-8

=head1 Name

HTML::StateTable::View::Serialise - Serialise an HTML::StateTable object

=head1 Synopsis

   use Moo;

   extends 'HTML::StateTable::View::Serialise';

=head1 Description

A base class which should be subclassed by a view in the consuming application

=head1 Configuration and Environment

Defines no attributes

=head1 Subroutines/Methods

Defines the following methods;

=over 3

=item process( $context )

The context stash attribute C<_serialise_table> is expected to contain a hash
reference of configuration options;

=over 3

=item filename - String

=item no_filename - Boolean, if true no filename is supplied

=item format - String, either 'csv' or 'json'. Selects the class of the
serialiser object

=item table - The table object being serialised

=item serialiser_args - Hash reference of options supplied the serialiser
constructor method on the table object

=back

Alternatively set C<_iterator_download> in the context stash with the following
options;

=over 3

=item filename - String

=item no_filename - Boolean, if true no filename is supplied

=item mime_type - Optional string. Will guess if not supplied using the
filename extension

=item object - The object which will be serialised

=back

The serialised output is written to the context response object by one of the
output methods listed. Also sets response headers for content type and
disposition. Returns true

=cut

sub process {
   my ($self, $context) = @_;

   my $config;

   if (my $stashed = $context->stash->{SERIALISE_TABLE_KEY()}) {
      my $format = $stashed->{format};
      my $serialiser_class = SERIALISERS->{$format};

      throw 'Format [_1] unknown', [$format] unless $serialiser_class;

      my $response   = $context->response;
      my $writer     = sub { $response->write(encode_utf8(join NUL, @_)) };
      my $table      = $stashed->{table};
      my $args       = $stashed->{serialiser_args};
      my $serialiser = $table->serialiser($serialiser_class, $writer, $args);
      my $filename   = $stashed->{no_filename} ? NUL
                     : $stashed->{filename} || $table->download_filename;

      $config = {
         filename    => $filename,
         no_filename => $stashed->{no_filename} // FALSE,
         object      => $serialiser,
      };

      $config->{mime_type} = $serialiser->mime_type
         if $serialiser->has_mime_type;
      $config->{extension} = $serialiser->extension
         if $serialiser->has_extension;
   }
   else { $config = $context->stash->{ITERATOR_DOWNLOAD_KEY()} }

   throw Unspecified, ['config'] unless defined $config && is_hashref $config;

   my $filename = $config->{filename};

   throw Unspecified, ['filename'] if !$filename && !$config->{no_filename};

   my $mime_type = $self->_get_mime_type($config, $filename);

   throw Unspecified, ['mime_type'] unless $mime_type;

   my $object = $config->{object} || throw Unspecified, ['object'];
   my $object_type = $config->{type} || $self->guess_object_type($object);
   my $output_method = "output_${object_type}";

   throw 'Unknown object type [_1]', [$object_type]
      unless $self->can($output_method);

   throw 'Can only use line_ending option with iterators'
      if $output_method ne 'output_iterator' && defined $config->{line_ending};

   $self->_set_response_headers($context, $mime_type, $filename);
   $self->$output_method($context, $object, $config);
   return TRUE;
}

=item guess_object_type( $object )

Returns a string for each of these types of object; 'filehandle', 'iterator',
'string', 'coderef', and 'object'. Used to construct the output method name
C<< output_<type> >>

=cut

sub guess_object_type {
   my ($self, $obj) = @_;

   my $is_blessed = blessed $obj;

   return
      $is_blessed && $obj->can('serialise')                    ? 'object'
      : is_globref($obj) || ($is_blessed && $obj->isa('GLOB')) ? 'filehandle'
      : $is_blessed && $obj->can('next')                       ? 'iterator'
      : !is_ref($obj) || (!$is_blessed && is_scalarref($obj))  ? 'string'
      : is_coderef($obj)                                       ? 'coderef'
      : throw 'Object [_1] unidentifiable', [$obj];
}

=item output_coderef( $context, \&code )

Calls the passed code reference passing in the self referential object and the
context

=cut

sub output_coderef {
   my ($self, $context, $code) = @_;

   $code->($self, $context);
   return;
}

=item output_filehandle( $context, $fh )

Sets the context response body to the supplied file handle

=cut

sub output_filehandle {
   my ($self, $context, $fh) = @_;

   throw 'File handle is not a glob' unless $fh->isa('GLOB');

   $context->response->body($fh);
   return;
}

=item output_iterator( $context, $iterator, \%options )

Repeatedly calls the C<next> method on the iterator until exhausted. Encodes
as UTF8 and writes to the context response. If supplied options C<line_ending>
is appended to each chunk returned by the iterator

=cut

sub output_iterator {
   my ($self, $context, $iter, $options) = @_;

   throw "Iterator does not have a 'next' method" unless $iter->can('next');

   my $ending = $options->{line_ending};

   while (defined(my $chunk = $iter->next)) {
      $chunk .= $ending if defined $ending;

      $context->response->write(encode_utf8($chunk));
   }

   return;
}

=item output_object( $context, $object )

Returns the result of calling the C<serialise> method on the supplied object

=cut

sub output_object {
   my ($self, $context, $object) = @_; return $object->serialise;
}

=item output_string( $context, $string )

Encodes the supplied string as UTF8 and writes to the context response

=cut

sub output_string {
   my ($self, $context, $string) = @_;

   $string = ${$string} if is_scalarref($string) && !blessed($string);

   $context->response->write(encode_utf8($string));
   return;
}

# Private methods
sub _get_mime_type {
   my ($self, $options, $filename) = @_;

   my $mime_type = $options->{mime_type};

   return $mime_type unless $filename;

   my $ext = $options->{extension};

   $filename .= DOT . $ext if $ext;

   if (!$ext && $mime_type && $filename !~ m{ \. [^.]{2,4} \z }mx) {
      $filename .= DOT . TYPE_EXTENSION->{$mime_type};
   }

   (my $file_ext = $filename) =~ s{ \A .* \. }{}mx;

   $mime_type = EXTENSION_TYPE->{lc $file_ext} || $mime_type;
   $mime_type = EXTENSION_TYPE->{'other'} unless $mime_type;
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
