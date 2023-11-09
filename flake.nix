{
  description = "A very basic flake";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      lib = pkgs.lib;
    in
    {
      packages.${system} = {
        hello = pkgs.stdenv.mkDerivation {
          pname = "hello";
          version = "2.12.1";

          src = builtins.fetchurl {
            url = "https://ftpmirror.gnu.org/hello/hello-2.12.1.tar.gz";
            sha256 = "sha256-jZkUKv2SV28wsM18tCqNxoCZmLxdYH2Idh9RLibH2yA=";
          };

          doCheck = false;
        };
        xymon = pkgs.stdenv.mkDerivation {
          pname = "xymon";
          version = "4.3.30";
          buildInputs = with pkgs;[ pcre libtirpc];
          CONFTYPE = "client";
          XYMONUSER="$(whoami)";
          XYMONTOPDIR="$(out)";
          XYMONHOSTIP = "157.136.141.40";
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
        };
      };
    };
}
