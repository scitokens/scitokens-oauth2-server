# Scitokens Server Docker Image

```sh
docker build \
  --build-arg TOMCAT_ADMIN_USERNAME=admin \
  --build-arg TOMCAT_ADMIN_PASSWORD=password \
  --build-arg TOMCAT_ADMIN_IP=127.0.0.1 \
  --rm -t local/c7-systemd .
```

```sh
docker-compose up --detach
```
