# Rosenpass docker image

This image provides a minimal configuration for the rosenpass and wireguard setup, to create a PQC (Post Quantum Computing) VPN connection. 
The image can be used as a client as well as a server. The only difference then is the rosenpass exchange command for the container. 

# Usage

```
docker run -d \
    --name=rosenpass
    --cap-add=NET_ADMIN
    --sysctl="net.ipv6.conf.all.src_valid_mark=1"
    --sysctl="net.ipv4.conf.all.src_valid_mark=1"
    stefan96/rosenpass:v0.2.0
```