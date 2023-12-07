{
  description = "Flake for creating the init-script for the image";

  outputs = { self, nixpkgs }:
    let
        system = "x86_64-linux";
        pkgs = nixpkgs.legacyPackages.${system};
    in {
        initScript = pkgs.writeShellScriptBin  "init.sh" ''
          #!/bin/bash

          echo "creating key directory...";
          mkdir -p /keys;

          print_common_vars () {
            echo "
            ALLOWED_IPS=$ALLOWED_IPS
            SERVER_PUBLIC_IP=$SERVER_PUBLIC_IP
            SERVER_PORT=$SERVER_PORT
            ";
          } 


          if [[ ! -n "$IPV6" ]];
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
            SALT=$(echo $RANDOM | md5sum | head -c 10);

            /bin/rp genkey /keys/rosenpass-client-secret-$SALT;
            /bin/rp pubkey /keys/rosenpass-client-secret-$SALT /keys/rosenpass-client-public-$SALT;
            if [[ -z "$SERVER_PUBKEY_DIR" ]];
            then
              echo "write the connection commands to file, since no SERVER_PUBKEY_DIR was given. Hence no connection possible right now"
              echo '
              #!/bin/bash
              echo "please insert next a publickey directory location for the peer you want to connect with as absolute path (e.g. /keys/publickey-example)"
              read SERVER_PUBKEY_DIR
              echo "please insert next the allowed-ips for this public key (e.g. 10.11.12.0/24)"
              read ALLOWED_IPS     
              echo "exchanging keys..."
              /bin/rp exchange /keys/rosenpass-client-secret-'$SALT' dev rosenpass0 peer "$SERVER_PUBKEY_DIR" endpoint "$SERVER_PUBLIC_IP":"$SERVER_PORT" allowed-ips "$ALLOWED_IPS" &
              sleep 5
              echo "Add ip to the wireguard interface"
              ip a add "$CLIENT_VPN_IP" dev rosenpass0
              echo "DONE"
              ' > /etc/connect_to_server.sh ;
            else
              echo "connect to the server";
              sleep 5;
              /bin/rp exchange /keys/rosenpass-client-secret-$SALT dev rosenpass0 peer "$SERVER_PUBKEY_DIR" endpoint "$SERVER_PUBLIC_IP":"$SERVER_PORT" allowed-ips "$ALLOWED_IPS" &
              sleep 5;
              echo "Add ip to the wireguard interface";
              ip a add "$CLIENT_VPN_IP" dev rosenpass0;
            fi;

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
            SALT=$(echo $RANDOM | md5sum | head -c 10);
            /bin/rp genkey /keys/rosenpass-server-secret-$SALT;
           /bin/rp pubkey /keys/rosenpass-server-secret-$SALT /keys/rosenpass-server-public-$SALT;
            

            if [[ -z "$CLIENT_PUBKEY_DIR" ]];
            then
              echo "write the connection commands to file, since no CLIENT_PUBKEY_DIR was given. Hence no connection possible right now";
              echo '
              #!/bin/bash

              declare -A key_ip_dict
              BASE_COMMAND="/bin/rp exchange /keys/rosenpass-server-secret-'$SALT' dev rosenpass0 listen $SERVER_PUBLIC_IP:$SERVER_PORT" 
              while true 
              do
                  echo "please insert next a publickey directory location for the peer you want to connect with as absolute path (e.g. /keys/publickey-example) Leave emtpy to skip"
                  read location

                  if [[ -z "$location" ]]
                  then
                      echo "left inputs blank, advancing..."
                      break       
                  fi

                  echo "please insert next the allowed-ips for this public key (e.g. 10.11.12.0/24)"
                  read allowed     

                  key_ip_dict[$location]=$allowed
              done

              for directory in ''${!key_ip_dict[@]}
              do 
                  BASE_COMMAND+=" peer $directory allowed-ips ''${key_ip_dict[$directory]}"
              done
              echo "Base_command: $BASE_COMMAND"

              echo "Exchanging keys with the clients..."
              $BASE_COMMAND &
              sleep 5
              echo "Add ip to the wireguard interface"
              ip a add "$SERVER_VPN_IP" dev rosenpass0
              echo "DONE"
              ' > /etc/open_server_connection.sh ;
            else
              echo "Setting connection for the peer";
              sleep 5;
              /bin/rp exchange /keys/rosenpass-server-secret-$SALT dev rosenpass0 listen "$SERVER_PUBLIC_IP":"$SERVER_PORT" peer "$CLIENT_PUBKEY_DIR" allowed-ips "$ALLOWED_IPS" &
              sleep 5;
              echo "Add ip to the wireguard interface";
              ip a add "$SERVER_VPN_IP" dev rosenpass0;
            fi;

          elif [ "$MODE" == "standalone" ];
          then
            echo "MODE=$MODE";
            
            echo "generate server public and private keys";
            SALT=$(echo $RANDOM | md5sum | head -c 10);
            /bin/rp genkey /keys/rosenpass-secret-$SALT;
            /bin/rp pubkey /keys/rosenpass-secret-$SALT /keys/rosenpass-public-$SALT;
            echo "Leaving everything else up to the user..."

          else
            echo "Specified an invalid mode (MODE=$MODE)";
            exit 1;
          fi;

          tail -f /dev/null
        '';
        defaultPackage.${system} = self.initScript;
  };
}