{
  description = "xymon-client for NixOS";

  outputs = { self, nixpkgs }@inputs:
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    lib = pkgs.lib;
  in
  {
    packages.${system} = rec {
      default = xymon-client;
      xymon-client = pkgs.stdenv.mkDerivation {
        pname = "xymon-client";
        version = "4.3.30";
        buildInputs = with pkgs; [ pcre libtirpc net-tools ];
        CONFTYPE = "server";
        XYMONUSER = "xymon";
        XYMONTOPDIR = "$(out)";
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

        installPhase = ''
          runHook preInstall
          make install DESTDIR=$out
          mkdir -p $out/etc/xymon
          mkdir -p $out/var/lib/xymon
          mkdir -p $out/etc/default
          cp -r $etcxymon/* $out/etc/xymon/
          cp -r $varlibxymon/* $out/var/lib/xymon/
          runHook postInstall
        '';
      };
    };

    nixosModules.xymon = { config, pkgs, lib, ... }:
      let
        cfg = config.services.xymon-client;
        environmentFile = "/etc/default/xymon-client";
        xymonClientPackage = self.packages.${system}.xymon-client;
      in {
        options.services.xymon-client = {
          enable = lib.mkEnableOption "Enable the xymon client service";
          logDir = lib.mkOption {
            type = lib.types.str;
            description = "Log directory for xymon-client";
            default = "/var/log/xymon";
          };
          varLibDir = lib.mkOption {
            type = lib.types.str;
            description = "Var lib directory for xymon-client";
            default = "/var/lib/xymon";
          };
          user = lib.mkOption {
            type = lib.types.str;
            description = "User to own xymon files";
            default = "xymon";
          };
          xymonServers = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            description = "Servers to connect to for xymon";
          };
          clientHostname = lib.mkOption {
            type = lib.types.str;
            description = "Client hostname for xymon";
          };
        };

        config = lib.mkIf cfg.enable {
          users.users.${cfg.user} = {
            isSystemUser = true;
            group = cfg.user;
          };
          users.groups.${cfg.user} = {};

          environment.systemPackages = [
            self.packages.${system}.xymon-client
            pkgs.net-tools
          ];

          boot.kernelModules = [ "drivetemp" ];
  
          environment.etc."xymon".source = self.packages.${system}.xymon-client + "/etc/xymon";
      
          environment.etc."default/xymon-client".text = ''
            XYMONSERVERS="${lib.concatStringsSep " " cfg.xymonServers}"
            CLIENTHOSTNAME="${cfg.clientHostname}"
            MACHINEDOTS="${cfg.clientHostname}"
            MACHINE="${cfg.clientHostname}"
            XYMONCLIENTHOME="${cfg.varLibDir}/client"
          '';
      
          system.activationScripts.xymonVarLib.text = ''
            mkdir -p ${cfg.varLibDir}
            cp -r ${self.packages.${system}.xymon-client}/var/lib/xymon/* ${cfg.varLibDir}/
            chown -R ${cfg.user}:${cfg.user} ${cfg.varLibDir}
            chmod u+rwx ${cfg.varLibDir}/tmp
          '';
  
          system.activationScripts.xymonLog.text = ''
            mkdir -p ${cfg.logDir}
            chown ${cfg.user}:${cfg.user} ${cfg.logDir}
          '';
  
          systemd.tmpfiles.rules = [
            "d /run/xymon 0755 ${cfg.user} ${cfg.user} -"
          ];
  
          systemd.services.xymon-client = {
            enable = true;
            description = "Xymon systems and network monitor";
            documentation = [
              "man:xymon(7)"
              "man:xymonlaunch(8)"
              "man:xymon(1)"
            ];
            after = [ "network.target" ];
            wantedBy = [ "multi-user.target" ];
            serviceConfig = {
              EnvironmentFile = "${environmentFile}";
              User = cfg.user;
              ExecStartPre = "${cfg.varLibDir}/init-common.sh";
              ExecStart = "${xymonClientPackage}/bin/xymoncmd ${xymonClientPackage}/bin/xymonlaunch --no-daemon --config=/etc/xymon/clientlaunch.cfg --log=${cfg.logDir}/clientlaunch.log --pidfile=/run/xymon/clientlaunch.pid";
              ExecStopPost = "${pkgs.runtimeShell} -c 'kill $(${pkgs.procps}/bin/pidof vmstat)'";
              Type = "simple";
              KillMode = "process";
              SendSIGKILL = "no";
            };
          };
        };
      };
  };
}
