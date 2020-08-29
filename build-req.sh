#Set Hostname
sudo hostnamectl set-hostname msr
#Allow user to run all as root
sudo usermod -G wheel -a $USER
#Add Pre-requisites
sudo swupd bundle-add buildreq-spark nginx jupyter conda java11-basic
sudo updatedb
#sudo pip3 install for transferring keys
systemctl enable --now sshd.service
sudo pip3 install pssh
#Set SSH Keys
cat /dev/zero | ssh-keygen -q -N "" > /dev/null
cat ~/.ssh/id_rsa.pub | pssh -h ips.txt -l remoteuser -A -I -i 'umask 077; mkdir -p ~/.ssh; afile=~/.ssh/authorized_keys; cat - >> $afile; sort -u $afile -o $afile'
mkdir -p /opt/{hadoop,hdfs/{namenode,datanode},spark,yarn/{logs,local},zep/notes} && sudo chown -R ${USER} /opt/{hadoop,hdfs/{namenode,datanode},spark,yarn/{logs,local},zep/notes}
sudo mkdir -p /var/log/{hadoop/pid,spark,zep/pid} && sudo chown -R ${USER} /var/log/{hadoop/pid,spark,zep/pid}
sudo mkdir -p /etc/{hadoop,spark,zep} && sudo chown -R ${USER} /etc/{hadoop,spark,zep}
#add env vars
sudo tee -a /etc/profile <<'EOF'
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
export ZEPPELIN_HOME="$DEV_HOME/zep"
export PYSPARK_PYTHON="$SPARK_HOME/python/pyspark"
export PYTHONPATH="$PYTHONPATH:$SPARK_HOME/python:/usr/bin/ipython3"
export R_HOME=/usr/lib64/R
export R_LIBS_USER=/opt/r
export PATH="$JAVA_HOME/bin:$HADOOPHOME/sbin:$HADOOPHOME/bin:$SPARK_HOME/bin:$SPARK_HOME/sbin:$ZEPPELIN_HOME/bin:$R_HOME:$PATH"
EOF
popd
#DARS config
sudo tee -a /etc/dars.ld.so.conf <<'EOF'
/usr/lib64/haswell/avx512_1
EOF
sudo ldconfig
#Get Spark
cd $HOME
wget https://downloads.apache.org/spark/spark-3.0.0/spark-3.0.0-bin-hadoop2.7.tgz
tar xvf spark-3.0.0-bin-hadoop2.7.tgz
rm spark-3.0.0-bin-hadoop2.7.tgz
mv spark-3.0.0-bin-hadoop2.7 $DEV_HOME/spark
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
msr
nu1
nu2
nu3
nu4
nu5
nu6
nu7
nu8
nu9
nu10
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
$HADOOPHOME/bin/hdfs namenode -format
#start DFS in NameNode @9870 and Data Nodes with...
$HADOOPHOME/sbin/start-dfs.sh
#start YARN daemons @8088
$HADOOPHOME/sbin/start-yarn.sh
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

