#cd to hadoop conf, wget raw file, chmod +x hadoop.sh, bash hadoop.sh
export HADOOP_CONF_DIR=$(pwd)
rm core-site.xml hdfs-site.xml mapred-site.xml yarn-site.xml workers hadoop-env.sh *.example *.template
#Hadoop core-site
cat > $HADOOP_CONF_DIR/core-site.xml << EOF
<configuration>
	<property>
		<name>fs.defaultFS</name>
		<value>hdfs://192.168.1.157:9820/</value>
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
		<value>1</value></property>
	<property>
		<name>dfs.permissions</name>
		<value>false</value>
	</property>
	<property>
		<name>dfs.hosts</name>
		<value>w1,w2,w3,w4,w5,w6,w7,w8,w9,wa,lt,mgr</value>
	</property>
	<property>
		<name>dfs.namenode.datanode.registration.ip-hostname-check</name>
		<value>true</value>
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
		<value>192.168.1.157:10020</value>
		<description>Default port is 10020.</description>
	</property>
	<property>
		<name>mapreduce.jobhistory.webapp.address</name>
		<value>192.168.1.157:19888</value>
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
192.168.1.157 mgr
192.168.1.7 w1
192.168.1.8 w3
192.168.1.9 w4
192.168.1.13 w5
192.168.1.14 w6
192.168.1.15 w7
192.168.1.16 w8
192.168.1.17 w9
192.168.1.18 wa
EOF
sudo cat > $HADOOP_CONF_DIR/hadoop-env.sh << EOF
export JAVA_HOME=$JAVA_HOME
EOF
