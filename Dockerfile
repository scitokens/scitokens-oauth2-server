FROM centos:7
ENV container docker
RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == \
systemd-tmpfiles-setup.service ] || rm -f $i; done); \
rm -f /lib/systemd/system/multi-user.target.wants/*;\
rm -f /etc/systemd/system/*.wants/*;\
rm -f /lib/systemd/system/local-fs.target.wants/*; \
rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
rm -f /lib/systemd/system/basic.target.wants/*;\
rm -f /lib/systemd/system/anaconda.target.wants/*;
VOLUME [ "/sys/fs/cgroup" ]

RUN yum install -y curl java-11-openjdk java-11-openjdk-devel openssl-devel apr-devel gcc gcc-c++ make
RUN alternatives --set java /usr/lib/jvm/java-11-openjdk-11.0.4.11-1.el7_7.x86_64/bin/java ;\
alternatives --set javac /usr/lib/jvm/java-11-openjdk-11.0.4.11-1.el7_7.x86_64/bin/javac

RUN useradd -r -s /sbin/nologin tomcat ;\
mkdir -p /opt/tomcat ;\
curl -s -L https://archive.apache.org/dist/tomcat/tomcat-8/v8.5.45/bin/apache-tomcat-8.5.45.tar.gz | tar -zxf - -C /opt/tomcat --strip-components=1 ;\
chgrp -R tomcat /opt/tomcat/conf ;\
chmod g+rwx /opt/tomcat/conf ;\
chmod g+r /opt/tomcat/conf/* ;\
chown -R tomcat /opt/tomcat/logs/ /opt/tomcat/temp/ /opt/tomcat/webapps/ /opt/tomcat/work/ ;\
chgrp -R tomcat /opt/tomcat/bin /opt/tomcat/lib ;\
chmod g+rwx /opt/tomcat/bin ;\
chmod g+r /opt/tomcat/bin/*

RUN cd /opt/tomcat/bin ;\
tar -zxvf tomcat-native.tar.gz ;\
cd tomcat-native-1.2.23-src/native ;\
ls -ald /usr/lib/jvm/java-11-openjdk-11.0.4.11-1.el7_7.x86_64/ ;\
ls -al /usr/lib/jvm/java-11-openjdk-11.0.4.11-1.el7_7.x86_64/ ;\
./configure --with-apr=/usr/bin/apr-1-config --with-java-home=/usr/lib/jvm/java-11-openjdk-11.0.4.11-1.el7_7.x86_64 --with-os-type=include/linux --with-ssl=yes --prefix=/opt/tomcat ;\
mv Makefile Makefile.org ;\
sed s+/include/include/linux+/include/linux+g Makefile.org > Makefile ;\
make ;\
make install ;\
chgrp -R tomcat /opt/tomcat/lib ;\
rm -f /opt/tomcat/conf/server.xml

ADD server.xml /opt/tomcat/conf/server.xml
RUN chgrp -R tomcat /opt/tomcat/conf/server.xml ;\
chmod go+r /opt/tomcat/conf/server.xml

ADD CA-bundle.pem /opt/tomcat/conf/CA-bundle.pem
ADD hostcert.pem /opt/tomcat/conf/hostcert.pem
ADD hostkey.pem /opt/tomcat/conf/hostkey.pem
RUN chgrp tomcat /opt/tomcat/conf/CA-bundle.pem /opt/tomcat/conf/hostcert.pem /opt/tomcat/conf/hostkey.pem ;\
chmod g+r /opt/tomcat/conf/hostkey.pem

ARG TOMCAT_ADMIN_USERNAME
ARG TOMCAT_ADMIN_PASSWORD
ENV TOMCAT_ADMIN_USERNAME ${TOMCAT_ADMIN_USERNAME:-admin}
ENV TOMCAT_ADMIN_PASSWORD ${TOMCAT_ADMIN_PASSWORD:-password}
ADD tomcat-users.xml.tmpl /opt/tomcat/conf/tomcat-users.xml.tmpl
RUN sed s+TOMCAT_ADMIN_USERNAME+${TOMCAT_ADMIN_USERNAME}+g /opt/tomcat/conf/tomcat-users.xml.tmpl | sed s+TOMCAT_ADMIN_PASSWORD+${TOMCAT_ADMIN_PASSWORD}+g > /opt/tomcat/conf/tomcat-users.xml ;\
chgrp tomcat /opt/tomcat/conf/tomcat-users.xml

ARG TOMCAT_ADMIN_IP
ENV TOMCAT_ADMIN_IP ${TOMCAT_ADMIN_IP:-127.0.0.1}
ADD manager.xml.tmpl /opt/tomcat/conf/Catalina/localhost/manager.xml.tmpl
RUN sed s+TOMCAT_ADMIN_IP+${TOMCAT_ADMIN_IP}+g /opt/tomcat/conf/Catalina/localhost/manager.xml.tmpl > /opt/tomcat/conf/Catalina/localhost/manager.xml ;\
chgrp -R tomcat  /opt/tomcat/conf/Catalina

ADD tomcat.service /etc/systemd/system/tomcat.service
RUN systemctl enable tomcat.service

RUN curl -s -L https://github.com/scitokens/scitokens-java/releases/download/v.1.2a-1/scitokens-server.war > /opt/tomcat/webapps/scitokens-server.war ;\
mkdir -p /opt/tomcat/webapps/scitokens-server ;\
chown tomcat:tomcat /opt/tomcat/webapps/scitokens-server ;\
cd /opt/tomcat/webapps/scitokens-server ;\
jar -xvf ../scitokens-server.war ;\
mkdir -p /opt/scitokens-server/config /opt/scitokens-server/keys /opt/scitokens-server/logs ;\
chgrp -R tomcat /opt/scitokens-server ;\
mkdir -p /opt/tomcat/var/storage/scitokens-server ;\
chown -R tomcat:tomcat /opt/tomcat/var/storage/scitokens-server

ADD scitokens-server/web.xml /opt/tomcat/webapps/scitokens-server/WEB-INF/web.xml
RUN chown tomcat:tomcat /opt/tomcat/webapps/scitokens-server/WEB-INF/web.xml

RUN yum install -y java-1.8.0-openjdk.x86_64
RUN cd /opt/scitokens-server/keys ;\
curl -s -L https://github.com/scitokens/scitokens-java/releases/download/v.1.2a/scitokens-util.jar > scitokens-util.jar ;\
/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.222.b10-1.el7_7.x86_64/jre/bin/java -jar scitokens-util.jar -batch create_keys /opt/scitokens-server/keys/scitokens.jwk ;\
chgrp tomcat /opt/scitokens-server/keys/scitokens.jwk ;\
chmod 640 /opt/scitokens-server/keys/scitokens.jwk ;\
export KID=$(grep kid /opt/scitokens-server/keys/scitokens.jwk | awk -F : 'NR==1{print $2};' | tr -d '", ')

ARG SCITOKENS_SERVER_ADDRESS
ENV SCITOKENS_SERVER_ADDRESS ${SCITOKENS_SERVER_ADDRESS:-127.0.0.1:8443}
RUN curl -L -s https://github.com/scitokens/scitokens-java/releases/download/v.1.2a/server-config.xml > /opt/scitokens-server/config/server-config.xml.tmpl
RUN sed s+oa4mp:scitokens.fileStore+scitokens-server+g /opt/scitokens-server/config/server-config.xml.tmpl | \
  sed s+address.of.your.server+${SCITOKENS_SERVER_ADDRESS}+g | \
  sed s+/path/to/log/file+/opt/tomcat/logs/scitokens-server.log+g | \
  sed s+ID_GOES_HERE+${KID}+g | sed s+/PATH/TO/JSON_WEBKEY_FILE+/opt/scitokens-server/keys/scitokens.jwk+g | \
  sed s+/opt/oa2/var/storage/scitokens-erver+/opt/tomcat/var/storage/scitokens-server+g | \
  sed 's+mail enabled="true"+mail enabled="false"+g' > /opt/scitokens-server/config/server-config.xml ;\
chgrp tomcat /opt/scitokens-server/config/server-config.xml

RUN mkdir -p /opt/scitokens-server/bin ;\
curl -s -L https://github.com/scitokens/scitokens-java/releases/download/v.1.2a-1/scitokens-cli.jar > /opt/scitokens-server/bin/scitokens-cli.jar ;\
echo "#/bin/bash" > /opt/scitokens-server/bin/scitokens-cli ;\
echo "java -jar /opt/scitokens-server/bin/scitokens-cli.jar -cfg /opt/scitokens-server/config/server-config.xml -name scitokens-server" >> /opt/scitokens-server/bin/scitokens-cli ;\
chmod +x /opt/scitokens-server/bin/scitokens-cli

CMD ["/usr/sbin/init"]
