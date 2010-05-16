#!perl

use strict;
use warnings;

use lib 't/no-component-lib';
use DBICDHTest;
use DBIx::Class::DeploymentHandler;
use aliased 'DBIx::Class::DeploymentHandler', 'DH';

use File::Path 'remove_tree';
use Test::More;
use Test::Exception;

DBICDHTest::ready;

my $db = 'dbi:SQLite:db.db';
my @connection = ($db, '', '', { ignore_version => 1 });
my $sql_dir = 't/sql';

VERSION1: {
  use_ok 'DBICVersion_v1';
  my $s = DBICVersion::Schema->connect(@connection);
  $DBICVersion::Schema::VERSION = 1;
  ok($s, 'DBICVersion::Schema 1 instantiates correctly');
  my $handler = DH->new({
    upgrade_directory => $sql_dir,
    schema => $s,
    databases => 'SQLite',
    sql_translator_args => { add_drop_table => 0 },
  });

  ok($handler, 'DBIx::Class::DeploymentHandler w/1 instantiates correctly');

  my $version = $s->schema_version;
  $handler->prepare_deploy;

  dies_ok {
    $s->resultset('Foo')->create({
      bar => 'frew',
    })
  } 'schema not deployed';
  $handler->install;
  dies_ok {
    $handler->install;
  } 'cannot install twice';
  lives_ok {
    $s->resultset('Foo')->create({
      bar => 'frew',
    })
  } 'schema is deployed';
}

VERSION2: {
  use_ok 'DBICVersion_v2';
  my $s = DBICVersion::Schema->connect(@connection);
  $DBICVersion::Schema::VERSION = 2;
  ok($s, 'DBICVersion::Schema 2 instantiates correctly');
  my $handler = DH->new({
    upgrade_directory => $sql_dir,
    schema => $s,
    databases => 'SQLite',
  });

  ok($handler, 'DBIx::Class::DeploymentHandler w/2 instantiates correctly');

  my $version = $s->schema_version();
  $handler->prepare_deploy();
  $handler->prepare_upgrade(1, $version);
  dies_ok {
    $s->resultset('Foo')->create({
      bar => 'frew',
      baz => 'frew',
    })
  } 'schema not deployed';
  dies_ok {
    $s->resultset('Foo')->create({
      bar => 'frew',
      baz => 'frew',
    })
  } 'schema not uppgrayyed';
  $handler->upgrade;
  lives_ok {
    $s->resultset('Foo')->create({
      bar => 'frew',
      baz => 'frew',
    })
  } 'schema is deployed';
}

VERSION3: {
  use_ok 'DBICVersion_v3';
  my $s = DBICVersion::Schema->connect(@connection);
  $DBICVersion::Schema::VERSION = 3;
  ok($s, 'DBICVersion::Schema 3 instantiates correctly');
  my $handler = DH->new({
    upgrade_directory => $sql_dir,
    schema => $s,
    databases => 'SQLite',
  });

  ok($handler, 'DBIx::Class::DeploymentHandler w/3 instantiates correctly');

  my $version = $s->schema_version();
  $handler->prepare_deploy;
  $handler->prepare_upgrade( 2, $version );
  dies_ok {
    $s->resultset('Foo')->create({
        bar => 'frew',
        baz => 'frew',
        biff => 'frew',
      })
  } 'schema not deployed';
  $handler->upgrade;
  lives_ok {
    $s->resultset('Foo')->create({
      bar => 'frew',
      baz => 'frew',
      biff => 'frew',
    })
  } 'schema is deployed';
}

DOWN2: {
  use_ok 'DBICVersion_v4';
  my $s = DBICVersion::Schema->connect(@connection);
  $DBICVersion::Schema::VERSION = 2;
  ok($s, 'DBICVersion::Schema 2 instantiates correctly');
  my $handler = DH->new({
    upgrade_directory => $sql_dir,
    schema => $s,
    databases => 'SQLite',
  });

  ok($handler, 'DBIx::Class::DeploymentHandler w/2 instantiates correctly');

  my $version = $s->schema_version();
  $handler->prepare_downgrade(3, $version);
  lives_ok {
    $s->resultset('Foo')->create({
      bar => 'frew',
      baz => 'frew',
      biff => 'frew',
    })
  } 'schema at version 3';
  $handler->downgrade;
  dies_ok {
    $s->resultset('Foo')->create({
      bar => 'frew',
      baz => 'frew',
      biff => 'frew',
    })
  } 'schema not at version 3';
  lives_ok {
    $s->resultset('Foo')->create({
      bar => 'frew',
      baz => 'frew',
    })
  } 'schema is at version 2';
}

done_testing;