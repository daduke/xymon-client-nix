{
  description = "A very basic flake";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
      {

        packages.${system}.hello = pkgs.stdenv.mkDerivation {
          pname = "hello";
          version = "2.12.1";

          src = builtins.fetchurl {
            url = "https://ftpmirror.gnu.org/hello/hello-2.12.1.tar.gz";
            sha256 = "sha256-jZkUKv2SV28wsM18tCqNxoCZmLxdYH2Idh9RLibH2yA=";
          };

          doCheck = false;
        };

      };
}
