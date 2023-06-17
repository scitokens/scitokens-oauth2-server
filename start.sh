#!/bin/bash

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
    # Note that `-L` is added here; this is because Kubernetes sets up some volume mounts
    # as symlinks and `-r` will copy the symlinks (which then becomes broken).  `-L` will
    # dereference the symlink and copy the data, which is what we want.
    cp -rL /opt/scitokens-server/etc/qdl/*.qdl /opt/scitokens-server/var/qdl/scitokens/
    chown -R tomcat /opt/scitokens-server/var/qdl/
fi

# Load up additional trust roots.  If OA4MP needs to contact a LDAP server, we will need
# the CA that signed the LDAP server's certificate to be in the java trust store.
if [ -e /opt/scitokens-server/etc/trusted-cas ]; then

    shopt -s nullglob
    for fullfile in /opt/scitokens-server/etc/trusted-cas/*.pem; do
        aliasname=$(basename "$file")
        aliasname="${filename%.*}"
        keytool -cacerts -importcert -noprompt -storepass changeit -file "$fullfile" -alias "$aliasname"
    done
    shopt -u nullglob

fi

# Start tomcat
exec /opt/tomcat/bin/catalina.sh run

