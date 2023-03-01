# Scitokens Server Docker Image

This repository contains a Docker image to install the Scitokens Lightweight Issuer based on the [SciTokens Java
Server](https://github.com/scitokens/scitokens-java).  The issuer facilitates users to acquire tokens which can be used to authenticate with other services.



The image is hosted on the OSG hub [lightweight-token-issuer](https://hub.opensciencegrid.org/harbor/projects/613/repositories/lightweight-token-issuer?publicAndNotLogged=yes)


## Prerequisites

For the lightweight token issuer to function, it needs:

- Docker installed
- Host Certificates to enable TLS (HTTPS) connections
- JSON Web Keys for the issuer
- Issuer policy file
- Registered client with CILogon

### Host Certificates

Host certificates secure the communication between the client and this issuer.  The easiest way to retrieve host certificates is to acquire them from letsencrypt.  This tutorial is adapted from [Digital Ocean's](https://www.digitalocean.com/community/tutorials/how-to-use-certbot-standalone-mode-to-retrieve-let-s-encrypt-ssl-certificates-on-centos-7) tutorial for CentOS 7.

Install the certbot tool:

    $ sudo yum --enablerepo=extras install epel-release
    $ sudo yum install certbot

Confirm that certbot is installed:

    $ certbot --version
    certbot 1.11.0

**NOTE:** Certbot must be able to listen on port 80 to external connections.  The firewall must be open on port 80 to successfully receive a certificate. 

Request the certificate challenges:

    $ sudo certbot certonly --standalone --preferred-challenges http -d example.com

Where `example.com` is replaced with the full hostname of your host.  Once you have run the command, it will prompt you for your email and a few other questions.  Once it is complete, it should tell you where the host certificates are stored, usually under `/etc/letsencrypt/live/*`


### JSON Web Keys

The JSON web keys are used to sign tokens issued by the issuer.  They are generated from the docker container.  You will only need to keep these keys saved.

    $ sudo docker run --rm  hub.opensciencegrid.org/sciauth/lightweight-token-issuer generate_jwk.sh > keys.jwk

If this is the first time running the lightweight token issuer container, it may take some time to download and extract the container.  Once completed, the jwks.json should be populated with the keys.  Save those keys, as you will need them when running the issuer.

### Configuring permissions

    curl -O https://raw.githubusercontent.com/scitokens/docker-scitokens-java/master/scitokens-server/var/qdl/user-config.json

## Starting the image





