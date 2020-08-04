#Set Hostname
sudo hostnamectl set-hostname msr
#Allow user to run all as root
sudo usermod -G wheel -a $USER
#Add Pre-requisites
sudo swupd bundle-add buildreq-spark nginx jupyter conda
sudo updatedb
#sudo pip3 install for transferring keys
sudo pip3 install pssh
#Set SSH Keys
cat /dev/zero | ssh-keygen -q -N "" > /dev/null
cat ~/.ssh/id_rsa.pub | pssh -h ips.txt -l remoteuser -A -I -i 'umask 077; mkdir -p ~/.ssh; afile=~/.ssh/authorized_keys; cat - >> $afile; sort -u $afile -o $afile'
#add env vars
sudo mkdir /opt/stack
sudo cat /etc/profile << EOF
export JAVA_HOME=/usr/lib/jvm/java-1.11.0-openjdk
export JAVA=$JAVA_HOME/bin/java
export JAVAC=$JAVA_HOME/bin/javac
export JAVAH=$JAVA_HOME/bin/javah
export JAR=$JAVA_HOME/bin/jar
export DEV_HOME=opt/stack
export HADOOPHOME=$DEV_HOME/hadoop
export HADOOP_INSTALL=$HADOOPHOME
export HADOOP_MAPRED_HOME=$HADOOPHOME
export HADOOP_COMMON_HOME=$HADOOPHOME
export HADOOP_HDFS_HOME=$HADOOPHOME
export HADOOP_YARN_HOME=$HADOOPHOME
export HADOOP_CONF_DIR=/etc/hadoop
export HADOOP_COMMON_LIB_NATIVE_DIR=$HADOOPHOME/lib/native
export HADOOP_DEFAULT_LIBEXEC_DIR=$HADOOPHOME/libexec
export HADOOP_IDENT_STRING=hadoop
export HADOOP_LOG_DIR=/var/log/hadoop
export HADOOP_PID_DIR=/var/log/hadoop/pid
export HADOOP_OPTS="-Djava.library.path=/opt/stack/hadoop/lib/native"
export HDFS_DATANODE_USER=hadoop
export HDFS_NAMENODE_USER=hadoop
export HDFS_SECONDARYNAMENODE_USER=hadoop
export SPARK_HOME=$DEV_HOME/spark
export SPARK_CONF_DIR=/etc/spark
export YARN_RESOURCEMANAGER_USER=hadoop
export YARN_NODEMANAGER_USER=hadoop
export ZEPPELIN_HOME=$DEV_HOME/zeppelin
export PYSPARK_PYTHON=$SPARK_HOME/python/pyspark
export PYTHONPATH=$PYTHONPATH:$SPARK_HOME/python:/usr/bin/python
export R_HOME=/usr/lib64/R
export PATH=$JAVA_HOME/bin:$HADOOPHOME/sbin:$HADOOPHOME/bin:$R_HOME:$PATH
EOF
popd
mkdir $DEV_HOME
#Get Spark
cd $DEV_HOME
wget https://downloads.apache.org/spark/spark-3.0.0/spark-3.0.0-bin-hadoop2.7.tgz
tar xvf spark-3.0.0-bin-hadoop2.7.tgz
rm spark-3.0.0-bin-hadoop2.7.tgz
mv spark-3.0.0-bin-hadoop2.7 $SPARK_HOME
#Spark
sudo useradd spark
sudo passwd spark #figure out how to automate
sudo usermod -G wheel -a spark
sudo chown -R $SPARK_HOME/* spark
#set system unit file master
sudo cat /etc/systemd/system/spark-master.service << EOF
[Unit]
Description=Apache Spark Master
After=network.target

[Service]
Type=forking
User=spark
Group=wheel
ExecStart=/opt/spark/sbin/start-master.sh
ExecStop=/opt/spark/sbin/stop-master.sh

[Install]
WantedBy=multi-user.target
EOF
#set system unit file worker
sudo cat /etc/systemd/system/spark-slave.service <<EOF
[Unit]
Description=Apache Spark Slave
After=network.target

[Service]
Type=forking
User=spark
Group=wheel
ExecStart=/opt/spark/sbin/start-slave.sh spark://$HOSTNAME:7077
ExecStop=/opt/spark/sbin/stop-slave.sh

[Install]
WantedBy=multi-user.target
EOF
#create configuration directory
sudo mkdir /etc/spark
#copy templates
sudo cp $SPARK_HOME/conf/* $SPARK_CONF_DIR
sudo cp $SPRK_CONF_DIR/log4j.properties.template $SPARK_CONF_DIR/log4j.properties
#copy templates to create custom configuration files
sudo cat $SPARK_CONF_DIR/spark-env.sh << EOF
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$HADOOPHOME/lib/native
SPARK_MASTER_HOST=$HOSTNAME
EOF
sudo cp /etc/spark/log4j.properties.template /etc/spark/log4j.properties
#Edit the /etc/spark/spark-defaults.conf file and update the spark.master variable with the SPARK_MASTER_HOST address and port 7077.
sudo cat $SPARK_CONF_DIR/spark-defaults.conf << EOF
spark.master    spark://$HOSTNAME:7077
EOF
#setup R packages for SparkR
sudo Rscript -e "install.packages(c('rJava','sparklyr', 'IRkernel', 'tm', 'openNLP', 'RWeka', 'shiny', 'officer', 'rio', 'knitr', 'rmarkdown', 'devtools', 'testthat', 'e1071', 'survival', 'ggplot2', 'mplot', 'googleVis','glmnet', 'pROC', 'data.table', 'caret', 'sqldf', 'wordcloud') repos='https://cloud.r-project.org/')"
#Start the master server:
sudo systemctl daemon-reload
sudo systmectl enable spark-master.service --now
sudo systemctl start spark-master.service
#sudo $SPARK_HOME/sbin/start-master.sh
#Start one worker daemon and connect it to the master using the spark.master variable defined earlier:
sudo systemctl start spark-slave.service
#sudo $SPARK_HOME/sbin/start-slave.sh spark://$HOSTNAME:7077
#Hadoop
sudo mkdir /etc/hadoop
sudo mkdir /var/log/hadoop
sudo useradd hadoop
sudo passwd hadoop #figure out how to automate this
sudo usermod -G wheel -a hadoop
sudo chown -R hadoop:wheel /var/log/hadoop/*
sudo chown -R hadoop:wheel $HADOOPHOME/*
su - hadoop
ssh-keygen -t rsa
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
ssh localhost #f/u automate 
su - hadoop
cd $DEV_HOME
wget http://mirror.cc.columbia.edu/pub/software/apache/hadoop/common/hadoop-3.3.0/hadoop-3.3.0.tar.gz
tar xvf hadoop-3.3.0.tar.gz
rm hadoop-3.3.0.tar.gz
mv hadoop-3.3.0 $HADOOPHOME
sudo cp -r $HADOOPHOME/etc/hadoop/* /etc/hadoop
cd $HOME
mkdir -p ~/hadoopdata/hdfs/namenode
mkdir -p ~/hadoopdata/hdfs/datanode
#/etc/hadoop/core-site.xml
sudo cat /etc/hadoop/core-site.xml << EOF
<configuration>
	<property>
		<name>fs.default.name</name>
		<value>hdfs://$HOSTNAME:9000</value>
	</property>
</configuration>
EOF
#/etc/hadoop/hdfs-site.xml
sudo cat /etc/hadoop/hdfs-site.xml << EOF
<configuration>
	<property>
		<name>dfs.replication</name>
		<value>1</value>
	</property>
	<property>
                <name>dfs.name.dir</name>
                <value>file:///home/hadoop/hadoopdata/hdfs/namenode</value>
        </property>
        <property>
                <name>dfs.data.dir</name>
                <value>file:///home/hadoop/hadoopdata/hdfs/datanode</value>
        </property>
</configuration>
EOF
#/etc/hadoop/mapred-site.xml
sudo cat /etc/hadoop/mapred-site.xml << EOF
<configuration>
	<property>
		<name>mapreduce.framework.name</name>
		<value>yarn</value>
	</property>
</configuration>
EOF
#/etc/hadoop/yarn-site.xml
sudo cat /etc/hadoop/yarn-site.xml << EOF
<configuration>
	<property>
		<name>yarn.nodemanager.aux-services</name>
		<value>mapreduce_shuffle</value>
	</property>
</configuration>
EOF
#workers /etc/hadoop/workers
sudo cat /etc/hadoop/workers << EOF
$HOSTNAME
EOF
sudo cp $HADOOPHOME/log4j.properties /etc/hadoop
sudo cat /etc/hadoop/hadoop-env.sh << EOF
JAVA_HOME=$JAVA_HOME
EOF
#format NameNode
ssh-copy-id localhost
$HADOOPHOME/bin/hdfs namenode -format
#start DFS in NameNode @9870 and Data Nodes with...
$HADOOPHOME/sbin/start-dfs.sh
#start YARN daemons @8088
$HADOOPHOME/sbin/start-yarn.sh
#zeppelin
cd $DEV_HOME
sudo mkdir /var/log/zeppelin
sudo mkdir /var/log/zeppelin/pid
sudo mkdir /usr/share/zep
sudo chmod -R 777 /usr/share/zep
sudo useradd $ZEPPELIN_HOME zeppelin
sudo passwd zeppelin
sudo usermod -G wheel -a zeppelin
sudo chown -R zeppelin $DEV_HOME/zeppelin
sudo chown -R zeppelin $DEV_HOME/zeppelin
su - zeppelin
cd $ZEPPELIN_HOME
wget https://downloads.apache.org/zeppelin/zeppelin-0.9.0-preview1/zeppelin-0.9.0-preview1-bin-all.tgz
tar xvf zeppelin-0.9.0-preview1-bin-all.tgz
rm zeppelin-0.9.0-preview1-bin-all.tgz
mv -v ./zeppelin-0.9.0-preview1-bin-all ./zeppelin
mv -v ./zeppelin/* $ZEPPELIN_HOME
sudo cat > $ZEPPELIN_HOME/conf/zeppelin-env.sh << EOF
export JAVA_HOME=$JAVA_HOME
export MASTER=spark://$HOSTNAME:7077
export ZEPPELIN_PORT=8888
export SPARK_HOME=$SPARK_HOME
export SPARK_CONF_DIR=$SPARK_CONF_DIR
export PYSPARK_PYTHON=$PYSPARK_PYTHON
export PYTHONPATH=$PYTHONPATH
export HADOOP_CONF_DIR=$HADOOP_CONF_DIR
export ZEPPELIN_NOTEBOOK_DIR=$ZEPPELIN_NOTEBOOK_DIR
export ZEPPELIN_SERVER_DEFAULT_DIR_ALLOWED=true
export ZEPPELIN_NOTEBOOK_DIR=/usr/share/zep
export ZEPPELIN_INTERPRETER_DIR=$ZEPPELIN_HOME/interpreter
EOF
#set system unit file for zeppelin
sudo cat /etc/systemd/system/zeppelin.service << EOF
[Unit]
Description=Zeppelin service
After=syslog.target network.target

[Service]
Type=forking
ExecStart=$ZEPPELIN_HOME/bin/zeppelin-daemon.sh --config /etc/zeppelin start
ExecStop=$ZEPPELIN_HOME/bin/zeppelin-daemon.sh stop
ExecReload=$ZEPPELIN_HOME/bin/zeppelin-daemon.sh reload
User=zeppelin
Group=wheel
Restart=always

[Install]
WantedBy=multi-user.target
EOF
sudo jupyter notebook --generate-config
#cd $ZEPPELIN_HOME/bin/zeppelin-daemon.sh --config /etc/zeppelin start
#f/u script out changing below template to reflect accurrate 8888 zeppelin port
#f/u check SPARKR_RLIBDIR
su - zeppelin
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
CONTENTURL="http://192.168.122.232"
VERSIONURL="http://192.168.122.232"
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

#krisc@nu1~/mixer $
mixer bundle create spark --local
echo "content($SPARK_HOME/)" >> local-bundles/spark
mixer bundle create hadoop --local
echo "content($HADOOPHOME/)" >> local-bundles/hadoop
mixer bundle create zeppelin --local
echo "content($ZEPPELIN_HOME/)" >> local-bundles/zeppelin
