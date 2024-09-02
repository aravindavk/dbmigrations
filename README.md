# Database migration tool

Database migration tool to apply all available migrations from `db/migrations` (customizable) directory. It is inspired by [micrate](https://github.com/amberframework/micrate).

## Usage
Create the migrations directory in your project directory. For example,

```
cd myproject
mkdir -p db/migrations
```

Export the DATABASE_URL. For example,

```
export DATABASE_URL=postgres://postgres:secret@localhost:5432/myapp_dev
```

### Scaffold

Now create the migration file by running the below command.

```console
$ dub run dbmigrations@0.2.0 scaffold -n users
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

### Upgrade

Run `dbmigrations up` to apply all the available migrations.

```console
$ dub run dbmigrations@0.2.0 up
OK  20240524135055-users
OK  20240524135713-api-keys
```

### Status

Check the status of the migrations by running

```console
$ dub run dbmigrations@0.2.0 status
Sep 02, 2024 06:09:50  20240524135055-users
              pending  20240524135713-api-keys
```

### Downgrade(one by one)

```console
$ dub run dbmigrations@0.2.0 down
OK  20240524135713-api-keys
```

## TODO:

- Only Postgres is supported now, add support for MySQL and Sqlite

## Contributing

- Fork it (https://github.com/aravindavk/dbmigrations/fork)
- Create your feature branch (git checkout -b my-new-feature)
- Commit your changes (git commit -asm 'Add some feature')
- Push to the branch (git push origin my-new-feature)
- Create a new Pull Request

## Contributors

- Aravinda VK - Creator and Maintainer
