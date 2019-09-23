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
