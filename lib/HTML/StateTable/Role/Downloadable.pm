package HTML::StateTable::Role::Downloadable;

use HTML::StateTable::Constants qw( EXCEPTION_CLASS FALSE SERIALISE_TABLE_KEY
                                    SERIALISE_TABLE_VIEW TRUE );
use HTML::StateTable::Types     qw( Bool Str );
use HTML::StateTable::Util      qw( json_bool throw );
use Unexpected::Functions       qw( UnknownView );
use Moo::Role;

=pod

=encoding utf-8

=head1 Name

HTML::StateTable::Role::Downloadable - Enable table downloads as CSV or JSON

=head1 Synopsis

   use Moo;
   extends 'HTML::StateTable';
   with 'HTML::StateTable::Role::Downloadable';

=head1 Description

Enable table downloads as CSV or JSON

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item downloadable

An immutable boolean with a true default. If false the download options
will not be serialised

=cut

has 'downloadable' => is => 'ro', isa => Bool, default => TRUE;

=item download_control_location

An immutable string with a default of C<BottomRight>. The location of the
download link

=cut

has 'download_control_location' => is => 'ro', isa => Str,
   default => 'BottomRight';

=item download_display

An immutable boolean with a true default. If false the download link will not
be displayed. A download button will still appear on the configurable
preferences dialog

=cut

has 'download_display' => is => 'ro', isa => Bool, default => TRUE;

=item download_filename

An immutable lazy string which defaults to the table name. Default name of the
downloaded file

=cut

has 'download_filename' => is => 'lazy', isa => Str,
   default => sub { shift->name || 'download' };

=item download_indicator

An immutable string which defaults to C<Downloading...>. Displayed by the
front end during the download. If set to the null string no indication is
displayed

=cut

has 'download_indicator' => is => 'ro', isa => Str, default => 'Downloading...';

=item download_label

An immutable string with a default of C<Download>. Display label for the
download link

=cut

has 'download_label' => is => 'ro', isa => Str, default => 'Download';

=item download_method

An immutable string with a default of C<csv>. Can also be set to C<json>. The
required download format

=cut

has 'download_method' => is => 'ro', isa => Str, default => 'csv';

=item download_view_name

An immutable string with default supplied by the C<SERIALISE_TABLE_VIEW>
constant. The name of the view in the web application used to download a
table

=cut

has 'download_view_name' => is => 'ro', isa => Str,
   default => SERIALISE_TABLE_VIEW;

=back

=head1 Subroutines/Methods

Defines the following methods;

=over 3

=item BUILD

Executes after C<BUILD>. If the C<configurable> attribute is true and the table
has C<context> adds the C<serialise_downloadable> method to the call chain
used to serialise the table description

=cut

after 'BUILD' => sub {
   my $self = shift;

   return unless $self->downloadable && $self->has_context;

   $self->add_role('downloadable', __PACKAGE__);

   my $view = $self->download_view_name;

   throw UnknownView, [$view] unless $self->context->view($view);

   my $format = $self->param_value('download') or return;

   $self->context->stash(
      SERIALISE_TABLE_KEY() => {
         filename => $self->download_filename,
         format   => $format,
         table    => $self,
      },
      view => $view,
   );

   return;
};

=item serialise_downloadable

Called by C<serialise_roles> in C<EmptyDiv> renderer

=cut

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

__END__

=back

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Moo::Role>

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
