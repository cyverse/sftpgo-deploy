FROM cyverse/sftpgo

ARG SFTP_PORT=2022
ARG SFTPGO_ADMIN_UI_PORT=8080
ARG SFTPGO_VAULT="/srv/sftpgo"
ENV TZ="America/Phoenix"

USER root
RUN apt-get update && \
      apt-get install --no-install-recommends -y curl && \
      rm -rf /var/lib/apt/lists/*

RUN curl -L https://github.com/cyverse/sftpgo-auth-irods/releases/download/v0.1.3/sftpgo-auth-irods-v0.1.3-linux-amd64.tar.gz --output sftpgo-auth-irods.tar.gz && \
      mkdir sftpgo-auth-irods && \
      mv sftpgo-auth-irods.tar.gz sftpgo-auth-irods && \
      tar zxvf sftpgo-auth-irods.tar.gz && \
      cp sftpgo-auth-irods/sftpgo-auth-irods /usr/local/bin/

COPY sftpgo/sftpgo.json.template /tmp/sftpgo.json.template
COPY sftpgo/prep-config-json.sh /usr/local/bin/
RUN prep-config-json.sh

COPY sftpgo/host_keys/* /var/lib/sftpgo/
COPY sftpgo/blacklist.json /var/lib/sftpgo/

# set setuid/setgid bits, since users may want to bind system ports (i.e., 22)
RUN chmod ug+s /usr/local/bin/sftpgo
RUN chmod ug+s /usr/local/bin/sftpgo-auth-irods
USER 1000:1000

CMD ["sftpgo", "serve"]