#!/bin/bash
# This script is deleting all databases which starts with "opennms_test_"

export "PGPASSWORD=postgres"

PSQL_EXECUTABLE=/Applications/Postgres.app/Contents/Versions/9.5/bin/psql
deleteFile='/tmp/delete.sql'
datnameLike='opennms_test_%'
query="select 'drop database '||datname||';' from pg_database where datname like '$datnameLike'"

#select '"'drop database '||datname||';' from pg_database where datistemplate=false and datname like '"$datnameLike';'"
#echo $query
echo "Use query: $query"
$PSQL_EXECUTABLE -t -d postgres -U postgres -c "${query}" > $deleteFile 2>/dev/null
if [ $? -ne 0 ]; then
    echo "Could not create $deleteFile"
    exit 1;
fi
echo "SQL file containing all drop commands are created at $deleteFile."
echo "If you continue all statements in $deleteFile will be executed and those databases are beeing dropped"
read -p "PRESS [ENTER] to drop ALL databases ..."

echo "Dropping all databases..."
$PSQL_EXECUTABLE -U postgres -f $deleteFile
if [ $? -ne 0 ]; then
    echo "Error while dropping databases"
    exit 1;
fi
echo "Successfully cleaned up PostgreSQL database"
