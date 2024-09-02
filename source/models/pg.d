module models.pg;

import std.typecons;

import dpq2;

import models.helpers;

class PostgresDriver : MigrationDriver
{
    Connection conn;
    string databaseUrl;

    private Answer execute_(Targs...)(string query, Targs args)
    {
        if (!conn)
            conn = new Connection(databaseUrl);

        QueryParams qps;
        qps.sqlCommand = query;
        qps.argsVariadic(args);
        return conn.execParams(qps);
    }

    void execute(string query)
    {
        import std.stdio;
        conn.exec(query);
    }
    
    static MigrationDriver initialize(string databaseUrl)
    {
        auto driver = new PostgresDriver;

        driver.databaseUrl = databaseUrl;
        driver.conn = new Connection(databaseUrl);

        string query = q"[
            SELECT *
            FROM information_schema.tables 
            WHERE table_schema LIKE 'public' AND 
                  table_type LIKE 'BASE TABLE' AND
                  table_name = $1
        ]";

        auto rs = driver.execute_(query, "schema_migration");
        if (rs.length > 0)
            return driver;

        query = q{
            CREATE TABLE schema_migration (
                id            SERIAL PRIMARY KEY,
                level         BIGINT NOT NULL,
                name          VARCHAR NOT NULL,
                createdAt     TIMESTAMP DEFAULT current_timestamp
            )
        };
        driver.execute_(query);
        return driver;
    }

    void addMigration(long level, string name)
    {
        auto query = q{
            INSERT INTO schema_migration (level, name)
            VALUES (                      $1,    $2)
        };
        execute_(query, level, name);
    }

    Nullable!MigrationRecord getLatestMigration()
    {
        Nullable!MigrationRecord migration; 
        auto query = q"[
            SELECT level,
                   name,
                   TO_CHAR(createdAt, 'Mon DD, YYYY HH:MM:SS') AS createdAt
            FROM schema_migration
            ORDER BY level DESC
            LIMIT 1
        ]";
        auto rs = execute_(query);
        if (rs.length > 0)
        {
            MigrationRecord m;
            m.name = rs[0]["name"].as!PGtext;
            m.level = rs[0]["level"].as!PGbigint;
            m.createdAt = rs[0]["createdAt"].as!PGtext;
            migration = m;
        }

        return migration;
    }

    MigrationRecord[] listMigrations()
    {
        MigrationRecord[] migrations;
        auto query = q"[
            SELECT level,
                   name,
                   TO_CHAR(createdAt, 'Mon DD, YYYY HH:MM:SS') AS createdAt
            FROM schema_migration
        ]";

        auto rs = execute_(query);
        foreach(idx; 0..rs.length)
        {
            MigrationRecord m;
            m.name = rs[idx]["name"].as!PGtext;
            m.level = rs[idx]["level"].as!PGbigint;
            m.createdAt = rs[idx]["createdAt"].as!PGtext;
            migrations ~= m;
        }

        return migrations;
    }

    void removeMigration(long level)
    {
        auto query = q{
            DELETE
            FROM schema_migration
            WHERE level = $1
        };
        execute_(query, level);
    }
}
