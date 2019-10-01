# Scitokens Server Docker Image

Make sure you have a `hostcert.pem` and a `hostkey.pem` in this directory and
then build the docker image with

```sh
docker build \
  --build-arg TOMCAT_ADMIN_USERNAME=admin \
  --build-arg TOMCAT_ADMIN_PASSWORD=password \
  --build-arg TOMCAT_ADMIN_IP=127.0.0.1 \
  --build-arg SCITOKENS_SERVER_ADDRESS=127.0.0.1:8443
  --rm -t scitokens/c7-token-server .
```

To also install the client, add `--build-arg INSTALL_SCITOKENS_CLIENT=true`

Start the image with

```sh
docker-compose up --detach
```

Approve a client
```sh
docker exec -it server-base_scitokens-tomcat_1 /opt/scitokens-server/bin/scitokens-cli
```

```
*************************************************************
* OA4MP2 OAuth 2/OIDC CLI (Command Line Interpreter)        *
* Version 4.2-SNAPSHOT                                      *
* By Jeff Gaynor  NCSA                                      *
*  (National Center for Supercomputing Applications)        *
*                                                           *
* type 'help' for a list of commands                        *
*      'exit' or 'quit' to end this session.                *
*************************************************************
OAuth 2 for MyProxy, version 4.2-SNAPSHOT startup on Wed Sep 25 18:11:48 UTC 2019
Store contains 1 entries.
cli>use clients
Store contains 1 entries.
  clients >ls
  0. (N) myproxy:oa4mp,2012:/client_id/193465d162e66dbfd8fffd79fb903e9e (sugwg-scitokens-cond...) created on 2019-09-25T18:09:01.393Z
  clients >approve /myproxy:oa4mp,2012:/client_id/193465d162e66dbfd8fffd79fb903e9e
    approver[(null)]:duncan
    set approved?[n]:y
    save this approval record [y/n]?y
    approval saved
  clients >exit
exiting ...
cli>exit
exiting ...
```
