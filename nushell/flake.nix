{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    nushell = {
      url = "github:nushell/nushell";
      flake = false;
    };
    reedline.url = "github:yuko1101/nixinized?dir=reedline";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      nushell,
      reedline,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
        patchedNushell = pkgs.applyPatches {
          name = "patched-nushell";
          src = nushell;
          patches = builtins.map (name: "${./patches}/${name}") (
            builtins.attrNames (builtins.readDir ./patches)
          );
        };
        src = pkgs.runCommand "nushell-src" { } ''
          mkdir -p $out
          cp -r ${patchedNushell}/* $out
          chmod +w $out/crates
          mkdir -p $out/crates/reedline
          cp -r ${reedline.packages.${system}.default}/* $out/crates/reedline
        '';
        cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
          inherit src;
          hash = "sha256-0T1oXv5x0CRwgmk2Y5BOw4Pk+d6Xfg/HfTKEQS0Ocmc=";
        };
        version = (builtins.fromTOML (builtins.readFile "${src}/Cargo.toml")).package.version;
      in
      {
        packages.nushell = pkgs.nushell.overrideAttrs (oldAttrs: {
          inherit src cargoDeps version;
          cargoBuildFlags = (oldAttrs.cargoBuildFlags or [ ]) ++ [
            "--features"
            "system-clipboard"
          ];
          doCheck = false;
        });
        packages.nu_plugin_polars = pkgs.nushellPlugins.polars.overrideAttrs (oldAttrs: {
          inherit src cargoDeps version;
        });
      }
    );
}