[Install]
WantedBy=multi-user.target
EOF
#zeppelin
cd $HOME
wget https://downloads.apache.org/zeppelin/zeppelin-0.9.0-preview1/zeppelin-0.9.0-preview1-bin-all.tgz
tar xvf zeppelin-0.9.0-preview1-bin-all.tgz
rm zeppelin-0.9.0-preview1-bin-all.tgz
mv -v ./zeppelin-0.9.0-preview1-bin-all ./zeppelin
mv -v ./zeppelin/* $ZEPPELIN_HOME
cat > $ZEPPELIN_HOME/conf/zeppelin-env.sh << EOF
export JAVA_HOME=$JAVA_HOME
export MASTER=yarn-cluster
export ZEPPELIN_PORT=8888
export SPARK_HOME=$SPARK_HOME
export SPARK_CONF_DIR=$SPARK_CONF_DIR
export PYSPARK_PYTHON=$PYSPARK_PYTHON
export PYTHONPATH=$PYTHONPATH
export HADOOP_CONF_DIR=$HADOOP_CONF_DIR
export ZEPPELIN_NOTEBOOK_DIR=$ZEPPELIN_NOTEBOOK_DIR
export ZEPPELIN_SERVER_DEFAULT_DIR_ALLOWED=true
export ZEPPELIN_NOTEBOOK_DIR=$ZEPPELIN_HOME/notes
export ZEPPELIN_INTERPRETER_DIR=$ZEPPELIN_HOME/interpreter
EOF
#set system unit file for zeppelin
sudo -i
cat > /etc/systemd/system/zeppelin.service << EOF
[Unit]
Description=Zeppelin service
After=syslog.target network.target

[Service]
Type=forking
ExecStart=$ZEPPELIN_HOME/bin/zeppelin-daemon.sh --config /etc/zep start
ExecStop=$ZEPPELIN_HOME/bin/zeppelin-daemon.sh stop
ExecReload=$ZEPPELIN_HOME/bin/zeppelin-daemon.sh reload
User=${USER}
Group=${USER}
Restart=always

[Install]
WantedBy=multi-user.target
EOF
sudo jupyter notebook --generate-config
#f/u check SPARKR_RLIBDIR
#Zotero
wget https://www.zotero.org/download/client/dl?channel=release&platform=linux-x86_64&version=5.0.89
tar xvf Zotero-5.0.89_linux-x86_64.tar.bz2
mv Zotero-5.0.89_linux-x86_64 $DEV_HOME/zotero
rm -rf Zotero-5.0.89_linux-x86_64.tar.bz2
cd $DEV_HOME
./zotero/set_launcher_icon
./zotero/zotero
#get firefox extension
#fu figure out path to install
wget https://download.zotero.org/connector/firefox/release/Zotero_Connector-5.0.68.xpi
#fu figure out automation of BetterBibtex
wget https://github.com/retorquere/zotero-better-bibtex/releases/download/v5.2.47/zotero-better-bibtex-5.2.47.xpi
#fu figure out automation of MarkdownZotero
wget https://github.com/fei0810/markdownhere4zotero/raw/master/markdownhere4zotero_kaopubear_190914.xpi
#fu figure out automation of ZotFile plugin
wget https://github.com/jlegewie/zotfile/releases/download/v5.0.16/zotfile-5.0.16-fx.xpi
#fu append existing file ~/Zotero/locate/engine.json
[
    {
        "name": "Sci-Hub Lookup",
        "alias": "Sci-Hub",
        "icon": "null",
        "_urlTemplate": "https://sci-hub.tw/{z:DOI}",
        "description": "Sci-Hub full text PDF search",
        "hidden": false,
        "_urlParams": [],
        "_urlNamespaces": {
            "z": "http://www.zotero.org/namespaces/openSearch#",
            "": "http://a9.com/-/spec/opensearch/1.1/"
        },
        "_iconSourceURI": "http://sci-hub.tw/favicon.ico"
    }
]
#setup mixer
mkdir ~/mixer
cd ~/mixer
sudo swupd bundle-add mixer
mixer init
#~/mixer/buidler.conf
sudo tee -a ~/mixer/builder.conf >> EOF
CONTENTURL="http://${HOSTNMAE -I}"
VERSIONURL="http://${HOSTNAME -I}"
EOF

#Make Nginx for Mixer/Bundle Creation
sudo mkdir -p /var/www
sudo ln -sf $HOME/mixer/update/www /var/www/mixer
sudo mkdir -p  /etc/nginx/conf.d
sudo cp -f /usr/share/nginx/conf/nginx.conf.example /etc/nginx/nginx.conf
#Grant user permissions
sudo tee -a /etc/nginx/nginx.conf << EOF
user $USER;
EOF
#Configure the mixer update server
sudo tee /etc/nginx/conf.d/mixer-server.conf << EOF
server {
  server_name localhost;
  location / {
    root /var/www/mixer;
    autoindex on;
  }
}
EOF
#Restart the daemon, enable nginx on boot, and start the service.
sudo systemctl daemon-reload
sudo systemctl enable nginx --now
#Make top-level directory to house stack
mkdir ~/stack && pushd $_
#Place Spark
mkdir -p spark/usr/bin && pushd $_
# create helloclear.sh script
cat > helloclear.sh << EOF
#!/bin/bash
echo "Hello Clear!"
EOF
# make script executable
chmod +x helloclear.sh
popd

#install autospec
sudo swupd bundle-add os-clr-on-clr
curl -O https://raw.githubusercontent.com/clearlinux/common/master/user-setup.sh
chmod +x user-setup.sh
./user-setup.sh
git config --global user.email "admin@krisc.dev"
git config --global user.name "krisc"

#Work in progres... figure out how to bundle above
#krisc@nu1~/mixer $
mixer bundle create spark --local
echo "content($SPARK_HOME/)" >> local-bundles/spark
mixer bundle create hadoop --local
echo "content($HADOOPHOME/)" >> local-bundles/hadoop
mixer bundle create zeppelin --local
echo "content($ZEPPELIN_HOME/)" >> local-bundles/zeppelin
