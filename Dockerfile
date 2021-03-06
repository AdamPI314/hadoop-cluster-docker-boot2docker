FROM ubuntu:14.04

MAINTAINER Elliot <elliot.srbai@gmail.com>

WORKDIR /root

# supress warnings such as, debconf: unable to initialize frontend: Dialog ...
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

# install openssh-server, openjdk and wget
RUN apt-get -qq update && apt-get -qq install -y openssh-server openjdk-7-jdk wget

# install vim, can live without it
RUN apt-get -qq install -y vim
RUN echo "set nu" >> ~/.vimrc 

# install hadoop 2.7.2
RUN wget https://www-us.apache.org/dist/hadoop/core/hadoop-2.7.2/hadoop-2.7.2.tar.gz && \
    tar -xzvf hadoop-2.7.2.tar.gz && \
    mv hadoop-2.7.2 /usr/local/hadoop && \
    rm hadoop-2.7.2.tar.gz

# set environment variable
ENV JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64 
ENV HADOOP_HOME=/usr/local/hadoop 
ENV PATH=$PATH:/usr/local/hadoop/bin:/usr/local/hadoop/sbin 

# ssh without key
RUN ssh-keygen -t rsa -f ~/.ssh/id_rsa -P '' && \
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys

RUN mkdir -p ~/hdfs/namenode && \ 
    mkdir -p ~/hdfs/datanode && \
    mkdir $HADOOP_HOME/logs

COPY config/* /tmp/

RUN mv /tmp/ssh_config ~/.ssh/config && \
    mv /tmp/hadoop-env.sh /usr/local/hadoop/etc/hadoop/hadoop-env.sh && \
    mv /tmp/hdfs-site.xml $HADOOP_HOME/etc/hadoop/hdfs-site.xml && \ 
    mv /tmp/core-site.xml $HADOOP_HOME/etc/hadoop/core-site.xml && \
    mv /tmp/mapred-site.xml $HADOOP_HOME/etc/hadoop/mapred-site.xml && \
    mv /tmp/yarn-site.xml $HADOOP_HOME/etc/hadoop/yarn-site.xml && \
    mv /tmp/slaves $HADOOP_HOME/etc/hadoop/slaves && \
    mv /tmp/start_hadoop.sh ~/start_hadoop.sh && \
    mv /tmp/stop_hadoop.sh ~/stop_hadoop.sh && \
    mv /tmp/run_wordcount.sh ~/run_wordcount.sh

RUN chmod +x ~/*.sh && \
    chmod +x $HADOOP_HOME/sbin/*.sh 

# format namenode
RUN /usr/local/hadoop/bin/hdfs namenode -format

RUN echo '\
export JAVA_HOME=/usr/java/default \n\
export PATH=${JAVA_HOME}/bin:${PATH} \n\
export HADOOP_CLASSPATH=export HADOOP_CLASSPATH=/usr/lib/jvm/java-7-openjdk-amd64/lib/tools.jar \n\
' >> ~/.bashrc 

RUN mkdir /root/src/
VOLUME /root/src/

CMD [ "sh", "-c", "service ssh start; bash"]

