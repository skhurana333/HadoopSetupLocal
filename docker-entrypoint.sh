#!/bin/bash
service ssh restart
hdfs namenode -format
start-dfs.sh
start-yarn.sh
$SPARK_HOME/sbin/start-history-server.sh
hdfs dfs -mkdir /spark-events
hdfs dfs -mkdir -p /user/hive/warehouse
hdfs dfs -mkdir /tmp
hdfs dfs -ls /user/hive/
hdfs dfs -chmod g+w /user/hive/warehouse
hdfs dfs -chmod g+w /tmp
service postgresql  start
exec "$@"
