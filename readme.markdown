# nix package for xymon-client

## Credits

This is based on [Pierre's](https://plmlab.math.cnrs.fr/nix/xymon-client) nix package for xymon-client. He laid the groundwork to get xymon-client compiled from the xymon sources. I added a nix module to configure the client.

## Installation

In your system flake, add
```
  inputs = {
    xymon-client.url = "github:daduke/xymon-client-nix";
    xymon-client.inputs.nixpkgs.follows = "nixpkgs";
  }

  outputs = { self, nixpkgs, xymon-client, ... }@inputs: {
    nixosConfigurations.nixos-testing = nixpkgs.lib.nixosSystem {
      ...
      modules = [
        xymon-client.nixosModules.xymon
      ];
      ...
    };
  };
```

and in `configuration.nix`:
```
  services.xymon-client = {
    enable = true;
    xymonServers = [ "xymon-server-IP1" "xymon-server-IP2" ];
    clientHostname = "nixos-testing.daduke.org";
    varLibDir = "/var/lib/xymon";
    logDir = "/var/log/xymon";
    user = "xymon";
  };
```

## Hobbit.pm Perl module

If you'd like to use xymon extensions that rely on the `Hobbit.pm` module, I've got you covered too. Add
```
  inputs = {
    Hobbit.url = "github:daduke/hobbit-module-nix";
  };
```
to your system `flake.nix` and
```
environment.systemPackages = with pkgs; [
  inputs.Hobbit.packages.${pkgs.system}.hobbit
];
```
to `configuration.nix`
