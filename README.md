# rosenpass-docker
Rosenpass Docker Implementation

[![Build and Test](https://github.com/EMCL-Research-ITSecLab/rosenpass-docker/actions/workflows/ci.yaml/badge.svg?branch=develop)](https://github.com/EMCL-Research-ITSecLab/rosenpass-docker/actions/workflows/ci.yaml) [![Release Pipeline](https://github.com/EMCL-Research-ITSecLab/rosenpass-docker/actions/workflows/release.yaml/badge.svg?branch=develop)](https://github.com/EMCL-Research-ITSecLab/rosenpass-docker/actions/workflows/release.yaml)
![Docker Image Version (latest semver)](https://img.shields.io/docker/v/stefan96/rosenpass?sort=semver&logo=docker&label=latest%20stable%20version&labelColor=lightgrey&color=blue&link=https%3A%2F%2Fhub.docker.com%2Fr%2Fstefan96%2Frosenpass%2Ftags) ![Docker Image Version (latest semver)](https://img.shields.io/docker/v/stefan96/rosenpass?logo=docker&label=latest%20snapshot%20version&labelColor=lightgrey&color=blue&link=https%3A%2F%2Fhub.docker.com%2Fr%2Fstefan96%2Frosenpass%2Ftags)


For more information on rosenpass and how it works, please refer to either [the Homepage](https://rosenpass.eu/) or the [GitHub Repository](https://github.com/rosenpass/rosenpass)

## 1. Getting started

To use the image in a custom setup, the following steps need to be applied:

For demonstration purposes we will use 4 virtual machines. 1 will act as server, 3 as clients, with the goal to connect the clients via the server with each other. Please note that in this setup the machines have no shared storage, hence the setup is not fully automated as with the docker-compose files (which is described [here](#fully-automated-setup-example-with-docker-compose)), since the public keys cannot be exchanged that easily. 
Furthermore, we assume the following:


| Configuration                                    | Value                                                 |
|------------------------------------------------|----------------------------------------------------------------------|
|Server public IP | 172.31.100.100  |
|Client 1 public IP| 172.31.100.101 |
|Client 2 public IP| 172.31.100.102 |
|Client 3 public IP| 172.31.100.103 |
|Server VPN IP | 10.11.12.100/24  |
|Client 1 VPN IP| 10.11.12.101/24 |
|Client 2 VPN IP| 10.11.12.102/24 |
|Client 3 VPN IP| 10.11.12.103/24 |
|Allowed VPN CIDR| 10.11.12.0/24 |
|IPv6 enabled| False|
|Docker network| name: br0, subnet: 172.28.0.0/24 |



**If you'd like to use this example on one machine with 4 docker containers, don't forget to create a network so that the containers can reach each other.**


<!-- TODO: insert depiction of the architecture -->

### 1.1 Start the server and client instances

First start the clients by running for client1:

client 1:
```
docker run -d \
 --cap-add=NET_ADMIN \
 -e MODE=client \
 -e SERVER_PUBLIC_IP="172.31.100.100" \
 -e SERVER_PORT="9999" \
 -e CLIENT_VPN_IP=10.11.12.101/24 \
 --privileged \
 --name client1 \
 stefan96/rosenpass:latest
 ```

client 2:
```
docker run -d \
 --cap-add=NET_ADMIN \
 -e MODE=client \
 -e SERVER_PUBLIC_IP="172.31.100.100" \
 -e SERVER_PORT="9999" \
 -e CLIENT_VPN_IP=10.11.12.102/24 \
 --privileged \
 --name client2 \
 stefan96/rosenpass:latest
 ```


client 3:
```
docker run -d \
 --cap-add=NET_ADMIN \
 -e MODE=client \
 -e SERVER_PUBLIC_IP="172.31.100.100" \
 -e SERVER_PORT="9999" \
 -e CLIENT_VPN_IP=10.11.12.103/24 \
 --privileged \
 --name client3 \
 stefan96/rosenpass:latest
 ```

client 4:
```
docker run -d \
 --cap-add=NET_ADMIN \
 -e MODE=client \
 -e SERVER_PUBLIC_IP="172.31.100.100" \
 -e SERVER_PORT="9999" \
 -e CLIENT_VPN_IP=10.11.12.104/24 \
 --privileged \
 --name client4 \
 stefan96/rosenpass:latest
 ```

and for the server:

```
docker run -d \
 --cap-add=NET_ADMIN \
 -e MODE="server" \
 -e SERVER_PUBLIC_IP="172.31.100.100" \
 -e SERVER_PORT="9999" \
 -e SERVER_VPN_IP="10.11.12.100/24" \
 --privileged \
 --name "server" \
 stefan96/rosenpass
```

This will create key pairs on each machine (public and private) which we will be using to authenticate the machines with each other.
Furthermore, with the information provided, a startup script will be created that contains all the commands necessary to execute, once the keys are exchanged


**Please note:** Carefully review your input information as a startup script will be generated from them. So if you type in something wrong you will either need to adjust the startup script or redo all the steps

### 1.2 Exchange the public keys

Now, the server needs the public keys of every client, and the clients need the publickey of the server. This part is not automated yet and requires you to manually exchange the keys ( i.e. copy the public key directories to the other machine(s) ).
For a server, the public key will be created at /keys/rosenpass-server-public. You can copy the key to your host machine using 
```
docker cp server:/keys/rosenpass-server-public ./
```
From there you can copy the key to the destined container(s). 
For clients, the key will be located at:
``/keys/rosenpass-client-public``

**When you transfer all the client keys to the server, remember to either rename them to be able to distinguish between them or to save them to different directories**

### 1.3 Start the server script
After transferring the public key directories from your clients to the server, 
log into the docker container of your server and run the start script with
``` bash /etc/open_server_connection.sh ```
You will be prompted for the location where you saved each public key directory of the clients. Type in one at a time and submit with "enter".
Afterward you will need to type in the IP that is allowed for this key (in other words: which VPN IP shall be assigned to this key. This is the client VPN IP of the machine that will be using the according private key to authenticate).
Submit with "enter". Repeat the process for each key and IP.
Afterward, the server will start and allow the connections from the clients.

```
Example: 
From client1 the prompts could look like this
1. path/to/the/pubkey-of-client1/
2. 10.11.12.101
```

### 1.4 Start the client scripts
After transfering the public key directory from your server to the clients, 
log into the each client docker container and run the start script with
``` bash /etc/connect_to_server.sh ```
You will be prompted for the location of the servers public key and afterward for the allowed IP range the tunnel shall be established for. In this example, use 10.11.12.0/24 to be able to connect to all clients. 
Afterward, the clients will establish a tunnel to the setup server
Repeat this on each client machine.

```
Example:
1. path/to/the/pubkey-of-server/
2. 10.11.12.0/24
```

Here, we are using the CIDR that contains all the clients and the server in the VPN to be able to reach them. Your setup could look different depending on your usecase.

### 1.5 Connection test 
From an arbitrary client, ping the server by using 
```ping 10.11.12.100```
This should ping the server within the VPN. Afterward try to connect to another client (e.g. client 3) by running:
```ping 10.11.12.103```
This will send the requests to the server and from there to the other client in the network. You can confirm this by running 


### (optional) 1.6 Set routes 
When you are running the container in a native Unix environment or inside wsl but without docker dekstop ([installation guide](https://dev.to/felipecrs/simply-run-docker-on-wsl2-3o8)) then you can also set routes via ``` ip route add ``` and point your desired network traffic through the docker network interface that is attached to the container. This will allow you to use the tunnel for all traffic sent from your device.  
The following example will demonstrate how to route the traffic for the IP ranges of the VPN subnet (10.11.12.0/24) from the host of client1 through wireguard to server1. This will enable us to ping all other clients as well with their VPN IPs from the host machine of client1.

To do that, you will need to create a network with 
```docker network create -d bridge --subnet=172.28.0.0/24 br0```
 and attach it to the container with 
 ```docker network connect -ip 172.28.0.10 br0 client1```
By doing this a network interface will be created which you should see with ```ip a```. Afterward, run
```ip route add 10.11.12.0/24 via 172.28.0.10```
 to route all traffic with an IP of 10.11.12.0/24 through the wiregaurd container, which is setup to forward these addresses by using the tunnel to the VPN server (Allowed addresses in [step 4](#4-start-the-client-scripts)).

To test the setup, try to ping e.g. the VPN IP of client2 (10.11.12.102) from the host of client1 ```ping 10.11.12.102```. You should now be able to get a proper response.


## 2. Fully automated setup example with docker compose 

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

To be able to ping the server container from the host via its VPN ip, follow [these steps](#optional-6-set-routes)

### 2.1 Manual Tests
To manually test the containers, log into the client container and run: 
```ping -6 -I rosenpass0 fe70::3``` (ipv6 version)
```ping -I rosenpass0 172.26.0.3``` (ipv4 version)

This will try to ping the server container via the rosenpass interface.
On the server container you can run 
```watch -n 0.2 'wg show all; wg show all preshared-keys'```
To see, that a peer has been connected. If you wait 2 minutes, you will also see, that the PSK will be replaced by rosenpass.
 
### 2.2 Automated Tests

The above test is also automated via pytest. To execute it, install the dependencies first via
```pip install -r tests/requirements.txt```
Then execute the tests by switching into the tests directory and run
```pytest -s```


## 3. Manual setup without docker compose
It is also possible to start the images in 3 different modes, without using the docker compose file. For the modes available, please refer to the manual [here](README.image.md)


## 4. Setup on GNS3

To setup a minimal example on gns3, it is recommended to use 3 sonic switches. One will connect the other 2 leaf switches. Each leaf switch will then include a virtual client. This will allow us to communicate from one client with another one via leaf and spine switches, by using a rosenpass VPN to secure the communication. Please note that the clients will not be part of the VPN, only the switches. The topology is displayed below:

<!-- Bild von GNS3 topology -->

For this topology we assume the following: 
- The 2 end nodes need to be in the same VLAN in order to be able to reach one another
- DHCP for the VLAN will be configured manually to assign IP addresses to all switches and the 2 end nodes
- The following configuration will be applied:

| Configuration                                    | Value                                                 |
|------------------------------------------------|----------------------------------------------------------------------|
|Spine IP | 172.31.100.100  |
|Leaf 1 IP| 172.31.100.101 |
|Leaf 2 IP| 172.31.100.102 |
|Client 1 IP| 172.31.100.103 |
|Client 2 IP| 172.31.100.104 |
|Spine VPN IP | 10.11.12.100 |
|Leaf 1 VPN IP| 10.11.12.101 |
|Leaf 2 VPN IP| 10.11.12.102 |


#### 4.1 Setup Gns3 and configure dhcp

**TO BE DONE:**

First you will need to replicate the architecture. Make sure to connect the internet sources on the eth0 ports, for instance for a leaf switch, eth0 should point to an arbitrary port of the main switch. The main switch should be connected on port eth0 to the hub and the hub on eth0 to the NAT. 

Now, in order to allow the virtual machines to communicate with each other, it is necessary to configure a dhcp service, as the sonic switches only come with a dhcp relay.  Execute the following steps on the main switch:

<!-- 
steps dhcp:
- sonci switch add ip to vlan or create new vlan 
- sonci switch: srtart container mit tpcm 
  - tpcm install name dhcp pull networkboot/dhcpd --args "--network host -v /home/admin/data/dhcpd.conf"
- frage: muess ich erstellen vlan ? wenen ja als brifdge, auf th0 oder eth2 ? wie verbninde ich Ethernet2 mit vlan ? ö -->


#### 4.2 start containers in the nodes 

Start the rosenpass containers for each node accordingly.
For the Spine switch, run:
```
docker run -d --cap-add=NET_ADMIN --network host -e MODE=server -e SERVER_PUBLIC_IP="192.168.122.30" -e SERVER_PORT=9999 -e SERVER_VPN_IP="10.11.12.100/24" --privileged --name=server stefan96/rosenpass:v0.2.1-SNAPSHOT
```

For Leaf switch 1, run:
```
docker run -d --cap-add=NET_ADMIN --network host -e MODE=client -e SERVER_PUBLIC_IP="192.168.122.30" -e SERVER_PORT=9999 -e CLIENT_VPN_IP="10.11.12.101/24" --privileged --name=client stefan96/rosenpass:v0.2.1-SNAPSHOT
```

For Leaf switch 2, run:
```
docker run -d --cap-add=NET_ADMIN --network host -e MODE=client -e SERVER_PUBLIC_IP="192.168.122.30" -e SERVER_PORT=9999 -e CLIENT_VPN_IP="10.11.12.102/24" --privileged --name=client stefan96/rosenpass:v0.2.1-SNAPSHOT
```

<!-- ISSUE: 
With network set to host the container can now use the hosts ip and be setup correctly. When using a bridge network the other docker container could not reach the container, because it is residing in a private network on another host. But when using host network one cannot route the traffic through the docker container for the VPN, so the other VPN member containers are not reachable at all -- Dilemma!! But maybe resolveable by only using host network and creating new routes that can directly access the VPN members -->

#### 4.3 Copy the keys to the docker host
Copy the keys created in the container to the docker host

For example in the Spine switch, run:
``` docker cp server:/keys/rosenpass-server-public ./ ```
In the Leaf switches, run:
``` docker cp server:/keys/rosenpass-client-public ./ ```



#### 4.4 Use sftp to get the keys for the server/clients
use sftp to login to the other switch(es) and download the public keys from there.
To do this from a Leaf switch to obtain the data of the Spine Switch, run:
```sftp admin@192.168.122.30``` 
You will be prompted for the password of the admin user. 
Afterwards run
```get /keys/rosenpass-server-public``` 
to obtain the wgpk and the pqpk files, which will be saved to the current directory on your leaf switch.
Do this on all Leaf switches, to obtain the Spines public keys and on the Spine switch to obtain the public keys of both Leaf switches. Make sure you save the Leaf switch keys in separate directories to be able to distinguish between Leaf1 and Leaf2.


#### 4.5 Inject the keys to the containers again
Now using docker cp again, inject the copied keys to the respective containers. For instance for each client machine copy the servers pubkeys to a directory of your choice, e.g. /keys/rosenpass-server-public
For instance for the Server, run:
``` docker cp ./rosenpass-client1-public server:/keys/rosenpass-client1-public```
or for one of the leaf switches run:
``` docker cp ./rosenpass-server-public server:/keys/rosenpass-server-public```

#### 4.6 Execute the scripts as mentioned above
Execute the startup scripts for the client and the server like mentioned above [start the server](#3-start-the-server-script) [start the client](#4-start-the-client-scripts)
If no error is displayed then the connection was established and can be tested by pinging the VPN IPs of the other switches. This should work from inside the rosenpass containers as well as outside on the host systems. 

#### 4.7 Add routing for the VLAN over VPN 
**TBD**

#### 4.8 test ping from client 1 to client 2
**TBD**

## 5. Tools used 
The following section describes the Tools that were used to build, bundle and test the image, as well as tools which supported the development process.

###  5.1 Nix 
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


#### 5.1.1 Package size
Since it is not possible to retrieve the package sizes from an official source, it was tested, what size a minimum image will have.
By tests, a plain Nix image will have roughly 1 MB of Space occupied. To have only the rosenpass tool included (which is not functional on its own), 67MB of space are required. All packages that are strictly required for rosenpass to work, consume 94MB of space (Wireguard is not included). When including Wireguard as well, the image takes up to 132MB. The image with all the packages listed above, needs 132MB as well. 
These results were obtained by using each combination of packages as mentioned above with a plain image and observing the size properties of the results in the nix path. via ``` nix path-info -Sh ./result ``` 



#### 5.1.2 Flake
Since rosenpass is relying on the experimental functionality of "flakes", this project also harnesses its capabilities. Flake allows even more reproducibility than normal Nix. 

### 5.2 Docker
As container runtime environment, docker is used as the defacto standard solution. With these, the resulting image can easily be integrate into the SONic switches, which are already using Docker for their functionalities. 

#### 5.2.2 Docker configuration

In order to be able to setup rosenpass correctly in docker containers, a few things need to be considered:
- In order to prevent permission and RETNETLINK errors, the container needs:
  - root privileges 
  - the NET_ADMIN capability
- Additionally for ipv6 compatibility the container need: 
  - sysctl options enabled to allow ipv6


### 5.3 Testing Frameworks
In order to prevent errors and enable users to quickly test out the images, small tests are created to ensure that. 

#### 5.3.1 Pytest

As testing framework, Pytest was used, because Python offers a small and lightweight solution for creating tests with docker containers. 
At the moment the tests directory contains 2 test scenarios that are checked each time in the CI Pipeline (on PR and on Release). These Tests covere the following topics:
- Setting up a client and a server container, using IPv4 and running a connection Test
- Setting up a client and a server container, using IPv6 and running a connection Test

On top of these, more complex and exhaustive testing can be implemented.


#### 5.3.2 Act
[Act](https://github.com/nektos/act) is a CLI tools to test out github action workflows locally in docker containers, without them running on the remote github actions runner and thus causing spam for everyone subscribed to the Repository.  


### Next-steps / Issues
**Next steps:**
1. create rosenpass containers with network setting set to host on the switches (checked)
2. observe if routes will be created on the host machine as well (checked)
3. test connection between switches via VPN (checked)
4. Find a way to route the traffic over the VPN for the VLAN of the clients
5. Create VLAN and DHCP in the spine/leafs
  <!-- - erstellen eines VLANS im spine, erstellen des gleichen vlans in den leafs > alle geben NAt oder server als helper/GW an -> wie im yt video
  - brauche dann keine eth0 leaf verbindungen mehr -> löschen -> sollte dann auch internet access + ip haben 
  - auf eth0 muss eingehend sein bei leafs ?
  - yt video nochmal anschauen wie die ip adressen auf den scwitches wie vergeben werden ?
 -->

**Current Issues:**
- pipeline only main branch build not snapshot?
- "error" in open_connection and client script: Ip description need to be adapted : server allowed ips = ip for the client in vpn ; client allowed ips= to which servers shall tunnel be used 

**Roadmap:**
  - gns3 setup dhcp 
  - e2e test
  - if time remains:
    - hardware switch usage 
    - container shutdown handling --> how to reconnect to the same VPN without additional config ? --> after shutdopwn the container seem to restablish the routes/interfaces etc. so the conection flow is possible again ootb!
    - REST service for kex