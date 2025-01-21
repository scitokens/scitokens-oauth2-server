ARG BASE_OSG_SERIES=23
ARG BASE_OS=el9
ARG BASE_YUM_REPO=release

FROM hub.opensciencegrid.org/osg-htc/software-base:${BASE_OSG_SERIES}-${BASE_OS}-${BASE_YUM_REPO}

RUN <<ENDRUN
    # Ensure that errors cause the build to fail.
    set -eux
    set -o pipefail

    # Install Java 11.
    dnf install -y java-11-openjdk-headless java-11-openjdk-devel

    # Create the tomcat user with a fixed UID/GID.
    groupadd -g 10443 tomcat
    useradd -u 10443 -g 10443 -s /sbin/nologin tomcat

    # Download and install Tomcat.
    mkdir -p /opt/tomcat
    curl -s -L https://archive.apache.org/dist/tomcat/tomcat-9/v9.0.98/bin/apache-tomcat-9.0.98.tar.gz | tar -zxf - -C /opt/tomcat --strip-components=1

    # The Tomcat distribution archive cannot know the UID and GID for our
    # 'tomcat' user, so we need to explicitly set user and group ownership.
    chown -R  tomcat  /opt/tomcat/logs  /opt/tomcat/temp  /opt/tomcat/webapps  /opt/tomcat/work
    chgrp -R  tomcat  /opt/tomcat/bin   /opt/tomcat/conf  /opt/tomcat/lib
    chmod     g+rwx   /opt/tomcat/bin   /opt/tomcat/conf  /opt/tomcat/lib
    chmod -R  g+rX    /opt/tomcat/bin   /opt/tomcat/conf  /opt/tomcat/lib

    ln -s /usr/lib64/libapr-1.so.0 /opt/tomcat/lib/libapr-1.so.0

    # Create various empty directories needed by the webapp.
    mkdir -p /opt/scitokens-server/etc/trusted-cas
    mkdir -p /opt/scitokens-server/lib
    mkdir -p /opt/scitokens-server/log
    mkdir -p /opt/scitokens-server/var/storage/file_store
    mkdir -p /opt/tomcat/webapps/scitokens-server
    chown tomcat:tomcat /opt/scitokens-server/var/storage/file_store

    # Install the OA4MP webapp and associated dependencies.
    curl -s -L https://github.com/ncsa/OA4MP/releases/download/v6.0.3/oauth2.war > /opt/tomcat/webapps/scitokens-server.war
    curl -s -L https://github.com/ncsa/OA4MP/releases/download/v6.0.3/jwt.jar > /opt/scitokens-server/lib/jwt.jar
    curl -s -L https://github.com/ncsa/OA4MP/releases/download/v6.0.3/cli.jar > /opt/scitokens-server/lib/scitokens-cli.jar
    curl -s -L https://github.com/javaee/javamail/releases/download/JAVAMAIL-1_6_2/javax.mail.jar > /opt/tomcat/lib/javax.mail.jar

    ( cd /opt/tomcat/webapps/scitokens-server && jar -xf /opt/tomcat/webapps/scitokens-server.war )
    rm /opt/tomcat/webapps/scitokens-server.war

    chgrp -R tomcat /opt/tomcat/webapps/scitokens-server
    mkdir -p /opt/tomcat/var/storage/scitokens-server
    chown -R tomcat:tomcat /opt/tomcat/var/storage/scitokens-server

    # Install support for the QDL CLI.
    curl -s -L https://github.com/ncsa/OA4MP/releases/download/v6.0.3/qdl-installer.jar >/tmp/oa2-qdl-installer.jar
    java -jar /tmp/oa2-qdl-installer.jar install -all -dir /opt/qdl
    rm /tmp/oa2-qdl-installer.jar
    mkdir -p /opt/qdl/var/scripts

    # Remove Tomcat's default manager apps and examples.
    rm -rf /opt/tomcat/webapps/ROOT /opt/tomcat/webapps/docs /opt/tomcat/webapps/examples /opt/tomcat/webapps/host-manager /opt/tomcat/webapps/manager

    # Remove packages that were needed only for this build step.
    dnf remove -y java-11-openjdk-devel
    dnf clean all
    rm -rf /var/cache/dnf/*
ENDRUN

# The generate_jwk.sh script is part of the documented bootstrap of the container.
ADD generate_jwk.sh /usr/local/bin/generate_jwk.sh

# Add other QDL CLI tools and configs not part of the default installer.
COPY qdl /opt/qdl

# Add in the Tomcat server configuration.
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
