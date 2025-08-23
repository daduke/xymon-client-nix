{
  description = "xymon-client for NixOS";

  outputs = { self, nixpkgs }:
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    lib = pkgs.lib;
    #stdenv = pkgs.stdenv;
  in
  {
    packages.${system} = rec {
      default = xymon-client;
      xymon-client = pkgs.stdenv.mkDerivation {
        pname = "xymon-client";
        version = "4.3.30";
        buildInputs = with pkgs;[ pcre libtirpc];
        CONFTYPE = "client";
        XYMONUSER="$(whoami)";
        XYMONTOPDIR="$(out)";
        XYMONHOSTIP = "127.0.0.1";
        PKGBUILD = "yes";
        configureFlags = [
          "--client"
          "--pcreinclude ${pkgs.pcre}/include"
          "--pcrelib ${pkgs.pcre}/lib"
          "--make ${pkgs.gnumake}/bin/make"
        ];
        dontAddPrefix = true;
        src = builtins.fetchurl {
          url = "https://netcologne.dl.sourceforge.net/project/xymon/Xymon/4.3.30/xymon-4.3.30.tar.gz";
          sha256 = "sha256:1xgm3ch2aqlmmkny3805c47ap1hjl9hjq1r5czwmvqg1r1qigmcf";
        };

        # these must be git committed or build will fail!
        etcxymon = ./etc-xymon;
        varlibxymon = ./var-lib-xymon;
        defaultxymon = ./default-xymon;
        service = ./xymon-client.service;

        installPhase = ''
          runHook preInstall
          make install DESTDIR=$out
          mkdir -p $out/etc/xymon
          mkdir -p $out/var/lib/xymon
            mkdir -p $out/etc/default
            mkdir -p $out/run/systemd/system
          cp -r $etcxymon/* $out/etc/xymon/
          cp -r $varlibxymon/* $out/var/lib/xymon/
          cp $defaultxymon $out/etc/default/xymon-client
          cp $service $out/run/systemd/system/xymon-client.service
          runHook postInstall
        '';
      };
    };

    nixosModules.xymon = { config, pkgs, ... }: {
      options = {};
      config = {
        # Deploy config files from the built package output to /etc/xymon
        environment.etc."xymon".source = self.packages.${system}.xymon-client + "/etc/xymon";
        environment.etc."default/xymon-client".source =
             self.packages.${system}.xymon-client + "/etc/default/xymon-client";
 
        system.activationScripts.xymonVarLib.text = ''
          mkdir -p /var/lib/xymon
          cp -r ${self.packages.${system}.xymon-client}/var/lib/xymon/* /var/lib/xymon/
          chown -R xymon: /var/lib/xymon
          chmod u+rwx /var/lib/xymon/tmp
        '';
 
        system.activationScripts.xymonService.text = ''
          mkdir -p /run/systemd/system
          cp ${self.packages.${system}.xymon-client}/run/systemd/system/xymon-client.service /run/systemd/system/xymon-client.service
        '';
 
        system.activationScripts.xymonLog.text = ''
          mkdir -p /var/log/xymon
          chown xymon: /var/log/xymon
        '';
 
 
        # Ensure /run/xymon exists with proper permissions on system boot
        systemd.tmpfiles.rules = [
          "d /run/xymon 0755 xymon xymon -"
        ];
      };
    };
  };
}
