package Mojolicious::Plugin::SQLiteViewerLite::Sqliteviewerlite;
use Mojo::Base 'Mojolicious::Controller';

sub default {
  my $self = shift;
  
  my $command = $self->stash->{command};
  my $database = $command->show_databases;
  my $current_database = $command->current_database;
  
  $self->render(
    databases => $database,
    current_database => $current_database
  );
}

1;
