export HADOOP_CONF_DIR=$(pwd)
rm core-site.xml hdfs-site.xml mapred-site.xml yarn-site.xml workers hadoop-env.sh *.example *.template
#Hadoop core-site
cat > $HADOOP_CONF_DIR/core-site.xml << EOF
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
cat > $HADOOP_CONF_DIR/hdfs-site.xml << EOF
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
		<value>10</value></property>
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
sudo cat > workers << EOF
msr
w1
w2
w3
w4
w5
w6
w7
w8
w9
wa
lt
EOF
sudo cat > $HADOOP_CONF_DIR/hadoop-env.sh << EOF
export JAVA_HOME=$JAVA_HOME
EOF
