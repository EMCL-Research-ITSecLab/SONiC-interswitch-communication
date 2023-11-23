{
  description = "Basic flake file for building a docker image containing the rosenpass tool";

  inputs = {
    rosenpass.url = "github:rosenpass/rosenpass";
  };

  outputs = { self, nixpkgs, rosenpass }:
    let
    pkgs = nixpkgs.legacyPackages.x86_64-linux;
    in {
      dockerImages.rosenpass = pkgs.dockerTools.buildLayeredImage {
        name = "rosenpass";
        tag = "latest";
        contents = [ 
          rosenpass.packages.x86_64-linux.rosenpass
          pkgs.iputils
          pkgs.coreutils-full
          pkgs.bash 
          pkgs.gnugrep 
          pkgs.iproute2 
          pkgs.procps
          pkgs.wireguard-tools
          pkgs.iana-etc
          pkgs.iptables
          pkgs.tcpdump
          ];
        
        config = {
          Cmd = [
            "${pkgs.bash}/bin/bash" "-c"
            ''
              echo "creating key directory...";
              mkdir -p /keys;

              print_common_vars () {
                echo "
                ALLOWED_IPS=$ALLOWED_IPS
                SERVER_PUBLIC_IP=$SERVER_PUBLIC_IP
                SERVER_PORT=$SERVER_PORT
                ";
              } 


              if [ -z "$IPV6" ];
              then
                echo "Activating IPv6";
                touch /etc/sysctl.conf;
                echo "
                  net.ipv6.conf.all.disable_ipv6 = 0
                  net.ipv6.conf.default.disable_ipv6 = 0
                  net.ipv6.conf.lo.disable_ipv6 = 0   
                " > /etc/sysctl.conf;
                sysctl -p ;
              fi;

              if [ "$MODE" == "client" ]; 
              then 
                echo "
                ****************** Configuration Options ******************
                MODE=$MODE
                CLIENT_VPN_IP=$CLIENT_VPN_IP
                SERVER_PUBKEY_DIR=$SERVER_PUBKEY_DIR
                $(print_common_vars)
                ***********************************************************
                ";
                
                echo "generate client public and private keys";
                ${rosenpass.packages.x86_64-linux.rosenpass}/bin/rp genkey /keys/rosenpass-client-secret;
                ${rosenpass.packages.x86_64-linux.rosenpass}/bin/rp pubkey /keys/rosenpass-client-secret /keys/rosenpass-client-public;
                echo "connect to the server";
                sleep 5;
                ${rosenpass.packages.x86_64-linux.rosenpass}/bin/rp exchange /keys/rosenpass-client-secret dev rosenpass0 peer "$SERVER_PUBKEY_DIR" endpoint "$SERVER_PUBLIC_IP":"$SERVER_PORT" allowed-ips "$ALLOWED_IPS" &
                sleep 5;
                echo "Add ip to the wireguard interface";
                ip a add "$CLIENT_VPN_IP" dev rosenpass0;

              elif [ "$MODE" == "server" ];
              then
                echo "
                ****************** Configuration Options ******************
                MODE=$MODE
                SERVER_VPN_IP=$SERVER_VPN_IP
                CLIENT_PUBKEY_DIR=$CLIENT_PUBKEY_DIR
                $(print_common_vars)
                ***********************************************************
                ";

                echo "generate server public and private keys";
                ${rosenpass.packages.x86_64-linux.rosenpass}/bin/rp genkey /keys/rosenpass-server-secret;
                ${rosenpass.packages.x86_64-linux.rosenpass}/bin/rp pubkey /keys/rosenpass-server-secret /keys/rosenpass-server-public;
                echo "Setting connection for the peer";
                sleep 5;
                ${rosenpass.packages.x86_64-linux.rosenpass}/bin/rp exchange /keys/rosenpass-server-secret dev rosenpass0 listen "$SERVER_PUBLIC_IP":"$SERVER_PORT" peer "$CLIENT_PUBKEY_DIR" allowed-ips "$ALLOWED_IPS" &
                sleep 5;
                echo "Add ip to the wireguard interface";
                ip a add "$SERVER_VPN_IP" dev rosenpass0;
              elif [ "$MODE" == "standalone" ];
              then
                echo "MODE=$MODE";
                echo "Leaving everything up to the user..."
              else
                echo "Specified an invalid mode (MODE=$MODE)";
                exit 1;
              fi;

              tail -f /dev/null
            ''
          ];
        };
      };


    # not copmpletely correct to use these, but to prevent errors when only using nix build . 
    packages.x86_64-linux.default = self.dockerImages.rosenpass;
  };
}