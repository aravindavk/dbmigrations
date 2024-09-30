module models.sqlite;

import std.string : replace, split;
import std.typecons;

import d2sqlite3;

import models.helpers;


class SqliteDriver : MigrationDriver
{
    Database conn;
    string databaseUrl;

    private ResultRange execute_(Targs...)(string query, Targs args)
    {
        Statement statement = conn.prepare(query);
        statement.bindAll(args);
        return statement.execute;
    }

    void execute(string query)
    {
        foreach(q; query.split(";"))
            conn.execute(q);
    }

    static MigrationDriver initialize(string databaseUrl)
    {
        auto driver = new SqliteDriver;

        databaseUrl = databaseUrl.replace("sqlite:///", "");
        driver.databaseUrl = databaseUrl;
        driver.conn = Database(databaseUrl);

        auto query = q{
            CREATE TABLE IF NOT EXISTS schema_migration (
                id            INTEGER PRIMARY KEY,
                level         INTEGER NOT NULL,
                name          VARCHAR NOT NULL,
                createdAt     DATETIME DEFAULT current_timestamp
            )
        };
        driver.execute_(query);
        return driver;
    }

    void addMigration(long level, string name)
    {
        auto query = q{
            INSERT INTO schema_migration (level, name)
            VALUES (:level, :name)
        };
        execute_(query, level, name);
    }

    Nullable!MigrationRecord getLatestMigration()
    {
        Nullable!MigrationRecord migration; 
        auto query = q"[
            SELECT name,
                   level,
                   (substr('JanFebMarAprMayJunJulAugSepOctNovDec', 1 + 3 * strftime('%m', createdAt), -3) || STRFTIME(' %d, %Y %H:%M:%S', createdAt)) AS createdAt
            FROM schema_migration
            ORDER BY level DESC
            LIMIT 1
        ]";
        auto rs = execute_(query);
        foreach (Row row; rs)
        {
            MigrationRecord m;
            m.name = row["name"].as!string;
            m.level = row["level"].as!long;
            m.createdAt = row["createdAt"].as!string;
            migration = m;
        }

        return migration;
    }

    MigrationRecord[] listMigrations()
    {
        MigrationRecord[] migrations;
        auto query = q"[
            SELECT name,
                   level,
                   (substr('JanFebMarAprMayJunJulAugSepOctNovDec', 1 + 3 * strftime('%m', createdAt), -3) || STRFTIME(' %d, %Y %H:%M:%S', createdAt)) AS createdAt
            FROM schema_migration
        ]";

        auto rs = execute_(query);
        foreach (Row row; rs)
        {
            MigrationRecord m;
            m.name = row["name"].as!string;
            m.level = row["level"].as!long;
            m.createdAt = row["createdAt"].as!string;

            migrations ~= m;
        }

        return migrations;
    }

    void removeMigration(long level)
    {
        auto query = q{
            DELETE
            FROM schema_migration
            WHERE level = :level
        };
        execute_(query, level);
    }
}
