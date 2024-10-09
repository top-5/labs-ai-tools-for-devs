{
  description = "tree-sitter";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";

    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs = { self, nixpkgs, flake-utils, ...}@inputs:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          overlays = [
            inputs.devshell.overlays.default
          ];
          pkgs = import nixpkgs {
            inherit overlays system;
          };

        in rec {
          packages = rec {

            goBinary = pkgs.buildGoModule {
              pname = "tree-sitter-query";
              version = "0.1.0";
              src = ./.; # Assuming your Go code is in the same directory as the flake.nix

              buildInputs = [pkgs.tree-sitter];

              CGO_ENABLED = "1";

              CGO_CFLAGS = "-I${pkgs.tree-sitter}/include";
              
              # If you have vendored dependencies, use this:
              # vendorSha256 = null;
              
              # If you're not using vendored dependencies, compute the hash of your go.mod and go.sum
              # You can get this hash by first setting it to lib.fakeSha256,
              # then running the build and replacing it with the correct hash
              vendorHash = "sha256-ZAlkGegeFLqvHlGD1oA08NS216r6WsWFkajzxI+jLX4=";
              
              # Specify the package to build if it's not in the root of your project
              subPackages = [ "cmd/ts" ];
            };

            default = pkgs.writeShellScriptBin "entrypoint" ''
              export PATH=${pkgs.lib.makeBinPath [goBinary]}
              ts "$@"
            '';

          };

          devShells.default = pkgs.devshell.mkShell {
            name = "java-tree-sitter-shell";
            packages = [
              pkgs.tree-sitter
              pkgs.gcc
              (pkgs.clojure.override { jdk = pkgs.openjdk22; })
              pkgs.go # Added Golang
            ];
            commands = [
            ];
          };
        }
      );
}
