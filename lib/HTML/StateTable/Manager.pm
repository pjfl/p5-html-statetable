package HTML::StateTable::Manager;

use HTML::StateTable::Constants qw( EXCEPTION_CLASS FALSE NUL QUERY_KEY
                                    SERIALISE_TABLE_KEY SERIALISE_TABLE_VIEW
                                    TRUE );
use HTML::StateTable::Types     qw( Object Str );
use HTML::StateTable::Util      qw( ensure_class_loaded throw );
use Unexpected::Functions       qw( UnknownView Unspecified );
use Try::Tiny;
use Moo;

=pod

=encoding utf-8

=head1 Name

HTML::StateTable::Manager - Table factory class

=head1 Synopsis

   use HTML::StateTable::Manager;

=head1 Description

A factory class for table objects

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item log

Optional logging object used to log errors

=item has_log

Predicate

=cut

has 'log' => is => 'ro', isa => Object, predicate => 'has_log';

=item meta_key

An immutable string which defaults to 'table_meta'. When set in the query
parameters it signifies a request for the defaults set in the column
definitions. Called just after the JS has deleted the preference record

=cut

has 'meta_key' => is => 'ro', isa => Str, default => 'table_meta';

=item namespace

An immutable required string. It is prepended to the supplied table name
to form a complete table class name

=cut

has 'namespace' => is => 'ro', isa => Str, required => TRUE;

=item page_manager

An optional immutable string. Name of the JS page management object

=item has_page_manager

Predicate

=cut

has 'page_manager' => is => 'ro', isa => Str, predicate => 'has_page_manager';

=item query_key

An immutable string which defaults to 'table_name'. When set in the query
parameters is signifies for which table this is a request. There might be
more than one table on a page

=cut

has 'query_key' => is => 'ro', isa => Str, default => QUERY_KEY;

=item renderer_class

An immutable string. The name of the non default renderer class

=item has_renderer_class

Predicate

=cut

has 'renderer_class' =>
   is        => 'ro',
   isa       => Str,
   predicate => 'has_renderer_class';

=item stash_key

An immutable string which defaults to '_serialise_table'. Parameters stored
in the stash under this key are used to configure the serialiser view

=cut

has 'stash_key' =>
   is      => 'ro',
   isa     => Str,
   default => SERIALISE_TABLE_KEY;

=item view_name

An immutable string which defaults to 'serialise_table'. Set this to the name
of the view within the application which will be responsible for serialising
the tables

=cut

has 'view_name' =>
   is      => 'ro',
   isa     => Str,
   default => SERIALISE_TABLE_VIEW;

=back

=head1 Subroutines/Methods

Defines the following methods;

=over 3

=item table( $name, \%options )

Returns a new table object. The C<namespace> attribute is prepended to the
C<name> provided and that table class is then loaded before creating
the new instance

=cut

sub table {
   my ($self, $name, $options) = @_;

   my $class = $self->_renderer_class($options->{context});

   $options->{download_view_name} = $self->view_name;
   $options->{filterable_view_name} = $self->view_name;
   $options->{log} = $self->log if $self->has_log;
   $options->{page_manager} = $self->page_manager if $self->has_page_manager;
   $options->{renderer_class} = $class if $class;
   $options->{renderer_args}->{query_key} = $self->query_key;

   my $table = $self->_get_table($name, $options);

   $self->_setup_view($table) if $self->_is_data_request($options->{context});

   return $table;
}

=item new_with_context( $name, \%options )

Proxy for C<table>

=cut

sub new_with_context {
   my ($self, $name, $options) = @_; return $self->table($name, $options);
}

# Private methods
sub _get_table {
   my ($self, $name, $options) = @_;

   my $class = $self->namespace . "::${name}";

   ensure_class_loaded $class;

   return $class->new($options);
}

sub _is_data_request {
   my ($self, $context) = @_;

   throw Unspecified, ['context'] unless $context;

   my $requested_with = $context->request->header('X-Requested-With')
      || $context->request->header('x-requested-with');

   return $requested_with && $requested_with eq 'XMLHttpRequest' ? TRUE : FALSE;
}

sub _renderer_class {
   my ($self, $context) = @_;

   if ($context) {
      my $params = $context->request->query_parameters;

      return $params->{renderer_class} if exists $params->{renderer_class};
   }

   return $self->renderer_class if $self->has_renderer_class;

   return;
}

sub _setup_view {
   my ($self, $table) = @_;

   my $context = $table->context;
   my $view    = $self->view_name;

   throw UnknownView, [$view] unless $context->view($view);

   my $params = $context->request->query_parameters;
   my $name   = $params->{$self->query_key} // NUL;
   my $key    = $self->stash_key;

   return unless !exists $context->stash->{$key} && $name eq $table->name;

   my $options = {
      format          => 'json',
      no_filename     => TRUE,
      serialiser_args => {
         disable_paging => FALSE,
         serialise_meta => $params->{$self->meta_key} ? TRUE : FALSE,
      },
      table           => $table,
   };

   $context->stash(view => $view, $key => $options);
   return;
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
