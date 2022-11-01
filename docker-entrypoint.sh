#!/bin/bash
service ssh restart
hdfs namenode -format
start-dfs.sh
start-yarn.sh
hdfs dfsadmin -safemode leave
$SPARK_HOME/sbin/start-history-server.sh
hdfs dfs -mkdir /spark-events
hdfs dfs -mkdir -p /user/hive/warehouse
hdfs dfs -mkdir /tmp
hdfs dfs -ls /user/hive/
hdfs dfs -chmod g+w /user/hive/warehouse
hdfs dfs -chmod g+w /tmp
service postgresql  start

set -e

su - postgres -c "createdb hivemetastoredb"
sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD 'welcome';"
echo "hive hivemetastored created"
schematool -initSchema -dbType postgres
exec "$@"
