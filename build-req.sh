swupd bundle-add buildreq-spark
updatedb
mkdir -p /opt/{hadoop,hdfs/{namenode,datanode},spark,yarn/{logs,local}} && chown -R ${USER} /opt/{hadoop,hdfs/{namenode,datanode},spark,yarn/{logs,local}}
mkdir -p /var/log/{hadoop/pid,spark,zep/pid} && sudo chown -R ${USER} /var/log/{hadoop/pid,spark}
mkdir -p /etc/{hadoop,spark,zep} && sudo chown -R ${USER} /etc/{hadoop,spark}
#add env vars
tee -a /etc/profile <<'EOF'
export JAVA_HOME=/usr/lib/jvm/java-1.11.0-openjdk
export JAVA="$JAVA_HOME/bin/java"
export JAVAC="$JAVA_HOME/bin/javac"
export JAVAH="$JAVA_HOME/bin/javac -h"
export JAR="$JAVA_HOME/bin/jar"
export DEV_HOME=/opt/
export HADOOP_HOME="$DEV_HOME/hadoop"
export HADOOP_INSTALL="$HADOOP_HOME"
export HADOOP_MAPRED_HOME="$HADOOP_HOME"
export HADOOP_COMMON_HOME="$HADOOP_HOME"
export HADOOP_HDFS_HOME="$HADOOP_HOME"
export HADOOP_YARN_HOME="$HADOOP_HOME"
export HADOOP_CONF_DIR=/etc/hadoop
export HADOOP_COMMON_LIB_NATIVE_DIR="$HADOOP_HOME/lib/native"
export HADOOP_DEFAULT_LIBEXEC_DIR="$HADOOP_HOME/libexec"
export HADOOP_IDENT_STRING=${USER}
export HADOOP_LOG_DIR=/var/log/hadoop
export HADOOP_PID_DIR=/var/log/hadoop/pid
export HADOOP_OPTS="-Djava.library.path=/opt/hadoop/lib/native -Dio.netty.tryReflectionSetAccessible=true"
export HDFS_DATANODE_USER=${USER}
export HDFS_NAMENODE_USER=${USER}
export HDFS_SECONDARYNAMENODE_USER=${USER}
export SPARK_HOME="$DEV_HOME/spark"
export SPARK_CONF_DIR=/etc/spark
export YARN_RESOURCEMANAGER_USER=${USER}
export YARN_NODEMANAGER_USER=${USER}
export R_HOME=/usr/lib64/R
export R_LIBS_USER=/opt/r
export PATH="$JAVA_HOME/bin:$HADOOPHOME/sbin:$HADOOPHOME/bin:$SPARK_HOME/bin:$SPARK_HOME/sbin:$ZEPPELIN_HOME/bin:$R_HOME:$PATH"
EOF
cd $HOME
wget https://downloads.apache.org/spark/spark-3.0.2/spark-3.0.2-bin-hadoop3.2.tgz
tar xvf spark-3.0.2/spark-3.0.2-bin-hadoop3.2.tgz
rm spark-3.0.2/spark-3.0.2-bin-hadoop3.2.tgz
mv spark-3.0.2-bin-hadoop3.2 $DEV_HOME/spark
#Spark
#set system unit file master
sudo -i
cat > /etc/systemd/system/spark.service << EOF
[Unit]
Description=Spark
After=syslog.target network.target network-online.target
Requires=network-online.target

