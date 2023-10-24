# rosenpass-docker
Rosenpass Docker Implementation

## Tools used

###  Nix 
The package management tool Nix is used to build rosenpass from source and to inject it into a minimal docker container
#### Flake
Since rosenpass is relying on the experimental functionality of "flakes", this project also harnesses its capabilities. Flake allows even more reproducibility than normal Nix. 

### Docker
As container runtime environment, docker is used as the defacto standard solution. With these, the resulting image can easily be integrate into the SONic switches, which are already using Docker for their functionalities. 

### Setup

In order to manually build the docker container for rosenpass, use:

```
nix build . 
docker load < result
docker run -it rosenpass /bin/bash
```

### Next-steps

- Include all necessary packages to be able to fully operate rosenpass
- resolve error when opening connection via:
  ```
  bash-5.2# rp exchange server.rosenpass-secret dev rosenpass0 listen 192.168.0.1:9999 peer client.rosenpass-public allowed-ips fe80::/64
  RTNETLINK answers: Operation not permitted
  Cannot find device "rosenpass0"
  Cannot find device "rosenpass0"
  ```
- minimal connection test between two local clients (manually configured (pub key, priv key, keyexchange, etc. ))
- include wireguard and observe if integration with rosenpass works