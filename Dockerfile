FROM ubuntu

LABEL maintainer "toastY"

RUN apt-get -y update \
  && apt-get -y install \
  curl wget \
  git \
  rsync \
  unzip \
  default-jre \
  dos2unix \
  jq \
  gosu \
  lsof \
  imagemagick \
  mysql-client \
  tzdata \
  nano

HEALTHCHECK --start-period=1m CMD mc-monitor status --host localhost --port $SERVER_PORT

RUN groupadd -g 1000 minecraft \
  && useradd -s /bin/false -u 1000 -g minecraft -d /home/minecraft minecraft \
  && mkdir -m 777 /data /mods /config /plugins /home/minecraft \
  && chown minecraft:minecraft /data /config /mods /plugins /home/minecraft \
  && git config --global --unset core.autocrlf; exit 0

EXPOSE 25565 25575

# hook into docker BuildKit --platform support
# see https://docs.docker.com/engine/reference/builder/#automatic-platform-args-in-the-global-scope
ARG TARGETOS=linux
ARG TARGETARCH=arm64
ARG TARGETVARIANT=""

ARG EASY_ADD_VER=0.7.0
ADD https://github.com/itzg/easy-add/releases/download/${EASY_ADD_VER}/easy-add_${TARGETOS}_${TARGETARCH}${TARGETVARIANT} /usr/bin/easy-add
RUN chmod +x /usr/bin/easy-add

RUN easy-add --var os=${TARGETOS} --var arch=${TARGETARCH}${TARGETVARIANT} \
  --var version=1.2.0 --var app=restify --file {{.app}} \
  --from https://github.com/itzg/{{.app}}/releases/download/{{.version}}/{{.app}}_{{.version}}_{{.os}}_{{.arch}}.tar.gz

RUN easy-add --var os=${TARGETOS} --var arch=${TARGETARCH}${TARGETVARIANT} \
 --var version=1.4.7 --var app=rcon-cli --file {{.app}} \
 --from https://github.com/itzg/{{.app}}/releases/download/{{.version}}/{{.app}}_{{.version}}_{{.os}}_{{.arch}}.tar.gz

RUN easy-add --var os=${TARGETOS} --var arch=${TARGETARCH}${TARGETVARIANT} \
 --var version=0.1.7 --var app=mc-monitor --file {{.app}} \
 --from https://github.com/itzg/{{.app}}/releases/download/{{.version}}/{{.app}}_{{.version}}_{{.os}}_{{.arch}}.tar.gz

RUN easy-add --var os=${TARGETOS} --var arch=${TARGETARCH}${TARGETVARIANT} \
 --var version=1.3.3 --var app=mc-server-runner --file {{.app}} \
 --from https://github.com/itzg/{{.app}}/releases/download/{{.version}}/{{.app}}_{{.version}}_{{.os}}_{{.arch}}.tar.gz

RUN easy-add --var os=${TARGETOS} --var arch=${TARGETARCH}${TARGETVARIANT} \
 --var version=0.1.1 --var app=maven-metadata-release --file {{.app}} \
 --from https://github.com/itzg/{{.app}}/releases/download/{{.version}}/{{.app}}_{{.version}}_{{.os}}_{{.arch}}.tar.gz

COPY mcstatus /usr/local/bin

VOLUME ["/data","/mods","/config"]
COPY server.properties /tmp/server.properties
COPY log4j2.xml /tmp/log4j2.xml
WORKDIR /data

ENTRYPOINT [ "/start" ]

ENV UID=1000 GID=1000 \
  JVM_XX_OPTS="-XX:+UseG1GC" MEMORY="1G" \
  TYPE=VANILLA VERSION=LATEST FORGEVERSION=RECOMMENDED SPONGEBRANCH=STABLE SPONGEVERSION= FABRICVERSION=LATEST LEVEL=world \
  PVP=true DIFFICULTY=easy ENABLE_RCON=true RCON_PORT=25575 RCON_PASSWORD=minecraft \
  RESOURCE_PACK= RESOURCE_PACK_SHA1= \
  LEVEL_TYPE=DEFAULT GENERATOR_SETTINGS= WORLD= MODPACK= MODS= SERVER_PORT=25565 ONLINE_MODE=TRUE CONSOLE=true SERVER_NAME="Dedicated Server" \
  REPLACE_ENV_VARIABLES="FALSE" ENV_VARIABLE_PREFIX="CFG_"

COPY start* /
RUN dos2unix /start* && chmod +x /start*
