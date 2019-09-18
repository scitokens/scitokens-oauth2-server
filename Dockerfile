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

CMD ["/usr/sbin/init"]
