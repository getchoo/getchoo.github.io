{
  description = "seth's website";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pre-commit = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nixpkgs-stable.follows = "nixpkgs";
        flake-compat.follows = "";
      };
    };
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      imports = with inputs; [
        treefmt-nix.flakeModule
        pre-commit.flakeModule
      ];

      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      perSystem = {
        lib,
        pkgs,
        config,
        self',
        ...
      }: let
        nodejs-slim = pkgs.nodejs-slim_20; # this should be the current lts
        corepack = pkgs.corepack_20;

        enableAll = lib.flip lib.genAttrs (lib.const {enable = true;});
      in {
        treefmt = {
          projectRootFile = ".git/config";

          programs = enableAll ["alejandra" "deadnix" "prettier"];

          settings.global = {
            excludes = [
              "./node_modules/*"
              "./dist/*"
              "./.astro/*"
              "flake.lock"
              "pnpm-lock.yaml"
            ];
          };
        };

        pre-commit.settings.hooks =
          (enableAll [
            "actionlint"
            "eclint"
            "eslint"
            "nil"
            "statix"
            "treefmt"
          ])
          // {
            treefmt.package = config.treefmt.build.wrapper;
          };

        devShells.default = pkgs.mkShellNoCC {
          shellHook = config.pre-commit.installationScript;
          packages = [
            self'.formatter
            nodejs-slim
            # use pnpm from package.json
            corepack
          ];
        };
      };
    };
}
