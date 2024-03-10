# [betothreeprod/mysqldb](https://github.com/b23prodtm/acake2php/tree/development/deployment/images/mysqldb)

The architectures supported by this image are:

| Architecture | repo |
| :----: | --- |
| x86-64 | [betothreeprod/mariadb-intel-nuc](https://hub.docker.com/r/betothreeprod/mariadb-intel-nuc) |
| arm64 | betothreeprod/mariadb-raspberrypi3-64 |
| armhf | [betothreeprod/mariadb-raspberrypi3](https://hub.docker.com/r/betothreeprod/mariadb-raspberrypi3) |


## Usage

Here are some example snippets to help you get started creating a container.

### docker

```
docker create \
  --name=mariadb \
  -e PUID=UID \
  -e PGID=GUID \
  -e MYSQL_ROOT_PASSWORD=ROOT_ACCESS_PASSWORD \
  -e TZ=Europe/London \
  -e MYSQL_DATABASE=USER_DB_NAME \
  -e MYSQL_USER=MYSQL_USER \
  -e MYSQL_PASSWORD=DATABASE_PASSWORD \			
	-e MYSQL_HOST=EXTERNAL_IP_ADDRESS `#optional` \
  -e REMOTE_SQL=http://URL1/your.sql,https://URL2/your.sql `#optional` \
  -p 3306:3306 \
  -v path_to_data:/config \
  --restart unless-stopped \
  linuxserver/mariadb
```


### docker-compose

Compatible with docker-compose v2 schemas.

```
---
version: "2"
services:
  mariadb:
    image: betothreeprod/mariadb-%%BALENA_MACHINE_NAME%%
    container_name: mariadb
    environment:
      - PUID=UID
      - PGID=GUID
      - MYSQL_ROOT_PASSWORD=ROOT_ACCESS_PASSWORD
      - TZ=Europe/London
			- MYSQL_DATABASE=USER_DB_NAME
      - MYSQL_USER=MYSQL_USER
      - MYSQL_PASSWORD=DATABASE_PASSWORD			
			- MYSQL_HOST=EXTERNAL_IP_ADDRESS #optional
      - REMOTE_SQL=http://URL1/your.sql,https://URL2/your.sql #optional
    volumes:
      - path_to_data:/config
    ports:
      - 3306:3306
    restart: unless-stopped
```

> %%BALENA_MACHINE_NAME%% it's the template variable for the host system name from [Balena OS reference](https://www.balena.io/docs/reference/base-images/base-images-ref/).
## User / Group Identifiers

When using volumes (`-v` flags) permissions issues can arise between the host OS and the container, we avoid this issue by allowing you to specify the user `PUID` and group `PGID`.

Ensure any volume directories on the host are owned by the same user you specify and any permissions issues will vanish like magic.

In this instance `PUID=UID` and `PGID=GUID`, to find it, you use `id user` as below:

```
  $ id $USER
    uid=1000(thedockeruser) gid=1000(thedockergroup) groups=1000(thedockergroup)
```
If docker's run by `root(0)`, it's the default behaviour, `PUID=0` and `GUID=0`.
