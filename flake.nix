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
          pkgs.coreutils-full
          pkgs.bash 
          pkgs.gnugrep 
          pkgs.iproute2 
          pkgs.procps
          pkgs.wireguard-tools
          pkgs.inetutils
          pkgs.iana-etc
          ];
        
        config = {
          Cmd = [
            "${pkgs.bash}/bin/bash" "-c"
            ''
              ${pkgs.coreutils-full}/bin/echo "generate public and private keys";
              ${rosenpass.packages.x86_64-linux.rosenpass}/bin/rp genkey rosenpass-secret;
              ${rosenpass.packages.x86_64-linux.rosenpass}/bin/rp pubkey rosenpass-secret rosenpass-public;

              if [ $CLIENT == "True" ]; 
              then 
                echo "Client mode enabled...";
                ${rosenpass.packages.x86_64-linux.rosenpass}/bin/rp exchange rosenpass-secret dev rosenpass0 peer $SERVER_PUBKEY_DIR endpoint $SERVER_IPV4 allowed-ips $ALLOWED_IPV6_IPS &;
                sleep 5;
                ip a add $CLIENT_IPV6 dev rosenpass0;

              elif [ $SERVER == "True" ];
              then
                echo "Server mode enabled...";
                ${rosenpass.packages.x86_64-linux.rosenpass}/bin/rp exchange rosenpass-secret dev rosenpass0 listen $SERVER_IPV4_LISTEN_ADDR peer $CLIENT_PUKEY_DIR allowed-ips $ALLOWED_IPV6_IPS &;
                sleep 5;
                ip a add $SERVER_IPV6 dev rosenpass0;

              fi;
            ''
          ];
        };
      };


    # not copmpletely correct to use these, but to prevent errors when only using nix build . 
    packages.x86_64-linux.default = self.dockerImages.rosenpass;
  };
}

        
# SERVER_PUBKEY_DIR=/server-pub-keys/rosenpass-public
# SERVER_IPV4=172.26.0.3:9999
# ALLOWED_IPV6_IPS=fe90::/64
# CLIENT_IPV6=fe90::4/64

# SERVER_IPV4_LISTEN_ADDR=172.26.0.3:9999
# CLIENT_PUKEY_DIR=/client-keys/rosenpass-public
# SERVER_IPV6=fe90::3/64