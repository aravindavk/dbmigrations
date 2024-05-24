import std.stdio;
import std.getopt;
import std.process;
import std.string;

import commands;

string migrationsDir = "./db/migrations";
long timestamp;
string scaffoldName;

int main(string[] args)
{
    // dfmt off
    auto opts = getopt(
        args,
        //config.passThrough,
        "d|dir", "Migration files directory", &migrationsDir,
        "t|timestamp", "Timestamp of current migration", &timestamp,
        "n|name", "Migration file to create (scaffold)", &scaffoldName
    );
    // dfmt on

    if (opts.helpWanted || args.length == 1)
    {
        defaultGetoptPrinter("Db migration tool", opts.options);
        return 0;
    }

    migrationsDir = migrationsDir.stripRight("/");

    switch (args[1])
    {
    case "up":
        migrateUp(migrationsDir, timestamp);
        break;
    case "down":
        migrateDown(migrationsDir, timestamp);
        break;
    case "status":
        showStatus(migrationsDir, timestamp);
        break;
    case "scaffold":
        import std.range;

        if (scaffoldName.empty)
        {
            stderr.writeln("Scaffold name is empty");
            return 1;
        }
        scaffold(migrationsDir, scaffoldName);
        break;
    default:
        stderr.writeln("Unknown sub-command \"" ~ args[1] ~ "\"");
        return 1;
    }

    // Deploy versions table if not exists

    return 0;
}
