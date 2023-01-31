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

# postgres user for ranger
su - postgres -c "createdb ranger"
sudo -u postgres psql -c "create user rangeradmin WITH PASSWORD 'welcome'; " 
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ranger  TO rangeradmin;"

# start ranger 
/usr/local/ranger-2.3.0-admin/setup.sh
ranger-admin start 

# start ranger hdfs plugin
/usr/local/ranger-2.3.0-hdfs-plugin/enable-hdfs-plugin.sh
stop-all.sh
start-all.sh

# setup and start ranger usersync service
cd /usr/local/usersync
/usr/local/usersync/setup.sh
ranger-usersync start


exec "$@"
