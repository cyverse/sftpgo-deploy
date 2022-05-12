FROM golang:1.18-bullseye as auth_builder

RUN mkdir -p /workspace
WORKDIR /workspace

RUN apt-get update && \
      apt-get install --no-install-recommends -y unzip make && \
      rm -rf /var/lib/apt/lists/*

RUN curl -L https://github.com/cyverse/sftpgo-auth-irods/archive/refs/heads/main.zip --output sftpgo-auth-irods.zip && \
      unzip sftpgo-auth-irods.zip && \
      mv sftpgo-auth-irods-main sftpgo-auth-irods

WORKDIR /workspace/sftpgo-auth-irods
RUN make

FROM cyverse/sftpgo
COPY --from=auth_builder /workspace/sftpgo-auth-irods/bin/sftpgo-auth-irods /usr/local/bin/
COPY sftpgo/sftpgo.json.template /tmp/sftpgo.json.template
COPY sftpgo/prep-config-json.sh /tmp/prep-config-json.sh
RUN /tmp/prep-config-json.sh /etc/sftpgo/sftpgo.json

CMD ["sftpgo", "serve"]