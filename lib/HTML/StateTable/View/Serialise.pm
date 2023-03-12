package HTML::StateTable::View::Serialise;

use HTML::StateTable::Constants qw( FALSE ITERATOR_DOWNLOAD_KEY
                                    NUL SERIALISE_TABLE_KEY
                                    SERIALISERS );
use HTML::StateTable::Util      qw( throw );
use Encode                      qw( encode_utf8 );
use Scalar::Util                qw( blessed );
use Moo;

extends 'HTML::StateTable::View::Download';

sub process {
   my ($self, $context) = @_;

   my $key     = SERIALISE_TABLE_KEY;
   my $stashed = $context->stash->{$key};

   throw 'No config hashref in the [_1] stash key', [$key] unless $stashed;

   my $table  = $stashed->{table};
   my $format = $stashed->{format};
   my $args   = $stashed->{serialiser_args};

   my $serialiser_class = SERIALISERS->{$format};

   throw 'Unknown serialiser [_1]', [$format] unless $serialiser_class;

   my $response   = $context->response;
   my $writer     = sub { $response->write(encode_utf8(join NUL, @_)) };
   my $serialiser = $table->serialiser($serialiser_class, $writer, $args);
   my $filename   = $stashed->{no_filename}
      ? NUL : $stashed->{filename} || $table->download_filename;
   my $config     = {
      filename    => $filename,
      no_filename => $stashed->{no_filename} // FALSE,
      object      => $serialiser,
   };

   $config->{mime_type} = $serialiser->mime_type if $serialiser->has_mime_type;
   $config->{extension} = $serialiser->extension if $serialiser->has_extension;

   $context->stash->{ITERATOR_DOWNLOAD_KEY()} = $config; # Belt

   return $self->next::method($context, $config); # and braces
}

sub guess_object_type {
   my ($self, $obj) = @_;

   return 'statetable'
      if blessed $obj && $obj->isa('HTML::StateTable::Serialiser');

   return;
}

sub output_statetable {
   my ($self, $context, $serialiser) = @_;

   return $serialiser->serialise;
}

use namespace::autoclean;

1;
