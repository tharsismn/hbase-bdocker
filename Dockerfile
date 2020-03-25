FROM centos:centos7

ARG HBASE_WDIR=/opt/hbase
ARG JAVA_V=1.8.0
ARG HBASE_V=2.1.5
#UPDATE CENTOS REPO
RUN yum -y update && \
    yum -y clean all && \
    yum -y repolist && \
    yum -y install openssh-server openssh-clients java-${JAVA_V}-openjdk java-${JAVA_V}-openjdk-devel 

ENV JAVA_HOME /usr/lib/jvm/java-${JAVA_V}

#CREATE PATHS TO INSTALL HBASE AND STORE DATA
RUN mkdir -p /opt/hbase
RUN mkdir -p /data/hbase
RUN mkdir -p /data/zookeeper
WORKDIR ${HBASE_WDIR}

#DOWNLOAD HBASE VERSION
#COPY hbase-${HBASE_V}-bin.tar.gz .
#RUN wget http://archive.apache.org/dist/hbase/${HBASE_V}/hbase-${HBASE_V}-bin.tar.gz .
RUN curl http://archive.apache.org/dist/hbase/${HBASE_V}/hbase-${HBASE_V}-bin.tar.gz --output hbase-${HBASE_V}-bin.tar.gz

#CREATE RSA AND DSA KEYS
RUN mkdir -p /root/.ssh && \
	ssh-keygen -q -t rsa -N '' -f /root/.ssh/id_rsa && \
	ssh-keygen -q -t dsa -N '' -f /etc/ssh/ssh_host_dsa_key && \
	ssh-keygen -q -t rsa -N '' -f /etc/ssh/ssh_host_rsa_key && \
	ssh-keygen -q -t ecdsa -N '' -f /etc/ssh/ssh_host_ecdsa_key && \
	ssh-keygen -q -t ed25519 -N '' -f /etc/ssh/ssh_host_ed25519_key && \
	cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys && \
	cat /etc/ssh/ssh_host_rsa_key.pub >> /root/.ssh/authorized_keys && \
	chmod 600 /root/.ssh/authorized_keys

#CONFIG TO RUN SSH WITHOU PASSWORD
RUN mkdir -p /var/run/sshd
#ROOT LOGIN WITHOUT PASSWORD // NO CHECK HOST // WITHOUT KNOWHOST FILE
RUN set -i 's/#PermitRootLogin yes/PermitRootLogin without-password/' /etc/ssh/sshd_config
RUN echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config
RUN echo "UserKnownHostsFile /dev/null" >> /etc/ssh/ssh_config
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

#INSTALL HBASE
RUN tar -zxvf hbase-${HBASE_V}-bin.tar.gz
COPY hbase-site.xml hbase-${HBASE_V}/conf
COPY hbase-env.sh hbase-${HBASE_V}/conf

RUN rm -rf hbase-${HBASE_V}-bin.tar.gz
ENV PATH $PATH:/opt/hbase/hbase-${HBASE_V}/bin

#COPY SCRIPT TO START SSHD AND HBASE
COPY start-all.sh .
RUN chmod +x start-all.sh
ENTRYPOINT ["/opt/hbase/start-all.sh"]

ENV LANG=en_US.UTF-8

#SSH PORT
EXPOSE 22
