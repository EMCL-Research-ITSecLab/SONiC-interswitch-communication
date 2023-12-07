# Rosenpass docker image

This image provides a minimal configuration for the rosenpass and wireguard setup, to create a PQC (Post Quantum Computing) VPN connection. 
The image can be used as a client as well as a server. If you select either client or server mode, then upon startup a public and private keyfile will be created and the client or server will be set up according to your further configuration. 

# Sample Setup
To see a fully working IPv and IPv4 sample, have a look at the Repository for the image [here](https://github.com/EMCL-Research-ITSecLab/rosenpass-docker). In the subdirectory "tests" are compose files for each scenario. Please note that these require the image to be present locally, so you will need to build the nix flake as described there.

If you want to see how a custom setup is done, please refer to the "Getting started" section in the [README](https://github.com/EMCL-Research-ITSecLab/rosenpass-docker) of the main Repo

# Client mode
To start the image in client mode, run 
```
docker run -d \
 --cap-add=NET_ADMIN
 -e MODE=client
 -e SERVER_PUBKEY_DIR=/path/to/the/VPN_servers/pubkey/within/the/container 
 -e SERVER_PUBLIC_IP=<public ip adress of the server> 
 -e SERVER_PORT=<Any open port, default would be 9999> 
 -e CLIENT_VPN_IP= <IP the client should get in the VPN in CIDR notation>
 -e ALLOWED_IPS=<CIDR notated IP adresses (comma seperated). Depending on your setup set this to the VPN CID like 172.28.0.0/16>
 -e IPV6 <Use this only if your VPN should use ipv6. Please note that the VOPN IPs and allowed IPs should be IPv6 addresses in this case>
 --privileged  
 stefan96/rosenpass
```


# Server mode
To start the image in server mode, run 
```
docker run -d \
 --cap-add=NET_ADMIN
 -e MODE=server
 -e CLIENT_PUBKEY_DIR=/path/to/the/VPN_clients/pubkey/within/the/container 
 -e SERVER_PUBLIC_IP=<public ip address of the server> 
 -e SERVER_PORT=<Any open port, default would be 9999> 
 -e SERVER_VPN_IP= <IP the client should get in the VPN in CIDR notation>
 -e ALLOWED_IPS=<IP for the client to whitelist, in CIDR notation>
 -e IPV6 <Use this only if your VPN should use ipv6. Please note that the VPN IPs and allowed IPs should be IPv6 addresses in this case>
 --privileged  
 stefan96/rosenpass
```


# Standalone mode
To start the image in standalone mode, run 
```
docker run -d \
 --cap-add=NET_ADMIN
 -e MODE=standalone
 --privileged  
 stefan96/rosenpass
```

Please note that if you do this, the container will startup but won't do anything, so the process of setting up the connection to a Server or creating a server will be up to you