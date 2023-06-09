#!/bin/sh

# In helm chart we use postgresqlConfiguration instead

# Extension: pg_stat_statements
# https://github.com/docker-library/postgres/issues/177
echo "shared_preload_libraries = 'pg_stat_statements'" >> $PGDATA/postgresql.conf
echo "pg_stat_statements.max = 10000" >> $PGDATA/postgresql.conf
echo "pg_stat_statements.track = all" >> $PGDATA/postgresql.conf
