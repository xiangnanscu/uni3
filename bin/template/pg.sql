GRANT CREATE ON SCHEMA public TO PUBLIC;

CREATE USER test WITH PASSWORD 'test';

CREATE DATABASE test;

CREATE USER $ {PGUSER} WITH PASSWORD '${PGPASSWORD}';

CREATE DATABASE $ {PGDATABASE};

