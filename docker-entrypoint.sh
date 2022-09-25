#!/bin/bash
service ssh restart
hdfs namenode -format
start-dfs.sh
start-yarn.sh
$SPARK_HOME/sbin/start-history-server.sh
hdfs dfs -mkdir /spark-events
exec "$@"
