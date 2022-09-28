FROM ubuntu

EXPOSE 9870
EXPOSE 8088
EXPOSE 22
EXPOSE 4040
EXPOSE 18080

RUN  apt-get update && apt-get -y install sudo 

# users etc
RUN adduser hadoop
RUN usermod -aG sudo hadoop


# curl etc
RUN apt-get install -y curl
RUN apt-get install -y wget
RUN apt-get install -y vim
RUN apt-get install -y net-tools
RUN apt-get install -y apt-utils
RUN apt-get install -y dialog

# ssh setup
RUN apt-get install -y openssh-server
RUN apt-get install -y openssh-client
RUN apt-get install -y mlocate

# jdk,ssh etc
RUN apt-get install -y openjdk-11-jdk
RUN apt-get install -y unzip
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-arm64

# hadoop
RUN wget https://downloads.apache.org/hadoop/common/hadoop-3.3.4/hadoop-3.3.4.tar.gz
RUN tar -xvzf hadoop-3.3.4.tar.gz
RUN mv hadoop-3.3.4 /usr/local/hadoop
RUN mkdir /usr/local/hadoop/logs

# spark
RUN mkdir /tmp/spark-events
RUN wget https://dlcdn.apache.org/spark/spark-3.3.0/spark-3.3.0-bin-hadoop3.tgz
RUN tar -xvf spark-3.3.0-bin-hadoop3.tgz
RUN mv spark-3.3.0-bin-hadoop3 /usr/local/spark
RUN mv /usr/local/spark/conf/spark-defaults.conf.template /usr/local/spark/conf/spark-defaults.conf
RUN echo "spark.master    yarn" >> /usr/local/spark/conf/spark-defaults.conf
RUN echo "spark.eventLog.enabled  true" >>  /usr/local/spark/conf/spark-defaults.conf
RUN echo "spark.history.provider            org.apache.spark.deploy.history.FsHistoryProvider"  >>  /usr/local/spark/conf/spark-defaults.conf
RUN echo "spark.eventLog.dir file:///tmp/spark-events" >>  /usr/local/spark/conf/spark-defaults.conf
RUN echo "spark.history.fs.logDirectory   file:///tmp/spark-events"  >>  /usr/local/spark/conf/spark-defaults.conf
RUN echo "spark.history.fs.update.interval  10s" >>  /usr/local/spark/conf/spark-defaults.conf
RUN echo "spark.history.ui.port             18080" >>  /usr/local/spark/conf/spark-defaults.conf

# ssh related
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config
RUN echo ""
RUN echo "root:root" | chpasswd
RUN echo "hadoop:hadoop" | chpasswd
RUN mkdir -p /var/run/sshd
RUN echo "mkdir -p /var/run/sshd" >> /etc/rc.local
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

#**************  hadoop user *********************

RUN /usr/bin/ssh-keygen -A
RUN ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa
RUN cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
RUN chmod 0600 ~/.ssh/authorized_keys

# envs
ENV HADOOP_HOME=/usr/local/hadoop
ENV HADOOP_INSTALL=$HADOOP_HOME
ENV HADOOP_MAPRED_HOME=$HADOOP_HOME
ENV HADOOP_COMMON_HOME=$HADOOP_HOME
ENV HADOOP_HDFS_HOME=$HADOOP_HOME
ENV YARN_HOME=$HADOOP_HOME
ENV HADOOP_COMMON_LIB_NATIVE_DIR=$HADOOP_HOME/lib/native
ENV PATH=$PATH:$HADOOP_HOME/sbin:$HADOOP_HOME/bin
ENV HADOOP_OPTS="-Djava.library.path=$HADOOP_HOME/lib/native"
ENV SPARK_HOME=/usr/local/spark
ENV PATH=$PATH:$SPARK_HOME/bin:$SPARK_HOME/sbin
ENV LD_LIBRARY_PATH=/usr/local/hadoop/lib/native:$LD_LIBRARY_PATH
ENV HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
ENV YARN_CONF_DIR=$HADOOP_HOME/etc/hadoop


