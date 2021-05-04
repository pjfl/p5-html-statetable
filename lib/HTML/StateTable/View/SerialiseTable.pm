package HTML::StateTable::View::SerialiseTable;

use namespace::autoclean;

use HTML::StateTable::Constants qw( ITERATOR_DOWNLOAD_KEY SERIALISE_TABLE_KEY );
use HTML::StateTable::Util      qw( throw );
use Encode                      qw( encode_utf8 );
use Scalar::Util                qw( blessed );
use Moo;

extends qw( HTML::StateTable::View::IteratorDownload );

__PACKAGE__->config(
   serialisers => {
      csv      => 'CSV',
      csv_fast => 'CSVInflateHashRef',
      json     => 'JSON',
   }
);

sub process {
   my ($self, $c) = @_;

   my $key     = SERIALISE_TABLE_KEY;
   my $stashed = $c->stash->{$key};

   throw 'No config hashref in the [_1] stash key', [$key] unless $stashed;

   my $table  = $stashed->{table};
   my $format = $stashed->{format};
   my $args   = $stashed->{serialiser_args};

   my $serialiser_class = __PACKAGE__->config->{serialisers}->{$format};

   throw 'Unknown serialiser [_1]', [$format] unless $serialiser_class;

   my $writer     = _mk_writer($c->response);
   my $serialiser = $table->serialiser($serialiser_class, $writer, $args);
   my $filename   = $stashed->{no_filename}
      ? q() : $stashed->{filename} || $table->download_filename;
   my $config     = {
      filename    => $filename,
      no_filename => $stashed->{no_filename},
      object      => $serialiser,
   };

   $config->{mime_type} = $serialiser->mime_type if $serialiser->has_mime_type;
   $config->{extension} = $serialiser->extension if $serialiser->has_extension;

   $c->stash->{ITERATOR_DOWNLOAD_KEY()} = $config; # Belt

   return $self->next::method($c, $config); # and braces
}

sub guess_object_type {
   my ($self, $obj) = @_;

   return 'statetable'
      if blessed $obj && $obj->isa('HTML::StateTable::Serialiser');

   return;
}

sub output_statetable {
   my ($self, $c, $serialiser) = @_;

   $serialiser->serialise;
}

sub _mk_writer {
   my ($res) = @_;

   return sub { $res->write(encode_utf8(join q(), @_)) };
}

1;
