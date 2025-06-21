{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    # TODO: Add wezterm as an input and build it from scratch without one from nixpkgs
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
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
        packages.default = pkgs.wezterm.overrideAttrs (oldAttrs: {
          patches =
            oldAttrs.patches or [ ]
            ++ builtins.map (name: "${self}/patches/${name}") (builtins.attrNames (builtins.readDir ./patches));
        });
      }
    );
}
