# Database migration tool

Generic db migration tool to generate the Upgrade sql statements or downgrade sql statements based on the given timestamp. This tool is not specific to any Database or doesn't maintain the version information.

Create the migrations directory in your project directory. For example,

```
cd myproject
mkdir -p db/migrations
```

Now create the migration file by running the below command.

```console
$ /usr/bin/dbmigrations -d ./db/migrations scaffold -n users
Created ./db/migrations/20240524213223-users.sql
```

Open the file and add the SQL for upgrade under `-- +UP` and downgrade SQL under `-- +DOWN` section. Example,

```sql
-- +UP
-- SQL in section '+UP' is included when this migration is applied
CREATE TABLE users(
  id                         BIGSERIAL PRIMARY KEY,
  name                       VARCHAR NOT NULL,
  email                      VARCHAR NOT NULL,
  password_hash              VARCHAR NOT NULL,
  created_at                 TIMESTAMP,
  updated_at                 TIMESTAMP
);

-- +DOWN
-- SQL section '+DOWN' is included when this migration is rolled back
DROP TABLE users;
```

## Upgrade

Run `dbmigrations up` to generate the migration file based on given timestamp.

```console
$ /usr/bin/dbmigrations -d ./db/migrations up
Included files:
20240524135055-users.sql

Migration file generated. Path: /tmp/dbmigration.sql
Execute the SQL file to run migration (upgrade/downgrade). For example, Postgres

  sudo -u postgres psql mydb -f /tmp/dbmigration.sql
```

To generate the migration file based on the given timestamp.

```
$ /usr/bin/dbmigrations -d ./db/migrations up -t 20240524135847
```

## Status

```console
$ /usr/bin/dbmigrations -d ./db/migrations status
   pending  20240524135055-users.sql
```

```console
$ /usr/bin/dbmigrations -d ./db/migrations status -t 20240524135055
      done  20240524135055-users.sql
```

## Downgrade(one by one)

Generates the migration file based on the given timestamp. Rollback only the last migration after the given timestamp.

```console
$ /usr/bin/dbmigrations -d ./db/migrations down -t 20240524135055
Included files:
20240524135055-users.sql

Migration file generated. Path: /tmp/dbmigration.sql
Execute the SQL file to run migration (upgrade/downgrade). For example, Postgres

  sudo -u postgres psql mydb -f /tmp/dbmigration.sql
```

To generate the migration file based on the given timestamp.
```

## Contributing

- Fork it (https://github.com/aravindavk/dbmigrations/fork)
- Create your feature branch (git checkout -b my-new-feature)
- Commit your changes (git commit -asm 'Add some feature')
- Push to the branch (git push origin my-new-feature)
- Create a new Pull Request

## Contributors

- Aravinda VK - Creator and Maintainer
