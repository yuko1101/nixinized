{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    reedline = {
      url = "github:nushell/reedline";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      reedline,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
      in
      {
        packages.default = pkgs.applyPatches {
          name = "patched-reedline";
          src = reedline;
          patches = builtins.map (name: "${./patches}/${name}") (
            builtins.attrNames (builtins.readDir ./patches)
          );
        };
      }
    );
}