[Service]
User=${USER}
Group=${USER}
Type=forking
ExecStart=/opt/spark/sbin/start-all.sh
ExecStop=/opt/spark/sbin/stop-all.sh
WorkingDirectory=$DEV_HOME
Environment=JAVA_HOME=/usr/lib/jvm/java-1.11.0-openjdk
Environment=SPARK_HOME=$SPARK_HOME
Environment=HADOOP_COMMON_HOME=$HADOOP_COMMON_HOME
TimeoutStartSec=2min
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
#copy templates
sudo cp $SPARK_HOME/conf/* $SPARK_CONF_DIR
sudo cp $SPARK_CONF_DIR/log4j.properties.template $SPARK_CONF_DIR/log4j.properties
#copy templates to create custom configuration files
sudo cat > $SPARK_CONF_DIR/spark-env.sh << EOF
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$HADOOPHOME/lib/native
SPARK_MASTER_HOST=$HOSTNAME
EOF
sudo cat > $SPARK_CONF_DIR/spark-defaults.conf << EOF
spark.master                     	yarn
spark.submit.deployMode                 cluster
spark.eventLog.enabled           	true
spark.eventLog.dir               	hdfs://namenode:8021/spark-logs
spark.serializer                 	org.apache.spark.serializer.KryoSerializer
spark.driver.memory              	24g
spark.executor.memory		  	7g
spark.executor.userClassPathFirst	true
spark.pyspark.python			/usr/bin/ipython3
#spark.driver.log.dfsDir	
spark.yarn.jars /opt/spark/jars
spark.yarn.populateHadoopClasspath false
yarn.nodemanager.local-dirs /opt/hadoop/etc/hadoop
spark.driverEnv.JAVA_HOME=/usr/lib/jvm/java-1.11.0-openjdk
spark.driverEnv.YARN_CONF_DIR=/opt/hadoop/etc/hadoop
spark.executorEnv.JAVA_HOME=/usr/lib/jvm/java-1.11.0-openjdk
spark.executorEnv.YARN_CONF_DIR=/opt/hadoop/etc/hadoop
spark.driver.extraJavaOptions -Dio.netty.tryReflectionSetAccessible=true -Djava.library.path=/opt/hadoop/lib/native
spark.executor.extraJavaOptions -Dio.netty.tryReflectionSetAccessible=true -Djava.library.path=/opt/hadoop/lib/native
EOF
#setup R packages for SparkR
sudo Rscript -e "install.packages(c('rJava','sparklyr', 'IRkernel', 'tm', 'openNLP', 'RWeka', 'shiny', 'officer', 'rio', 'knitr', 'rmarkdown', 'devtools', 'testthat', 'e1071', 'survival', 'ggplot2', 'mplot', 'googleVis','glmnet', 'pROC', 'data.table', 'caret', 'sqldf', 'wordcloud') repos='https://cloud.r-project.org/')"
#Start the master server:
sudo systemctl daemon-reload
sudo systmectl enable spark.service --now
sudo systemctl start spark.service
#Hadoop
ssh localhost #f/u automate 
cd $HOME
wget http://mirror.cc.columbia.edu/pub/software/apache/hadoop/common/hadoop-3.3.0/hadoop-3.3.0.tar.gz
tar xvf hadoop-3.3.0.tar.gz
rm hadoop-3.3.0.tar.gz
mv hadoop-3.3.0 $HADOOPHOME
cd $HOME
#Hadoop core-site
sudo cat > $HADOOP_CONF_DIR/core-site.xml << EOF
<configuration>
	<property>
		<name>fs.defaultFS</name>
		<value>hdfs://msr:9820/</value>
		<description>NameNode URI</description>
	</property>
	<property>
		<name>io.file.buffer.size</name>
		<value>131072</value>
		<description>Buffer size</description>
	</property>
</configuration>
EOF
#HDFS
sudo cat > $HADOOP_CONF_DIR/hdfs-site.xml << EOF
<configuration>
	<property>
		<name>dfs.namenode.name.dir</name>
		<value>file:///opt/hdfs/namenode</value>
		<description>NameNode directory for namespace and transaction logs storage.</description>
	</property>
	<property>
		<name>dfs.datanode.data.dir</name>
		<value>file:///opt/hdfs/datanode</value>
		<description>DataNode directory</description>
	</property>
	<property>
		<name>dfs.replication</name>
		<value>1</value></property>
	<property>
		<name>dfs.permissions</name>
		<value>false</value>
	</property>
	<property>
		<name>dfs.datanode.use.datanode.hostname</name>
		<value>true</value>
	</property>
	<property>
		<name>dfs.namenode.datanode.registration.ip-hostname-check</name>
		<value>false</value>
	</property>
</configuration>
EOF
#map reduce
sudo cat > $HADOOP_CONF_DIR/mapred-site.xml << EOF
<configuration>
	<property>
		<name>mapreduce.framework.name</name>
		<value>yarn</value>
		<description>MapReduce framework name</description>
	</property>
	<property>
		<name>mapreduce.jobhistory.address</name>
		<value>msr:10020</value>
		<description>Default port is 10020.</description>
	</property>
	<property>
		<name>mapreduce.jobhistory.webapp.address</name>
		<value>msr:19888</value>
		<description>Default port is 19888.</description>
	</property>
	<property>
		<name>mapreduce.jobhistory.intermediate-done-dir</name>
		<value>/mr-history/tmp</value>
		<description>Directory where history files are written by MapReduce jobs.</description>
	</property>
	<property>
		<name>mapreduce.jobhistory.done-dir</name>
		<value>/mr-history/done</value>
		<description>Directory where history files are managed by the MR JobHistory Server.</description>
	</property>
</configuration>
EOF
sudo cat > $HADOOP_CONF_DIR/yarn-site.xml << EOF
<configuration>
	<property>
 		<name>yarn.resourcemanager.hostname</name>
		<value>msr</value>
	</property>
	<property>
		<name>yarn.nodemanager.aux-services</name>
		<value>mapreduce_shuffle</value>
		<description>Yarn Node Manager Aux Service</description>
	</property>
	<property>
		<name>yarn.nodemanager.aux-services.mapreduce.shuffle.class</name>
		<value>org.apache.hadoop.mapred.ShuffleHandler</value>
	</property>
	<property>
		<name>yarn.nodemanager.local-dirs</name>
		<value>file:///opt/yarn/local</value>
	</property>
	<property>
		<name>yarn.nodemanager.log-dirs</name>
		<value>file:///opt/yarn/logs</value>
	</property>
</configuration>
EOF
#workers /etc/hadoop/workers
sudo cat > $HADOOP_CONF_DIR/workers << EOF
rig.krisc.dev
nuc2.krisc.dev
nuc4.krisc.dev
nuc6.krisc.dev
nuc7.krisc.dev
nuc8.krisc.dev
nuc9.krisc.dev
nuc10.krisc.dev
nuc11.krisc.dev
nuc12.krisc.dev
nuc13.krisc.dev
EOF
sudo cp $HADOOPHOME/log4j.properties /etc/hadoop
sudo cat > $HADOOP_CONF_DIR/hadoop-env.sh << EOF
export JAVA_HOME=$JAVA_HOME
export HADOOP_HOME=$HADOOPHOME
export HADOOP_LIBEXEC_DIR=$HADOOPHOME/libexec
export HADOOP_CONF_DIR=$HADOOP_CONF_DIR
export HDFS_NAMENODE_USER=${USER}
export HDFS_DATANODE_USER=${USER}
export HDFS_SECONDARYNAMENODE_USER=${USER}
export YARN_RESOURCEMANAGER_USER=${USER}
export YARN_NODEMANAGER_USER=${USER}
EOF
#format NameNode
ssh-copy-id localhost
$HADOOP_HOME/bin/hdfs namenode -format
#start DFS in NameNode @9870 and Data Nodes with...
$HADOOP_HOME/sbin/start-dfs.sh
#start YARN daemons @8088
$HADOOP_HOME/sbin/start-yarn.sh
#setup hadoop system unit
sudo -i
cat > /etc/systemd/system/hadoop.service << EOF
[Unit]
Description=Hadoop DFS namenode and datanode plus yarn resouce manager and node manager
After=syslog.target network.target network-online.target
Requires=network-online.target

[Service]
User=${USER}
Group=${USER}
Type=forking
ExecStart=/opt/hadoop/sbin/start-all.sh
ExecStop=/opt/hadoop/sbin/stop-all.sh
WorkingDirectory=/opt
Environment=JAVA_HOME=$JAVA_HOME
Environment=HADOOP_COMMON_HOME=$HADOOP_COMMON_HOME
TimeoutStartSec=2min
Restart=on-failure
