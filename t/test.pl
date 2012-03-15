use Mojolicious::Lite;

use DBIx::Custom;
use FindBin;
use lib "lib";

use Mojolicious::Plugin::SQLiteViewerLite;
my $dbi = DBIx::Custom->connect(
  dsn => 'dbi:SQLite:dbname=:memory:',
);

$dbi->execute('create table table1 (key1 integer primary key not null, key2 not null, key3)');

plugin 'SQLiteViewerLite', dbh => $dbi->dbh, prefix => 'sqliteviewer';

get '/' => {text => 'a'};

app->start;

