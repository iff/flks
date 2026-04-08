{
  description = "synced common flake dependencies";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-utils.url = "github:numtide/flake-utils";
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
        pkgs = nixpkgs.legacyPackages.${system};
        flupq = pkgs.writeScriptBin "flupq" ''
          #!${pkgs.zsh}/bin/zsh
          set -eu -o pipefail
          overrides=(
            --override-input nixpkgs github:NixOS/nixpkgs/${self.inputs.nixpkgs.rev}
            --override-input unstable github:NixOS/nixpkgs/${self.inputs.unstable.rev}
            --override-input flake-utils github:numtide/flake-utils/${self.inputs.flake-utils.rev}
          )
          # double quiet is nice, but it doesnt show anymore what inputs it actually did update
          # flake update $overrides --quiet --quiet $@
          flake update $overrides $@
        '';
        flup = pkgs.writeScriptBin "flup" ''
          #!${pkgs.zsh}/bin/zsh
          set -eu -o pipefail
          ${flupq}/bin/flupq $@
          echo 'Note that input overrides are purely based on input names, not their defined values.'
        '';
        env = pkgs.buildEnv {
          name = "flup";
          paths = [
            flup
            flupq
          ];
        };
      in
      {
        packages.default = env;
        devShells.default = pkgs.mkShellNoCC {
          packages = with pkgs; [
            nil
            nixfmt-rfc-style
            pinact
          ];
          shellHook = "";
        };
      }
    );
}
