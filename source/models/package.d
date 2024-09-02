module models;

import std.string;
import std.process;
import std.stdio;
import core.stdc.stdlib : exit;

public import models.helpers;
import models.pg;

MigrationDriver migrationDriver;

static this()
{
    auto databaseUrl = environment.get("DATABASE_URL", "");
    if (databaseUrl.empty)
    {
        stderr.writeln("DATABASE_URL environment variable is not set");
        exit(1);
    }

    if (databaseUrl.startsWith("postgres:"))
        migrationDriver = PostgresDriver.initialize(databaseUrl);
}
