{
  description = "Basic flake file for building a docker image containing the rosenpass tool";

  inputs = {
    rosenpass.url = "github:rosenpass/rosenpass";
    config.url = "path:./config";
  };

  outputs = { self, nixpkgs, rosenpass, config }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      dockerImages.rosenpass = pkgs.dockerTools.buildLayeredImage {
        name = "rosenpass";
        tag = "latest";
        contents = [ 
          rosenpass.packages.${system}.rosenpass
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
          config.defaultPackage.${system}
          ];
        
        config = {
          Cmd = [
            "${pkgs.bash}/bin/bash" "-c" "/bin/init.sh"
          ];
        };
      };


    packages.${system}.default = self.dockerImages.rosenpass;
  };
}