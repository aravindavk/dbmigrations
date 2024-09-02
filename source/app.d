import std.stdio;
import std.getopt;
import std.string;

import commands;

int main(string[] args)
{
    auto commands = [
        "up": &commandUp,
        "down": &commandDown,
        "scaffold": &commandScaffold,
        "status": &commandStatus
    ];

    // dfmt off
    auto globalOpts = getopt(
        args,
        std.getopt.config.passThrough,
        "d|dir", "Migration files directory (Default: db/migrations)", &settings.migrationFilesDir,
        "debug", "Debug mode", &settings.debugEnabled
    );
    // dfmt on

    if (args.length < 2 || globalOpts.helpWanted)
    {
        commandHelp;
        return 1;
    }

    settings.migrationFilesDir = settings.migrationFilesDir.stripRight("/");

    import std.file;

    if (!settings.migrationFilesDir.exists)
    {
        stderr.writeln("Migration directory (" ~ settings.migrationFilesDir ~ ") doesn't exists");
        return 1;
    }

    auto func = (args[1] in commands);

    if (func is null)
    {
        writeln("Unknown sub-command");
        commandHelp;
        return 1;
    }
    return (*func)(args);
}
