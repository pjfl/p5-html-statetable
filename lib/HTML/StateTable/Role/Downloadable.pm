package HTML::StateTable::Role::Downloadable;

use HTML::StateTable::Constants qw( FALSE SERIALISE_TABLE_KEY
                                    SERIALISE_TABLE_VIEW TRUE );
use HTML::StateTable::Types     qw( Bool Str );
use HTML::StateTable::Util      qw( json_bool throw );
use Moo::Role;

has 'downloadable' => is => 'ro', isa => Bool, default => TRUE;

has 'download_display' => is => 'ro', isa => Bool, default => TRUE;

has 'download_filename' =>
   is      => 'lazy',
   isa     => Str,
   default => sub { shift->name || 'download' };

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

   $self->add_role('downloadable', __PACKAGE__);

   return unless $self->downloadable && $self->has_context;

   throw 'Undefined view [_1]', [$self->download_view_name]
      unless $self->context->view($self->download_view_name);

   if (my $format = $self->param_value('download')) {
      $self->context->stash->{view} = $self->download_view_name;

      $self->context->stash->{$self->download_stash_key} = {
         filename => $self->download_filename,
         format   => $format,
         table    => $self,
      };
   }
};

# Called by serialise_roles in EmptyDiv renderer
sub serialise_downloadable {
   my $self = shift;

   return $self->downloadable ? {
      display   => json_bool $self->download_display,
      filename  => $self->download_filename,
      label     => $self->download_label,
      location  => { control => 'BottomRight' },
      method    => $self->download_method,
      role_name => 'Downloadable',
   } : undef;
}

use namespace::autoclean;

1;