# setup envs vars, props  in Hadoop
RUN echo "export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-arm64" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh
RUN echo "export HADOOP_CLASSPATH+="$HADOOP_HOME/lib/*.jar""  >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh 
RUN echo 'export HDFS_NAMENODE_USER=root'   >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh
RUN echo 'export HDFS_DATANODE_USER=root'  >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh
RUN echo 'export HDFS_SECONDARYNAMENODE_USER=root'  >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh
RUN echo 'export YARN_RESOURCEMANAGER_USER=root'  >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh
RUN echo 'export YARN_NODEMANAGER_USER="root"'  >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh

WORKDIR /usr/local/hadoop/lib
RUN wget https://jcenter.bintray.com/javax/activation/javax.activation-api/1.2.0/javax.activation-api-1.2.0.jar 
RUN chown hadoop:hadoop /usr/local/hadoop/lib/*

# name  node config
SHELL ["/bin/bash", "-c"]

RUN echo $'<configuration> \n\
   <property> \n\
      <name>fs.default.name</name> \n\
      <value>hdfs://0.0.0.0:9000</value> \n\
      <description>The default file system URI</description> \n\
   </property> \n\
</configuration>'  > $HADOOP_HOME/etc/hadoop/core-site.xml 

# hdfs data
RUN mkdir -p /home/hadoop/hdfs/{namenode,datanode}
#RUN chown -R hadoop:hadoop /home/hadoop/hdfs
RUN echo   $'<configuration> \n\   
   <property>  \n\
      <name>dfs.replication</name> \n\
      <value>1</value>  \n\
   </property>  \n\
   <property> \n\  
      <name>dfs.name.dir</name> \n\ 
      <value>file:///home/hadoop/hdfs/namenode</value> \n\ 
   </property>  \n\
   <property> \n\
      <name>dfs.data.dir</name> \n\  
      <value>file:///home/hadoop/hdfs/datanode</value> \n\ 
   </property>  \n\
 </configuration>'    >  $HADOOP_HOME/etc/hadoop/hdfs-site.xml


# mapred values
RUN echo $'<configuration> \n\
   <property> \n\
      <name>mapreduce.framework.name</name> \n\
      <value>yarn</value> \n\
   </property> \n\
</configuration>'  >   $HADOOP_HOME/etc/hadoop/mapred-site.xml 

# yarn settings
RUN echo $'<configuration> \n\
   <property> \n\
      <name>yarn.nodemanager.aux-services</name> \n\
      <value>mapreduce_shuffle</value> \n\
   </property> \n\
</configuration>'  > $HADOOP_HOME/etc/hadoop/yarn-site.xml

# mysql setup for hive
# https://www.digitalocean.com/community/tutorials/how-to-install-mysql-on-ubuntu-20-04

# postgreqSQL tryouts
ARG DEBIAN_FRONTEND=noninteractive
RUN apt install postgresql postgresql-contrib -f -y


# Hive setup -http://www.sqlnosql.com/install-hive-on-hadoop-3-xx-on-ubuntu-with-postgresql-database/
RUN wget https://dlcdn.apache.org/hive/hive-3.1.3/apache-hive-3.1.3-bin.tar.gz
RUN tar -xvf apache-hive-3.1.3-bin.tar.gz
RUN mv apache-hive-3.1.3-bin /usr/local/hive
ENV HIVE_HOME=/usr/local/hive
ENV PATH=$PATH:$HIVE_HOME/bin
RUN cp $HIVE_HOME/conf/hive-env.sh.template $HIVE_HOME/conf/hive-env.sh
RUN echo "export HADOOP_HEAPSIZE=512 " >> >> $HIVE_HOME/conf/hive-env.sh
RUN echo "export HIVE_CONF_DIR=/usr/local/hive/conf" >> $HIVE_HOME/conf/hive-env.sh
RUN echo "export HADOOP_HOME=/usr/local/hadoop" >> $HIVE_HOME/conf/hive-env.sh
RUN cp /$HIVE_HOME/hcatalog/etc/hcatalog/proto-hive-site.xml $HIVE_HOME/conf/hive-site.xml



# run ssh server
ENTRYPOINT ["/docker-entrypoint.sh"]


