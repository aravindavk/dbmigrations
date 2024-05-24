import std.stdio;
import std.file;
import std.algorithm;
import std.algorithm.sorting : sort;
import std.array;
import std.path : baseName;
import std.conv;

const OUTPUT_FILE = "/tmp/dbmigration.sql";

struct MigrationFile
{
    string name;
    long timestamp;
}

MigrationFile tsFromFilename(string name)
{
    auto bn = baseName(name);
    auto parts = bn.split("-");

    MigrationFile f;
    f.name = bn;
    f.timestamp = parts[0].to!long;
    return f;
}

void showOutputFileHelp()
{
    writefln("Migration file generated. Path: %s", OUTPUT_FILE);
    writeln("Execute the SQL file to run migration (upgrade/downgrade). For example, Postgres");
    writeln;
    writefln("  sudo -u postgres psql mydb -f %s", OUTPUT_FILE);
}

void scaffold(string migrationsDir, string name)
{
    import std.datetime;
    import std.format;

    auto curTime = Clock.currTime;
    auto dt = cast(DateTime) curTime;
    auto fmtTime = format("%04d%02d%02d%02d%02d%02d", dt.year, dt.month,
            dt.day, dt.hour, dt.minute, dt.second);

    auto migrationFile = migrationsDir ~ "/" ~ fmtTime ~ "-" ~ name ~ ".sql";
    auto f = File(migrationFile, "w");
    f.writeln("-- +UP");
    f.writeln("-- SQL in section '+UP' is included when this migration is applied");
    f.writeln;
    f.writeln("-- +DOWN");
    f.writeln("-- SQL section '+DOWN' is included when this migration is rolled back");
    f.writeln;

    writefln("Created %s", migrationFile);
}

void showStatus(string migrationsDir, long ts)
{
    auto sqlFiles = dirEntries(migrationsDir, SpanMode.depth).filter!(
            f => f.name.endsWith(".sql")).array.sort;
    foreach (sqlFile; sqlFiles)
    {
        auto fileTs = tsFromFilename(sqlFile.name);
        string status = (ts == 0 || fileTs.timestamp > ts) ? "pending" : "done";
        writefln("%10s  %s", status, fileTs.name);
    }
}

void migrateUp(string migrationsDir, long ts)
{
    auto outFile = File(OUTPUT_FILE, "w");
    string[] includedFiles;

    auto sqlFiles = dirEntries(migrationsDir, SpanMode.depth).filter!(
            f => f.name.endsWith(".sql")).array.sort;
    foreach (sqlFile; sqlFiles)
    {
        auto fileTs = tsFromFilename(sqlFile.name);
        if (fileTs.timestamp <= ts && ts > 0L)
            continue;

        includedFiles ~= fileTs.name;

        outFile.writeln("-- " ~ sqlFile.name);
        auto f = File(sqlFile.name);
        foreach (l; f.byLine)
        {
            if (l.startsWith("-- +DOWN"))
                break;

            outFile.writeln(l);
        }
    }

    if (includedFiles.length > 0)
    {
        writeln("Included files:");
        writeln(includedFiles.join("\n"));
        writeln;
        showOutputFileHelp;
        return;
    }

    writeln("No migrations pending");
}

void migrateDown(string migrationsDir, long ts)
{
    auto outFile = File(OUTPUT_FILE, "w");
    string[] includedFiles;

    auto sqlFiles = dirEntries(migrationsDir, SpanMode.depth).filter!(f => f.name.endsWith(".sql"))
        .array
        .sort!("a > b");
    foreach (sqlFile; sqlFiles)
    {
        auto fileTs = tsFromFilename(sqlFile.name);
        if (fileTs.timestamp > ts || ts == 0L)
            continue;

        includedFiles ~= fileTs.name;
        outFile.writeln("-- " ~ sqlFile.name);
        auto f = File(sqlFile.name);
        bool downStarted = false;
        foreach (l; f.byLine)
        {
            if (l.startsWith("-- +DOWN"))
                downStarted = true;

            if (downStarted)
                outFile.writeln(l);
        }

        // Downgrade is one by one, so break!
        break;
    }

    if (includedFiles.length > 0)
    {
        writeln("Included files:");
        writeln(includedFiles.join("\n"));
        writeln;
        showOutputFileHelp;
        return;
    }

    writeln("No migrations pending");
}
