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
  $r = $r->waypoint("/$prefix")->via('get')->to(cb => sub { $self->action_index(shift) });
  # Tables
  $r->get('/tables' => sub { $self->action_tables(shift) });
  # Table
  $r->get('/table' => sub { $self->action_table(shift) });

  # Show create tables
  $r->get('/showcreatetables' => sub { $self->action_showcreatetables(shift) });
  # Show primary keys
  $r->get('/showprimarykeys', sub { $self->action_showprimarykeys(shift) });
  # Show null allowed columns
  $r->get('/shownullallowedcolumns', sub { $self->action_shownullallowedcolumns(shift) });
  # Show database engines
  $r->get('/showdatabaseengines', sub { $self->action_showdatabaseengines(shift) });
  # Show charsets
  $r->get('/showcharsets', sub { $self->action_showcharsets(shift) });
  
  # Select
  $r->get('/select', sub { $self->action_select(shift) });

  return $r;
}

sub action_index {
  my ($self, $c) = @_;
  
  my $database = $self->command->show_databases;
  my $current_database = $self->command->current_database;
  
  $DB::single = 1;
  $c->render(
    controller => 'sqliteviewerlite',
    action => 'index',
    prefix => $self->prefix,
    databases => $database,
    current_database => $current_database
  );
}

sub action_tables {
  my ($self, $c) = @_;
  
  my $params = $self->params($c);
  my $rule = [
    database => {default => ''} => [
      'safety_name'
    ] 
  ];
  my $vresult = $self->validator->validate($params, $rule);
  my $database = $vresult->data->{database};
  my $tables = $self->command->show_tables($database);
  
  return $c->render(
    controller => 'sqliteviewerlite',
    action => 'tables',
    prefix => $self->prefix,
    database => $database,
    tables => $tables
  );
}

sub action_table {
  my ($self, $c) = @_;
  
  # Validation
  my $params = $self->params($c);
  my $rule = [
    database => {default => ''} => [
      'safety_name'
    ],
    table => {default => ''} => [
      'safety_name'
    ]
  ];
  my $vresult = $self->validator->validate($params, $rule);
  my $database = $vresult->data->{database};
  my $table = $vresult->data->{table};
  
  my $table_def = $self->command->show_create_table($database, $table);
  return $c->render(
    controller => 'sqliteviewerlite',
    action => 'table',
    prefix => $self->prefix,
    database => $database,
    table => $table, 
    table_def => $table_def,
  );
}

sub action_showcreatetables {
  my ($self, $c) = @_;
  
  # Validation
  my $params = $self->params($c);
  my $rule = [
    database => {default => ''} => [
      'safety_name'
    ]
  ];
  my $vresult = $self->validator->validate($params, $rule);
  my $database = $vresult->data->{database};
  my $tables = $self->command->show_tables($database);
  
  # Get create tables
  my $create_tables = {};
  for my $table (@$tables) {
    $create_tables->{$table} = $self->command->show_create_table($database, $table);
  }
  
  return $c->render(
    controller => 'sqliteviewerlite',
    action => 'showcreatetables',
    prefix => $self->prefix,
    database => $database,
    create_tables => $create_tables
  );
}

sub action_showprimarykeys {
  my ($self, $c) = @_;
  
  # Validation
  my $params = $self->params($c);
  my $rule = [
    database => {default => ''} => [
      'safety_name'
    ],
  ];
  my $vresult = $self->validator->validate($params, $rule);
  my $database = $vresult->data->{database};
  
  # Get primary keys
  my $primary_keys = $self->command->show_primary_keys($database);
  
  $c->render(
    controller => 'sqliteviewerlite',
    action => 'showprimarykeys',
    prefix => $self->prefix,
    database => $database,
    primary_keys => $primary_keys
  );
}

sub action_shownullallowedcolumns {
  my ($self, $c) = @_;
  
  # Validation
  my $params = $self->params($c);
  my $rule = [
    database => {default => ''} => [
      'safety_name'
    ],
  ];
  my $vresult = $self->validator->validate($params, $rule);
  my $database = $vresult->data->{database};
  
  # Get null allowed columns
  my $null_allowed_columns = $self->command->show_null_allowed_columns($database);
  
  $c->render(
    controller => 'sqliteviewerlite',
    action => 'shownullallowedcolumns',
    prefix => $self->prefix,
    database => $database,
    null_allowed_columns => $null_allowed_columns
  );
}

sub action_select {
  my ($self, $c) = @_;
  
  # Validation
  my $params = $self->params($c);
  my $rule = [
    database => {default => ''} => [
      'safety_name'
    ],
    table => {default => ''} => [
      'safety_name'
    ]
  ];
  my $vresult = $self->validator->validate($params, $rule);
  my $database = $vresult->data->{database};
  my $table = $vresult->data->{table};
  
  # Get null allowed columns
  my $result = $self->dbi->select(table => "$database.$table", append => 'limit 0, 1000');
  my $header = $result->header;
  my $rows = $result->fetch_all;
  my $sql = $self->dbi->last_sql;
  
  $c->render(
    controller => 'sqliteviewerlite',
    action => 'select',
    prefix => $self->prefix,
    database => $database,
    table => $table,
    header => $header,
    rows => $rows,
    sql => $sql
  );
}

sub params {
  my ($self, $c) = @_;
  my $params = {map {$_ => $c->param($_)} $c->param};
  return $params;
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
