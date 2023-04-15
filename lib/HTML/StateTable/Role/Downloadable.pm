package HTML::StateTable::Role::Downloadable;

use HTML::StateTable::Constants qw( EXCEPTION_CLASS FALSE SERIALISE_TABLE_KEY
                                    SERIALISE_TABLE_VIEW TRUE );
use HTML::StateTable::Types     qw( Bool Str );
use HTML::StateTable::Util      qw( json_bool throw );
use Unexpected::Functions       qw( UnknownView );
use Moo::Role;

has 'downloadable' => is => 'ro', isa => Bool, default => TRUE;

has 'download_control_location' => is => 'ro', isa => Str,
   default => 'BottomRight';

has 'download_display' => is => 'ro', isa => Bool, default => TRUE;

has 'download_filename' =>
   is      => 'lazy',
   isa     => Str,
   default => sub { shift->name || 'download' };

has 'download_indicator' => is => 'ro', isa => Str, default => 'Downloading...';

has 'download_label' => is => 'ro', isa => Str, default => 'Download';

has 'download_method' => is => 'ro', isa => Str, default => 'csv';

has 'download_stash_key' =>
   is      => 'ro',
   isa     => Str,
   default => SERIALISE_TABLE_KEY;

has 'download_view_name' =>
   is      => 'ro',
   isa     => Str,
   default => SERIALISE_TABLE_VIEW;

after 'BUILD' => sub {
   my $self = shift;

   return unless $self->downloadable && $self->has_context;

   $self->add_role('downloadable', __PACKAGE__);

   throw UnknownView, [$self->download_view_name]
      unless $self->context->view($self->download_view_name);

   if (my $format = $self->param_value('download')) {
      $self->context->stash(
         view => $self->download_view_name,
         $self->download_stash_key => {
            filename => $self->download_filename,
            format   => $format,
            table    => $self,
         },
      );
   }
};

# Called by serialise_roles in EmptyDiv renderer
sub serialise_downloadable {
   my $self = shift;

   return {
      display   => json_bool $self->download_display,
      filename  => $self->download_filename,
      indicator => $self->download_indicator,
      label     => $self->download_label,
      location  => { control => $self->download_control_location },
      method    => $self->download_method,
   };
}

use namespace::autoclean;

1;
