use 5.001001;
package Mojolicious::Plugin::SQLiteViewerLite;
use Mojo::Base 'Mojolicious::Plugin::SQLiteViewerLite::Base';
use Mojolicious::Plugin::SQLiteViewerLite::Command;
use DBIx::Custom;
use Validator::Custom;
use File::Basename 'dirname';
use Cwd 'abs_path';

our $VERSION = '0.02';

has command => sub {
  my $self = shift;
  my $commond = Mojolicious::Plugin::SQLiteViewerLite::Command->new(dbi => $self->dbi);
};

sub register {
  my ($self, $app, $conf) = @_;
  my $dbh = $conf->{dbh};
  my $prefix = $conf->{prefix} // 'sqliteviewerlite';
  my $r = $conf->{route} // $app->routes;
  
  # Add template path
  $self->add_template_path($app->renderer, __PACKAGE__);
  
  # Set Attribute
  $self->dbi->dbh($dbh);
  $self->prefix($prefix);
  
  # Routes
  $r = $r->waypoint("/$prefix")->via('get')->to(
    'sqliteviewerlite#default',
    namespace => 'Mojolicious::Plugin::SQLiteViewerLite',
    plugin => $self,
    prefix => $self->prefix,
    main_title => 'SQLite Viewer Lite',
  );
  $r->get('/tables')->to(
    '#tables',
    utilities => [
      {path => 'showcreatetables', title => 'Show create tables'},
      {path => 'showprimarykeys', title => 'Show primary keys'},
      {path => 'shownullallowedcolumns', title => 'Show null allowed columns'},
    ]
  );
  $r->get('/table')->to('#table');
  $r->get('/showcreatetables')->to('#showcreatetables');
  $r->get('/showprimarykeys')->to('#showprimarykeys');
  $r->get('/shownullallowedcolumns')->to('#shownullallowedcolumns');
  $r->get('/showdatabaseengines')->to('#showdatabaseengines');
  $r->get('/showcharsets')->to('#showcharsets');
  $r->get('/select')->to('#select');
}

1;

=head1 NAME

Mojolicious::Plugin::SQLiteViewerLite - Mojolicious plugin to display SQLite database information on browser

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
to display SQLite database information on browser.

L<Mojolicious::Plugin::SQLiteViewerLite> have the following features.

=over 4

=item *

Display all table names

=item *

Display C<show create table>

=item *

Select * from TABLE limit 0, 1000

=item *

Display C<primary keys> and C<null allowed columnes> in all tables.

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
