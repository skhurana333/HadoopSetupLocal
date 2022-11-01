Docker image having hdfs, yarn, Spark for testing on local laptop. 
Spark is configured to work with Yarn.
Please use below command to start the container 

Namenode Url
===========
localhost:9000

Branches
=======
main branch - Spark with Yarn,. hdfs
hives_setup branch - Above and Hive
spark_hive_ranger branch - Above and Ranger. It has solr etc

spark_hive_ranger Branch Docs
=============================
Ranger UI (localhost:6080)
------------------------
User Id - admin
password - Welcome123

Docker Run Command
------------------
 docker run -p 9870:9870  -p 8088:8088  -p 4040:4040 -p 18080:18080 -p 8080:8080 -p 6080:6080  -v ~/dummy:/hostdata  -d   imageId        tail -f /dev/null

Ports Opened
----------
6080 - For Ranger Admin UI
9870 - Namenode UI
8088 - Hdfs UI
22
4040
18080 - Spark UI

Versions
--------
JDK - openjdk 8
Hadopp (Yarn + hdfs) - 3.3.4
Spark - 3.3.1
Hive - 3.1.3
Apache Ranger - 2.3.0
Postgres - 14
Hive and Ranger DB - postgres

hives_setup Branch Docs
=======================
hives_setup has Spark with Yarn and Hive also. Hive metaDB is postgresSQL

Main Branch Docs
===============
Main brnac has Spark with Yarn

If Using Only On Local
---------------------
- To create image -> docker build . 
- Get image is from this command -> docker image ls 
- To start container ->  docker run -p 9870:9870  -p 8088:8088  -p 4040:4040 -p 18080:18080 -v ~/:/hostdata  -d local_spark_dev  tail -f /dev/null
- Get continer id -> docker ps 
- Log in to container -> docker exec -it containerId bash 
- Chech UIs from local laptop ->  localhost:9870 (name mode UI) , localhost:8088 (yarn UI) 

Test 
----
- spark-shell
- On Spark shell

val data = Seq(("Java", "20000"), ("Python", "100000"), ("Scala", "3000"))
val df = data.doDF
df.write.parquet("hdfs://localhost:9000/tdata") 

- validate data is in hdfs -> hdfs dfs /tdata

