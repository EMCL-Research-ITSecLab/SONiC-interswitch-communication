# rosenpass-docker
Rosenpass Docker Implementation

## Tools used 

###  Nix 
The package management tool Nix is used to build rosenpass from source and to inject it into a minimal docker container

The following packages are included by using Nix: 

| Nix-package                                    | Package Description                                                 | Reason for Inclusion |
|------------------------------------------------|----------------------------------------------------------------------|----------------------|
| rosenpass.packages.x86_64-linux.rosenpass      | The rosenpass functionalities, build from source                                       |    To be able to use rosenpass in the final container                  |
| pkgs.coreutils-full                            | The GNU Core Utilities are the basic file, shell and text manipulation utilities of the GNU operating system. This is the full version that includes additional utilities. | Adds different necessary functionalities for practical work with the container (debugging, rosenpass-script needs certain cli tools as well)                     |
| pkgs.bash                                      | Bash is the GNU Project's shell—the Bourne Again SHell. This is an sh-compatible shell that incorporates useful features from the Korn shell (ksh) and C shell (csh). | Bash to be able to debug and login to the container via cli                     |
| pkgs.gnugrep                                   | GNU grep, a tool for searching text using regular expressions.      | The rosenpass implementation relies on grep, otherwise it cannot function                     |
| pkgs.iproute2                                  | A collection of utilities for Linux networking.                     |  ip command is necessary to create network devices for rosenpass and wireguard                    |
| pkgs.procps                       | Package to include sysctl       | sysctl is needed to be able to configure ipv6 correctly                 |
| pkgs.wireguard-tools                        | Package to include wireguard          | Is needed to establish a VPN connection between servers                 |

#### Flake
Since rosenpass is relying on the experimental functionality of "flakes", this project also harnesses its capabilities. Flake allows even more reproducibility than normal Nix. 

### Docker
As container runtime environment, docker is used as the defacto standard solution. With these, the resulting image can easily be integrate into the SONic switches, which are already using Docker for their functionalities. 

#### Docker configuration

In order to be able to setup rosenpass correctly in docker containers, a few things need to be considered:
- In order to prevent permission and RETNETLINK errors, the container needs:
  - root priviledges 
  - the NET_ADMIN capability
  - an ipv6 address 
  - sysctl options enabled to allow ipv6

### Setup

In order to manually build the docker container for rosenpass, use:

```
nix build . 
docker load < result
docker compose up 
```

### Next-steps

- minimal connection test between two local clients by using docker compose
- include wireguard and observe if integration with rosenpass works
- Begin (simple) pipeline setup for building the docker image
- Upload the docker image from the pipeline to ghcr