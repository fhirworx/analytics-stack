#configs
sudo mkdir /etc/profile.d && sudo chown -R ${USER} /etc/profile.d
cat > /etc/profile.d/r.sh << EOF
export R_HOME=/opt/R/
export R_LD_LIBRARY_PATH=/opt/R/lib
EOF
cat > /etc/profile.d/java.sh << EOF
export JAVA_HOME=/opt/java
export JAVA=$JAVA_HOME/bin/java
export JAVAC=$JAVA_HOME/bin/javac
export JAVAH=$JAVA_HOME/bin/javah
export JAR=$JAVA_HOME/bin/jar
export _JAVA_OPTIONS="-Dio.netty.tryReflectionSetAccessible=true"
EOF
cat > /etc/profile.d/env.sh << EOF
export PATH="$JAVA_HOME/bin:$R_HOME/bin:$PATH"
EOF
#download from source, unpack, and compile
cd /opt
wget https://apache.osuosl.org/maven/maven-3/3.6.3/binaries/apache-maven-3.6.3-bin.tar.gz
tar xvf apache-maven-3.6.3-bin.tar.gz
mv apache-maven-3.6.3 mvn && rm apache-maven-3.6.3-bin.tar.gz
#interactive download of https://download.oracle.com/otn-pub/java/jdk/14.0.2+12/205943a0976c4ed48cb16f1043c5c647/jdk-14.0.2_linux-x64_bin.tar.gz
cd ~/Downloads && mv jdk-14.0.2_linux-x64_bin.tar.gz /opt
tar xvf jdk-14.0.2_linux-x64_bin.tar.gz
mv jdk-14.0.2 java && rm jdk-14.0.2_linux-x64_bin.tar.gz
wget https://stat.ethz.ch/R/daily/R-patched.tar.gz
tar xvf R-patched.tar.gz
mv R-patched R && rm R-patched.tar.gz
cd R_HOME
./configure --prefix=opt
make
make install
R CMD javareconf
