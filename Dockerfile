FROM centos:7
ENV container docker
#RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == \
#systemd-tmpfiles-setup.service ] || rm -f $i; done); \
#rm -f /lib/systemd/system/multi-user.target.wants/*;\
#rm -f /etc/systemd/system/*.wants/*;\
#rm -f /lib/systemd/system/local-fs.target.wants/*; \
#rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
#rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
#rm -f /lib/systemd/system/basic.target.wants/*;\
#rm -f /lib/systemd/system/anaconda.target.wants/*;
#VOLUME [ "/sys/fs/cgroup" ]

RUN yum install -y curl java-11-openjdk java-11-openjdk-devel openssl-devel apr-devel gcc gcc-c++ make
#RUN alternatives --set java /usr/lib/jvm/java-11-openjdk/bin/java && \
#alternatives --set javac /usr/lib/jvm/java-11-openjdk/bin/javac

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
ls -ald /usr/lib/jvm/java-11-openjdk-11.0.8.10-0.el7_8.x86_64/ ;\
ls -al /usr/lib/jvm/java-11-openjdk-11.0.8.10-0.el7_8.x86_64/ ;\
./configure --with-apr=/usr/bin/apr-1-config --with-java-home=/usr/lib/jvm/java-11-openjdk-11.0.8.10-0.el7_8.x86_64 --with-os-type=include/linux --with-ssl=yes --prefix=/opt/tomcat ;\
mv Makefile Makefile.org ;\
sed s+/include/include/linux+/include/linux+g Makefile.org > Makefile ;\
make ;\
make install ;\
chgrp -R tomcat /opt/tomcat/lib ;\
rm -f /opt/tomcat/conf/server.xml

ADD server.xml /opt/tomcat/conf/server.xml
RUN chgrp -R tomcat /opt/tomcat/conf/server.xml ;\
chmod go+r /opt/tomcat/conf/server.xml

ADD add-trust-root.pem /opt/tomcat/conf/add-trust-root.pem
ADD comodo-rsa.pem /opt/tomcat/conf/comodo-rsa.pem
ADD incommon-igtf.pem /opt/tomcat/conf/incommon-igtf.pem
RUN cat /opt/tomcat/conf/incommon-igtf.pem /opt/tomcat/conf/comodo-rsa.pem /opt/tomcat/conf/add-trust-root.pem > /opt/tomcat/conf/CA-bundle.pem && \
    keytool -cacerts -importcert -noprompt -storepass changeit -file /opt/tomcat/conf/incommon-igtf.pem -alias incommon && \
    keytool -cacerts -importcert -noprompt -storepass changeit -file /opt/tomcat/conf/comodo-rsa.pem -alias comodo && \
    keytool -cacerts -importcert -noprompt -storepass changeit -file /opt/tomcat/conf/add-trust-root.pem -alias addtrust

# Change into volume mount
ADD hostcert.pem /opt/tomcat/conf/hostcert.pem
ADD hostkey.pem /opt/tomcat/conf/hostkey.pem
RUN chgrp tomcat /opt/tomcat/conf/CA-bundle.pem /opt/tomcat/conf/hostcert.pem /opt/tomcat/conf/hostkey.pem ;\
chmod g+r /opt/tomcat/conf/hostkey.pem

ARG TOMCAT_ADMIN_USERNAME=admin
ARG TOMCAT_ADMIN_PASSWORD=password
ADD tomcat-users.xml.tmpl /opt/tomcat/conf/tomcat-users.xml.tmpl
RUN sed s+TOMCAT_ADMIN_USERNAME+${TOMCAT_ADMIN_USERNAME}+g /opt/tomcat/conf/tomcat-users.xml.tmpl | sed s+TOMCAT_ADMIN_PASSWORD+${TOMCAT_ADMIN_PASSWORD}+g > /opt/tomcat/conf/tomcat-users.xml ;\
chgrp tomcat /opt/tomcat/conf/tomcat-users.xml

ARG TOMCAT_ADMIN_IP=127.0.0.1
ADD manager.xml.tmpl /opt/tomcat/conf/Catalina/localhost/manager.xml.tmpl
RUN sed s+TOMCAT_ADMIN_IP+${TOMCAT_ADMIN_IP}+g /opt/tomcat/conf/Catalina/localhost/manager.xml.tmpl > /opt/tomcat/conf/Catalina/localhost/manager.xml ;\
chgrp -R tomcat  /opt/tomcat/conf/Catalina

#ADD tomcat.service /etc/systemd/system/tomcat.service
#RUN systemctl enable tomcat.service

COPY --chown=tomcat:tomcat scitokens-server /opt
RUN curl -s -L https://github.com/ncsa/OA4MP/releases/download/5.2.0/oauth2.war > /opt/tomcat/webapps/scitokens-server.war ;\
mkdir -p /opt/tomcat/webapps/scitokens-server ;\
cd /opt/tomcat/webapps/scitokens-server ;\
jar -xf ../scitokens-server.war ;\
chgrp -R tomcat /opt/tomcat/webapps/scitokens-server ;\
mkdir -p /opt/tomcat/var/storage/scitokens-server ;\
chown -R tomcat:tomcat /opt/tomcat/var/storage/scitokens-server
COPY --chown=tomcat:tomcat scitokens-server/web.xml /opt/tomcat/webapps/scitokens-server/WEB-INF/web.xml
RUN chmod 644 /opt/tomcat/webapps/scitokens-server/WEB-INF/web.xml

