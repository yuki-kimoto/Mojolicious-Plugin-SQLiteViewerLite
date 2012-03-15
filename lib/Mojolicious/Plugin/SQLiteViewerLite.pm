use 5.001001;
package Mojolicious::Plugin::SQLiteViewerLite;
use Mojo::Base 'Mojolicious::Plugin';
use DBIx::Custom;
use Validator::Custom;
use File::Basename 'dirname';
use Cwd 'abs_path';
use Mojolicious::Plugin::SQLiteViewerLite::Command;

our $VERSION = '0.06';

has 'prefix';
has validator => sub {
  my $validator = Validator::Custom->new;
  $validator->register_constraint(
    safety_name => sub {
      my $name = shift;
      return ($name || '') =~ /^\w+$/ ? 1 : 0;
    }
  );
  return $validator;
};

has dbi => sub { DBIx::Custom->new };

has command => sub {
  my $self = shift;
  my $commond = Mojolicious::Plugin::SQLiteViewerLite::Command->new(dbi => $self->dbi);
};

# Viewer
sub register {
  my ($self, $app, $conf) = @_;
  my $dbh = $conf->{dbh};
  my $prefix = $conf->{prefix} // 'sqliteviewerlite';
  my $r = $conf->{route} // $app->routes;
  
  # Add Renderer path
  $self->add_renderer_path($app->renderer);
  
  # Set Attribute
  $self->dbi->dbh($dbh);
  $self->prefix($prefix);
  
  $r = $self->create_routes($r);
}

sub add_renderer_path {
  my ($self, $renderer) = @_;
  my $class = __PACKAGE__;
  $class =~ s/::/\//g;
  $class .= '.pm';
  my $public = abs_path dirname $INC{$class};
  push @{$renderer->paths}, "$public/SQLiteViewerLite/templates";
}

sub create_routes {
  my ($self, $r) = @_;
  
  my $prefix = $self->prefix;

  # Top page
  my %args = (
    namespace => 'Mojolicious::Plugin::SQLiteViewerLite',
    controller => 'sqliteviewerlite',
    plugin => $self
  );
  
  # Routes
  $r = $r->waypoint("/$prefix")->via('get')->to(%args, action => 'default');
  $r->get('/tables')->to(%args, action => 'tables');
  $r->get('/table')->to(%args, action => 'table');
  $r->get('/showcreatetables')->to(%args, action => 'showcreatetables');
  $r->get('/showprimarykeys')->to(%args, action => 'showprimarykeys');
  $r->get('/shownullallowedcolumns')->to(%args, action => 'shownullallowedcolumns');
  $r->get('/showdatabaseengines')->to(%args, action => 'showdatabaseengines');
  $r->get('/showcharsets')->to(%args, action => 'showcharsets');
  $r->get('/select')->to(%args, action => 'select');

  return $r;
}

1;

=head1 NAME

Mojolicious::Plugin::SQLiteViewerLite - Mojolicious plugin to display mysql database information

=head1 SYNOPSYS

  # Mojolicious::Lite
  plugin 'SQLiteViewerLite', dbh => $dbh;

  # Mojolicious
  $app->plugin('SQLiteViewerLite', dbh => $dbh);

  # Access
  http://localhost:3000/sqliteviewerlite
  
  # Prefix
  plugin 'SQLiteViewerLite', dbh => $dbh, prefix => 'sqliteviewerlite2';

=head1 DESCRIPTION

L<Mojolicious::Plugin::SQLiteViewerLite> is L<Mojolicious> plugin
to display MySQL database information on your browser.

L<Mojolicious::Plugin::SQLiteViewerLite> have the following features.

=over 4

=item *

Display all table names

=item *

Display C<show create table>

=item *

Select * from TABLE limit 0, 1000

=item *

Display C<primary keys>, C<null allowed columnes>, C<database engines> and C<charsets> in all tables.

=back

=head1 OPTIONS

=head2 C<dbh>

  dbh => $dbh

Database handle object in L<DBI>.

=head2 C<prefix>

  prefix => 'sqliteviewerlite2'

Application base path, default to C<sqliteviewerlite>.

=head2 C<route>

    route => $route

Router, default to C<$app->routes>.

It is useful when C<under> is used.

  my $b = $r->under(sub { ... });
  plugin 'SQLiteViewerLite', dbh => $dbh, route => $b;

=cut
