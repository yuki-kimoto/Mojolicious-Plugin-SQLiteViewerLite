package Mojolicious::Plugin::SQLiteViewerLite::Controller;
use Mojo::Base 'Mojolicious::Controller';

sub default {
  my $self = shift;
  
  my $plugin = $self->stash->{plugin};
  my $command = $plugin->command;
  
  my $database = $command->show_databases;
  my $current_database = $command->current_database;
  
  $self->stash->{template} = 'sqliteviewerlite/default'
    unless $self->stash->{template};

  $self->render(
    databases => $database,
    current_database => $current_database,
    prefix => $plugin->prefix
  );
}

sub tables {
  my $self = shift;;
  
  my $plugin = $self->stash->{plugin};
  my $command = $plugin->command;

  my $params = $command->params($self);
  my $rule = [
    database => {default => ''} => [
      'safety_name'
    ] 
  ];
  my $vresult = $plugin->validator->validate($params, $rule);
  my $database = $vresult->data->{database};
  my $tables = $command->show_tables($database);
  
  $self->stash->{template} = 'sqliteviewerlite/tables'
    unless $self->stash->{template};

  return $self->render(
    controller => 'sqliteviewerlite',
    prefix => $plugin->prefix,
    database => $database,
    tables => $tables
  );
}

sub table {
  my $self = shift;;
  
  my $plugin = $self->stash->{plugin};
  my $command = $plugin->command;

  # Validation
  my $params = $command->params($self);
  my $rule = [
    database => {default => ''} => [
      'safety_name'
    ],
    table => {default => ''} => [
      'safety_name'
    ]
  ];
  my $vresult = $plugin->validator->validate($params, $rule);
  my $database = $vresult->data->{database};
  my $table = $vresult->data->{table};
  
  my $table_def = $command->show_create_table($database, $table);

  $self->stash->{template} = 'sqliteviewerlite/table'
    unless $self->stash->{template};

  return $self->render(
    controller => 'sqliteviewerlite',
    prefix => $plugin->prefix,
    database => $database,
    table => $table, 
    table_def => $table_def,
  );
}

sub showcreatetables {
  my $self = shift;;
  
  my $plugin = $self->stash->{plugin};
  my $command = $plugin->command;

  # Validation
  my $params = $command->params($self);
  my $rule = [
    database => {default => ''} => [
      'safety_name'
    ]
  ];
  my $vresult = $plugin->validator->validate($params, $rule);
  my $database = $vresult->data->{database};
  my $tables = $command->show_tables($database);
  
  # Get create tables
  my $create_tables = {};
  for my $table (@$tables) {
    $create_tables->{$table} = $plugin->command->show_create_table($database, $table);
  }
  
  $self->stash->{template} = 'sqliteviewerlite/showcreatetables'
    unless $self->stash->{template};

  $self->render(
    controller => 'sqliteviewerlite',
    prefix => $plugin->prefix,
    database => $database,
    create_tables => $create_tables
  );
}

sub showprimarykeys {
  my $self = shift;;
  
  my $plugin = $self->stash->{plugin};
  my $command = $plugin->command;

  # Validation
  my $params = $command->params($self);
  my $rule = [
    database => {default => ''} => [
      'safety_name'
    ],
  ];
  my $vresult = $plugin->validator->validate($params, $rule);
  my $database = $vresult->data->{database};
  
  # Get primary keys
  my $primary_keys = $command->show_primary_keys($database);
  
  $self->stash->{template} = 'sqliteviewerlite/showprimarykeys'
    unless $self->stash->{template};

  $self->render(
    controller => 'sqliteviewerlite',
    prefix => $plugin->prefix,
    database => $database,
    primary_keys => $primary_keys
  );
}

sub shownullallowedcolumns {
  my $self = shift;;
  
  my $plugin = $self->stash->{plugin};
  my $command = $plugin->command;

  # Validation
  my $params = $command->params($self);
  my $rule = [
    database => {default => ''} => [
      'safety_name'
    ],
  ];
  my $vresult = $plugin->validator->validate($params, $rule);
  my $database = $vresult->data->{database};
  
  # Get null allowed columns
  my $null_allowed_columns = $command->show_null_allowed_columns($database);
  
  $self->stash->{template} = 'sqliteviewerlite/shownullallowedcolumns'
    unless $self->stash->{template};

  $self->render(
    controller => 'sqliteviewerlite',
    prefix => $plugin->prefix,
    database => $database,
    null_allowed_columns => $null_allowed_columns
  );
}

sub select {
  my $self = shift;;
  
  my $plugin = $self->stash->{plugin};
  my $command = $plugin->command;

  # Validation
  my $params = $command->params($self);
  my $rule = [
    database => {default => ''} => [
      'safety_name'
    ],
    table => {default => ''} => [
      'safety_name'
    ]
  ];
  my $vresult = $plugin->validator->validate($params, $rule);
  my $database = $vresult->data->{database};
  my $table = $vresult->data->{table};
  
  # Get null allowed columns
  my $result = $plugin->dbi->select(table => "$database.$table", append => 'limit 0, 1000');
  my $header = $result->header;
  my $rows = $result->fetch_all;
  my $sql = $plugin->dbi->last_sql;
  
  $self->stash->{template} = 'sqliteviewerlite/select'
    unless $self->stash->{template};

  $self->render(
    controller => 'sqliteviewerlite',
    prefix => $plugin->prefix,
    database => $database,
    table => $table,
    header => $header,
    rows => $rows,
    sql => $sql
  );
}

1;