# Make JWK a volume mount
#RUN mkdir -p /opt/scitokens-java/scitokens-cli ;\
#curl -s -L https://github.com/ncsa/OA4MP/releases/download/5.2.1/jwt.jar > /opt/scitokens-java/scitokens-cli/scitokens-util.jar ;\
#java -jar /opt/scitokens-java/scitokens-cli/scitokens-util.jar -batch create_keys -out /opt/scitokens-server/etc/scitokens.jwk ;\
#chgrp tomcat /opt/scitokens-server/etc/scitokens.jwk ;\
#chmod 640 /opt/scitokens-server/etc/scitokens.jwk

# Make server configuration a volume mount
ARG SCITOKENS_SERVER_ADDRESS=127.0.0.1:8443
ADD scitokens-server/etc/server-config.xml /opt/scitokens-server/etc/server-config.xml.tmpl
RUN sed s+oa4mp:scitokens.fileStore+scitokens-server+g /opt/scitokens-server/etc/server-config.xml.tmpl | \
  sed s+address.of.your.server+${SCITOKENS_SERVER_ADDRESS}+g | \
  sed s+/path/to/log/file+/opt/tomcat/logs/scitokens-server.log+g | \
#  sed s+ID_GOES_HERE+$(grep kid /opt/scitokens-server/etc/scitokens.jwk | awk -F : 'NR==1{print $2};' | tr -d '", ')+g | sed s+/PATH/TO/JSON_WEBKEY_FILE+/opt/scitokens-server/etc/scitokens.jwk+g | \
  sed s+/opt/oa2/var/storage/scitokens-erver+/opt/tomcat/var/storage/scitokens-server+g | \
  sed 's+mail enabled="true"+mail enabled="false"+g' > /opt/scitokens-server/etc/server-config.xml ;\
chgrp tomcat /opt/scitokens-server/etc/server-config.xml

RUN mkdir -p /opt/scitokens-server/bin ;\
curl -L -s https://github.com/ncsa/OA4MP/releases/download/5.2.1/oa2-cli.jar >/opt/scitokens-server/bin/scitokens-cli.jar ;\
echo "#!/bin/bash" > /opt/scitokens-server/bin/scitokens-cli ;\
echo "java -jar /opt/scitokens-server/bin/scitokens-cli.jar -cfg /opt/scitokens-server/config/server-config.xml -name scitokens-server" >> /opt/scitokens-server/bin/scitokens-cli ;\
chmod +x /opt/scitokens-server/bin/scitokens-cli

ARG INSTALL_SCITOKENS_CLIENT=false
RUN if [ "x${INSTALL_SCITOKENS_CLIENT}" == "xtrue" ] ; then echo "Installing scitokens client" >&2 ;\
curl -L -s https://github.com/scitokens/scitokens-java/releases/download/v1.2.1/scitokens-client.war > /opt/tomcat/webapps/scitokens-client.war ;\
mkdir -p /opt/tomcat/webapps/scitokens-client ;\
cd /opt/tomcat/webapps/scitokens-client ;\
jar -xf ../scitokens-client.war ;\
chgrp -R tomcat /opt/tomcat/webapps/scitokens-client ;\
fi
ADD scitokens-client/web.xml /opt/tomcat/webapps/scitokens-client/WEB-INF/web.xml
RUN if [ "x${INSTALL_SCITOKENS_CLIENT}" == "xtrue" ] ; then echo "Configuring scitokens client" >&2 ;\
chgrp tomcat /opt/tomcat/webapps/scitokens-client/WEB-INF/web.xml ;\
chmod 644 /opt/tomcat/webapps/scitokens-client/WEB-INF/web.xml ;\
mkdir -p /opt/scitokens-client/config ;\
curl -s -L https://raw.githubusercontent.com/scitokens/scitokens-java/master/scitokens-client/src/main/resources/sample-client-config.xml | \
  sed s+oa4mp:scitokens.fileStore+scitokens-client+g | \
  sed s+/path/to/logfile+/opt/tomcat/logs/scitokens-client.log+g | \
  sed s+address.of.the.server+${SCITOKENS_SERVER_ADDRESS}+g | \
  sed s+address.of.this.client+${SCITOKENS_SERVER_ADDRESS}+g | \
  sed s+/path/to/storage+/opt/scitokens-client/var/filestore+g > /opt/scitokens-client/config/client-config.xml ;\
mkdir -p /opt/scitokens-client/logs ;\
mkdir -p /opt/scitokens-client/var/filestore ;\
chgrp -R tomcat /opt/scitokens-client ;\
chmod g+w /opt/scitokens-client/logs /opt/scitokens-client/var/filestore ;\
else rm -rf /opt/tomcat/webapps/scitokens-client ;\
fi

RUN ln -s /usr/lib64/libapr-1.so.0 /opt/tomcat/lib/libapr-1.so.0

ADD generate_jwk.sh /usr/local/bin/generate_jwk.sh

#CMD ["/usr/sbin/ini"]
USER tomcat:tomcat

ENV JAVA_HOME=/usr/lib/jvm/jre
ENV CATALINA_PID=/opt/tomcat/temp/tomcat.pid
ENV CATALINA_HOME=/opt/tomcat
ENV CATALINA_BASE=/opt/tomcat
ENV CATALINA_OPTS="-Xms512M -Xmx1024M -server -XX:+UseParallelGC"
ENV JAVA_OPTS="-Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom -Djava.library.path=/opt/tomcat/lib"


CMD ["/opt/tomcat/bin/catalina.sh", "run"]



