# sftpgo-deploy
Deploy SFTPGo for CyVerse DataStore

## Build
Update configuration parameters set in `config.inc`.

```bash
./build
```

This builds `sftpgo-deploy` docker image. The docker image is based on `cyverse/sftpgo` image, which is built from `https://github.com/cyverse/sftpgo`.

## Start

```bash
./controller start
```

## Stop

```bash
./controller stop
```
