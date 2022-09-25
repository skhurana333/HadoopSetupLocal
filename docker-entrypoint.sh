#!/bin/bash
service ssh restart
hdfs namenode -format
start-dfs.sh
start-yarn.sh
$SPARK_HOME/sbin/start-history-server.sh
hdfs dfs -mkdir /spark-events
hdfs dfs -mkdir /tpcds_data1gb
hdfs dfs -put /testdata/data /tpcds_data1gb
exec "$@"
