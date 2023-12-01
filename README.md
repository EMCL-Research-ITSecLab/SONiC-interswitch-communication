# rosenpass-docker
Rosenpass Docker Implementation

[![Build and Test](https://github.com/EMCL-Research-ITSecLab/rosenpass-docker/actions/workflows/ci.yaml/badge.svg?branch=develop)](https://github.com/EMCL-Research-ITSecLab/rosenpass-docker/actions/workflows/ci.yaml) [![Release Pipeline](https://github.com/EMCL-Research-ITSecLab/rosenpass-docker/actions/workflows/release.yaml/badge.svg?branch=develop)](https://github.com/EMCL-Research-ITSecLab/rosenpass-docker/actions/workflows/release.yaml)
![Docker Image Version (latest semver)](https://img.shields.io/docker/v/stefan96/rosenpass?sort=semver&logo=docker&label=latest%20stable%20version&labelColor=lightgrey&color=blue&link=https%3A%2F%2Fhub.docker.com%2Fr%2Fstefan96%2Frosenpass%2Ftags) ![Docker Image Version (latest semver)](https://img.shields.io/docker/v/stefan96/rosenpass?logo=docker&label=latest%20snapshot%20version&labelColor=lightgrey&color=blue&link=https%3A%2F%2Fhub.docker.com%2Fr%2Fstefan96%2Frosenpass%2Ftags)




## Setup

In order to build and start the containers in a local environment, simply run from the root of the project:

```
nix build . 
docker load < result
cd tests
docker compose up --wait
```

This spins up 2 docker containers with the minimal rosenpass image, which are connected via a bridge network of docker.

To stop and cleanup, run:

```
docker compose down
```

### Manual Tests
To manually test the containers, log into the client container and run: 
```ping -6 -I rosenpass0 fe70::3``` (ipv6 version)
```ping -I rosenpass0 172.27.0.3``` (ipv4 version)

This will try to ping the server container via the rosenpass interface.
On the server container you can run 
```watch -n 0.2 'wg show all; wg show all preshared-keys'```
To see, that a peer has been connected. If you wait 2 minutes, you will also see, that the PSK will be replaced by rosenpass.
 
### Automated Tests

The above test is also automated via pytest. To execute it, install the dependencies first via
```pip install -r tests/requirements.txt```
Then execute the tests by switching into the tests directory and run
```pytest -s```


### Manual setup without docker compose
It is also possible to start the images in 3 different modes, without using the docker compose file. For the modes available, please refer to the manual [here](README.image.md)


## Tools used 

###  Nix 
The package management tool Nix is used to build rosenpass from source and to inject it into a minimal docker container

The following packages are included by using Nix: 

| Nix-package                                    | Package Description                                                 | Reason for Inclusion | Required |
|------------------------------------------------|----------------------------------------------------------------------|----------------------|----------|
| `rosenpass.packages.x86_64-linux.rosenpass`      | The rosenpass functionalities, build from source                     | To be able to use rosenpass in the final container | True |
| `pkgs.coreutils-full`                            | The GNU Core Utilities are the basic file, shell and text manipulation utilities of the GNU operating system. This is the full version that includes additional utilities. | Adds different necessary functionalities for practical work with the container (debugging, rosenpass-script needs certain cli tools as well) | True |
| `pkgs.iana-etc`                                  | Package to include protocols for communication                      | Needed to include /etc/protocols in the image to be able to communicate e.g. via imcp for a ping | True |
| `pkgs.gnugrep`                                   | GNU grep, a tool for searching text using regular expressions.      | The rosenpass implementation relies on grep, otherwise it cannot function | True |
| `pkgs.iproute2`                                  | A collection of utilities for Linux networking.                     | ip command is necessary to create network devices for rosenpass and wireguard | True |
| `pkgs.procps`                                    | Package to include sysctl                                           | sysctl is needed to be able to configure ipv6 correctly | False |
| `pkgs.wireguard-tools`                           | Package to include wireguard                                        | Is needed to establish a VPN connection between servers | False |
| `pkgs.iputils`                                   | Package to include ping and other network tools                     | Is needed to test the connection between the servers | False |
| `pkgs.bash`                                      | Bash is the GNU Project's shell—the Bourne Again SHell. This is an sh-compatible shell that incorporates useful features from the Korn shell (ksh) and C shell (csh). | Bash to be able to debug and login to the container via cli | False |
| `pkgs.tcpdump`                                      | tcpdump utility to watch network traffic | Really useful to include for debugging purposes  | False |


#### Package size
Since it is not possible to retrieve the package sizes from an official source, it was tested, what size a minimum image will have.
By tests, a plain Nix image will have roughly 1 MB of Space occupied. To have only the rosenpass tool included (which is not functional on its own), 67MB of space are required. All packages that are strictly required for rosenpass to work, consume 94MB of space (Wireguard is not included). When including Wireguard as well, the image takes up to 132MB. The image with all the packages listed above, needs 132MB as well. 
These results were obtained by using each combination of packages as mentioned above with a plain image and observing the size properties of the results in the nix path. via ``` nix path-info -Sh ./result ``` 



#### Flake
Since rosenpass is relying on the experimental functionality of "flakes", this project also harnesses its capabilities. Flake allows even more reproducibility than normal Nix. 

### Docker
As container runtime environment, docker is used as the defacto standard solution. With these, the resulting image can easily be integrate into the SONic switches, which are already using Docker for their functionalities. 

#### Docker configuration

In order to be able to setup rosenpass correctly in docker containers, a few things need to be considered:
- In order to prevent permission and RETNETLINK errors, the container needs:
  - root privileges 
  - the NET_ADMIN capability
- Additionally for ipv6 compatibility the container need: 
  - sysctl options enabled to allow ipv6


### Testing Frameworks

#### Pytest

In order to automate the tests in the CI environment, Pytest was used. At the moment the tests directory contains 2 test scenarios that are checked each time in the CI Pipeline (on PR and on Release). These Tests covere the following topics:
- Setting up a client and a server container, using IPv4 and running a connection Test
- Setting up a client and a server container, using IPv6 and running a connection Test

On top of these, more complex and exhaustive testing can be implemented.


#### Act
[Act](https://github.com/nektos/act) is a CLI tools to test out github action workflows locally in docker containers, without them running on the remote github actions runner and thus causing spam for everyone subscribed to the Repository.  


### Next-steps

- dynamic peer setting for server
- test on gns3
- 