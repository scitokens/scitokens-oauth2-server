#!/bin/sh

# Set the hostname
sed s+\{HOSTNAME\}+$HOSTNAME+g /opt/scitokens-server/etc/server-config.xml.tmpl > /opt/scitokens-server/etc/server-config.xml
sed s+\{HOSTNAME\}+$HOSTNAME+g /opt/scitokens-server/etc/proxy-config.xml.tmpl | \
sed s+\{CLIENT_ID\}+$CLIENT_ID+g | \
sed s+\{CLIENT_SECRET\}+$CLIENT_SECRET+g > /opt/scitokens-server/etc/proxy-config.xml
chgrp tomcat /opt/scitokens-server/etc/server-config.xml
chgrp tomcat /opt/scitokens-server/etc/proxy-config.xml

# Run the boot to inject the template
${QDL_HOME}/var/scripts/boot.qdl

# Check for the JWKS key
if [ ! -e /opt/scitokens-server/etc/keys.jwk ]; then
    echo "Please provide a JWKS key in the file /opt/scitokens-server/etc/keys.jwk.  Please generate it with the following command:"
    echo "sudo docker run --rm  hub.opensciencegrid.org/sciauth/lightweight-token-issuer generate_jwk.sh > keys.jwk"
    echo "And volume mount the keys.jwk to /opt/scitokens-server/etc/keys.jwk within the container."
    exit 1
fi

# check for one or more files in a directory
if [ -e /opt/scitokens-server/etc/qdl/ ]; then
    cp -r /opt/scitokens-server/etc/qdl/*.qdl /opt/scitokens-server/var/qdl/scitokens/
    chown -R tomcat /opt/scitokens-server/var/qdl/
fi

# Start tomcat
exec /opt/tomcat/bin/catalina.sh run

