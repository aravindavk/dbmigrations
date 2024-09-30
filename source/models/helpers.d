module models.helpers;

import std.typecons;

struct MigrationRecord
{
    string name;
    long level;
    string createdAt;
    string filename;
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
