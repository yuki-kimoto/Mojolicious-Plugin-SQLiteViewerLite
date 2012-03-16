use Mojolicious::Lite;

use DBIx::Custom;
use FindBin;
use lib "lib";

use Mojolicious::Plugin::SQLiteViewerLite;
my $dbi = DBIx::Custom->connect(
  dsn => 'dbi:SQLite:dbname=test.db',
  connector => 1
);
eval {
  $dbi->execute('create table table1 (key1 integer primary key not null, key2 not null, key3)');
  $dbi->insert({key1 => $_, key2 => $_ + 1, key3 => $_ + 2}, table => 'table1') for (1 .. 1000);
};

warn $dbi->connector;

plugin 'SQLiteViewerLite', connector => $dbi->connector, prefix => 'sqliteviewer';

get '/' => {text => 'a'};

app->start;

