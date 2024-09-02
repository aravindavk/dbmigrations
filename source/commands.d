import std.stdio;
import std.file;
import std.algorithm;
import std.algorithm.sorting : sort;
import std.array;
import std.path : baseName;
import std.conv;
import std.getopt;

import models;

// One place for all the settings
struct Settings
{
    string migrationFilesDir = "db/migrations";
    ulong currentLevel;
    string databaseUrl;
    bool debugEnabled;
    string scaffoldName;
}

Settings settings;

void commandHelp()
{
    string msg = q"[
        dbmigrations - Simple tool to manage database migrations

        USAGE
            $ dbmigrations COMMAND [OPTIONS]

        COMMANDS
            up       - Apply all available migrations
            down     - Roll back single migration from the current version
            status   - Status of applied and pending migrations
            scaffold - Create a empty migration file

        OPTIONS
            -d DIR, --dir=DIR  - Migration files directory

        EXAMPLES
            $ dbmigrations up
            OK  20240524135055-users
            OK  20240524135713-api-keys

            $ dbmigrations down
            OK  20240524135713-api-keys

            $ dbmigrations status
            Sep 02, 2024 06:09:50  20240524135055-users
                          pending  20240524135713-api-keys

            $ dbmigrations scaffold -n subscriptions
            Created ./db/migrations/20240902185129-subscriptions.sql
    ]";
    writeln(msg);
}

int commandUp(string[] args)
{
    auto latestMigration = migrationDriver.getLatestMigration();

    auto sqlFiles = dirEntries(settings.migrationFilesDir, SpanMode.depth).filter!(
            f => f.name.endsWith(".sql")).array.sort;

    int migrationsCount;
    foreach (sqlFile; sqlFiles)
    {
        auto fileTs = parseFilename(sqlFile.name);
        if (!latestMigration.isNull && fileTs.level <= latestMigration.get.level)
            continue;

        migrationsCount++;

        auto query = appender!string;
        auto f = File(sqlFile.name);
        foreach (l; f.byLine)
        {
            if (l.startsWith("-- +DOWN"))
                break;

            query.put(l ~ "\n");
        }
        if (query.capacity > 0)
            migrationDriver.execute(query.data);

        migrationDriver.addMigration(fileTs.level, fileTs.name);
        writefln("%6s  %s-%s", "OK", fileTs.level, fileTs.name);
    }

    if (migrationsCount == 0)
        writeln("No migrations pending");

    return 0;
}

MigrationRecord parseFilename(string name)
{
    import std.path : baseName;
    import std.conv;

    auto bn = baseName(name);
    auto parts = bn.split("-");

    MigrationRecord f;
    f.filename = bn;
    f.name = parts[1..$].join("-").replace(".sql", "");
    f.level = parts[0].to!long;
    f.createdAt = "pending";
    return f;
}

int commandStatus(string[] args)
{
    auto migrations = migrationDriver.listMigrations;
    auto sqlFiles = dirEntries(settings.migrationFilesDir, SpanMode.depth).filter!(
            f => f.name.endsWith(".sql")).array.sort;

    if (migrations.length > 0 || sqlFiles.length > 0)
        writefln("%21s  %s", "Applied At", "Migration");
    else
    {
        writeln("No migrations available");
        return 0;
    }
    foreach(m; migrations)
        writefln("%21s  %s-%s", m.createdAt, m.level, m.name);

    long lastTs = migrations.length > 0 ? migrations[$-1].level : 0;
    
    foreach (sqlFile; sqlFiles)
    {
        auto fileTs = parseFilename(sqlFile.name);
        if (fileTs.level > lastTs)
            writefln("%21s  %s-%s", fileTs.createdAt, fileTs.level, fileTs.name);
    }

    return 0;
}

void enforceMigration(bool condition, string error, int ret = 1)
{
    if (!condition)
    {
        import core.stdc.stdlib : exit;
        stderr.writeln(error);
        exit(ret);
    }
}

int commandDown(string[] args)
{
    auto latestMigration = migrationDriver.getLatestMigration();
    enforceMigration(!latestMigration.isNull, "No migration available for downgrade");

    string[] includedFiles;

    auto sqlFiles = dirEntries(settings.migrationFilesDir, SpanMode.depth).filter!(f => f.name.endsWith(".sql"))
        .array
        .sort!("a > b");

    auto sqlFileName = i"$(settings.migrationFilesDir)/$(latestMigration.get.level)-$(latestMigration.get.name).sql".text;
    auto fileTs = parseFilename(sqlFileName);

    auto query = appender!string;
    if (sqlFileName.exists)
    {
        auto f = File(sqlFileName);
        bool downStarted = false;
        foreach (l; f.byLine)
        {
            if (l.startsWith("-- +DOWN"))
                downStarted = true;

            if (downStarted)
                query.put(l ~ "\n");
        }
    }

    if (query.capacity > 0)
        migrationDriver.execute(query.data);

    migrationDriver.removeMigration(latestMigration.get.level);
    writefln("%6s  %s-%s", "OK", fileTs.level, fileTs.name);

    return 0;
}

int commandScaffold(string[] args)
{
    // dfmt off
    auto opts = getopt(
        args,
        std.getopt.config.required,
        "n|name", "Migration file name", &settings.scaffoldName
    );
    // dfmt on

    import std.datetime;
    import std.format;

    auto curTime = Clock.currTime;
    auto dt = cast(DateTime) curTime;
    auto fmtTime = format("%04d%02d%02d%02d%02d%02d", dt.year, dt.month,
            dt.day, dt.hour, dt.minute, dt.second);

    auto migrationFile = settings.migrationFilesDir ~ "/" ~ fmtTime ~ "-" ~ settings.scaffoldName ~ ".sql";
    auto f = File(migrationFile, "w");
    f.writeln("-- +UP");
    f.writeln;
    f.writeln("-- +DOWN");
    f.writeln;

    writefln("Created %s", migrationFile);
    return 0;
}
