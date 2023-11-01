# rosenpass-docker
Rosenpass Docker Implementation


## Setup

In order to build and start the containers in a local environment, simply run from the root of the project:

```
nix build . 
docker load < result
cd tests
docker compose up 
```

This spins up 2 docker containers with the minimal rosenpass image, which are connected via a bridge network of docker.

To stop and cleanup, run:

```
docker compose down
docker compose rm -f
docker network rm tests_rosenpass
```

Please note, if you don't remove the network manually after manually spinning up the containers, you will run into an error next time you try to recreate the docker containers, as the IP adresses are already used. 

### Manual Tests
To manually test the containers, log into the client container and run: 
```ping6 fe90::3%rosenpass0```
This will try to ping the server container via the rosenpass interface.
On the server container you can run 
```watch -n 0.2 'wg show all; wg show all preshared-keys'```
To see, that a peer has been connected. If you wait 2 minutes, you will also see, that the PSK will be replaced by rosenpass.
 
### Automated Tests

The above test is also automated via pytest. To execute it, install the dependencies first via
```pip install -r tests/requirements.txt```
Then execute the tests by switching into the tests directory and run
```pytest -s```


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
| pkgs.inetutils                      | Package to include ping and other network tools       | Is needed to test the connection between the servers                 |
| pkgs.iana-etc                  | Package to include protocols for communication      | Needed to include /etc/protocols in the image to be able to communicate e.g. via imcp for a ping                 |




#### Flake
Since rosenpass is relying on the experimental functionality of "flakes", this project also harnesses its capabilities. Flake allows even more reproducibility than normal Nix. 

### Docker
As container runtime environment, docker is used as the defacto standard solution. With these, the resulting image can easily be integrate into the SONic switches, which are already using Docker for their functionalities. 

#### Docker configuration

In order to be able to setup rosenpass correctly in docker containers, a few things need to be considered:
- In order to prevent permission and RETNETLINK errors, the container needs:
  - root privileges 
  - the NET_ADMIN capability
  - an ipv6 address 
  - sysctl options enabled to allow ipv6


### Next-steps

- Begin (simple) pipeline setup for building the docker image
  - Test part not complete --> error when starting ocker containers with network and container not found ?
  - Upload image to dockerhub --> only on main branch on develop do upload as snapshot