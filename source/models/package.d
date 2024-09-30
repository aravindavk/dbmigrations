module models;

import std.string;
import std.process;
import std.stdio;
import core.stdc.stdlib : exit;

public import models.helpers;
import models.pg;
import models.sqlite;

MigrationDriver migrationDriver;

static this()
{
    auto databaseUrl = environment.get("DATABASE_URL", "");

    if (databaseUrl.startsWith("postgres:"))
        migrationDriver = PostgresDriver.initialize(databaseUrl);
    else if (databaseUrl.startsWith("sqlite:"))
        migrationDriver = SqliteDriver.initialize(databaseUrl);
}
