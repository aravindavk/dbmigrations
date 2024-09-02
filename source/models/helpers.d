module models.helpers;

import std.typecons;

struct MigrationRecord
{
    string name;
    string filename;
    long level;
    string createdAt;
}

interface MigrationDriver
{
    static MigrationDriver initialize(string databaseUrl);
    void addMigration(long level, string name);
    void removeMigration(long level);
    Nullable!MigrationRecord getLatestMigration();
    MigrationRecord[] listMigrations();
    void execute(string query);
}
