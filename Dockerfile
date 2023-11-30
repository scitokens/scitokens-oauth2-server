FROM hub.opensciencegrid.org/opensciencegrid/software-base:3.6-al8-release

RUN yum install -y curl java-11-openjdk-headless java-11-openjdk-devel

# Download and install tomcat
RUN useradd -r -s /sbin/nologin tomcat ;\
    mkdir -p /opt/tomcat ;\
    curl -s -L https://archive.apache.org/dist/tomcat/tomcat-9/v9.0.83/bin/apache-tomcat-9.0.83.tar.gz | tar -zxf - -C /opt/tomcat --strip-components=1 ;\
    chgrp -R tomcat /opt/tomcat/conf ;\
    chmod g+rwx /opt/tomcat/conf ;\
    chmod g+r /opt/tomcat/conf/* ;\
    chown -R tomcat /opt/tomcat/logs/ /opt/tomcat/temp/ /opt/tomcat/webapps/ /opt/tomcat/work/ ;\
    chgrp -R tomcat /opt/tomcat/bin /opt/tomcat/lib ;\
    chmod g+rwx /opt/tomcat/bin ;\
    chmod g+r /opt/tomcat/bin/* ;\
    ln -s /usr/lib64/libapr-1.so.0 /opt/tomcat/lib/libapr-1.so.0

RUN \
    # Create various empty directories needed by the webapp
    mkdir -p /opt/scitokens-server/etc/trusted-cas &&\
    mkdir -p /opt/scitokens-server/lib &&\
    mkdir -p /opt/scitokens-server/log &&\
    mkdir -p /opt/scitokens-server/var/storage/file_store &&\
    mkdir -p /opt/tomcat/webapps/scitokens-server ;\
    # Install the OA4MP webapp and associated dependencies.
    curl -s -L https://github.com/ncsa/OA4MP/releases/download/v5.4.1/oauth2.war > /opt/tomcat/webapps/scitokens-server.war ;\
    curl -s -L https://github.com/javaee/javamail/releases/download/JAVAMAIL-1_6_2/javax.mail.jar > /opt/tomcat/lib/javax.mail.jar ;\
    curl -s -L https://github.com/ncsa/OA4MP/releases/download/v5.4.1/jwt.jar > /opt/scitokens-server/lib/jwt.jar ;\
    curl -L -s https://github.com/ncsa/OA4MP/releases/download/v5.4.1/cli.jar > /opt/scitokens-server/lib/scitokens-cli.jar ;\
    cd /opt/tomcat/webapps/scitokens-server ;\
    jar -xf ../scitokens-server.war ;\
    chgrp -R tomcat /opt/tomcat/webapps/scitokens-server ;\
    mkdir -p /opt/tomcat/var/storage/scitokens-server ;\
    chown -R tomcat:tomcat /opt/tomcat/var/storage/scitokens-server ;\
    # Install support for the QDL CLI
    curl -L -s https://github.com/ncsa/OA4MP/releases/download/v5.4.1/qdl-installer.jar >/tmp/oa2-qdl-installer.jar ;\
    java -jar /tmp/oa2-qdl-installer.jar -dir /opt/qdl ;\
    rm /tmp/oa2-qdl-installer.jar ;\
    mkdir -p /opt/qdl/var/scripts ;\
    # Remove the default manager apps and examples -- we don't use these
    rm -rf /opt/tomcat/webapps/ROOT /opt/tomcat/webapps/docs /opt/tomcat/webapps/examples /opt/tomcat/webapps/host-manager /opt/tomcat/webapps/manager ;\
    true;

# The generate_jwk.sh script is part of the documented bootstrap of the container.
ADD generate_jwk.sh /usr/local/bin/generate_jwk.sh

# Add other QDL CLI tools and configs not part of the default installer
COPY qdl /opt/qdl

# Add in the tomcat server configuration
ADD --chown=root:tomcat server.xml /opt/tomcat/conf/server.xml

# Copy over our configuration of the OA4MP webapp.
COPY --chown=tomcat:tomcat scitokens-server/web.xml /opt/tomcat/webapps/scitokens-server/WEB-INF/web.xml
COPY --chown=tomcat:tomcat scitokens-server/ /opt/scitokens-server/

ENV JAVA_HOME=/usr/lib/jvm/jre \
    CATALINA_PID=/opt/tomcat/temp/tomcat.pid \
    CATALINA_HOME=/opt/tomcat \
    CATALINA_BASE=/opt/tomcat \
    CATALINA_OPTS="-Xms512M -Xmx1024M -server -XX:+UseParallelGC" \
    JAVA_OPTS="-Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom -Djava.library.path=/opt/tomcat/lib" \
    ST_HOME="/opt/scitokens-server" \
    QDL_HOME="/opt/qdl" \
    PATH="${ST_HOME}/bin:${QDL_HOME}/bin:${PATH}"

ADD start.sh /start.sh
CMD ["/start.sh"]
