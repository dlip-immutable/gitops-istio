{
  description = "IMX Infrastructure";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-release.url = "github:NixOS/nixpkgs/release-20.09";
    flake-utils.url = "github:numtide/flake-utils";
    newrelic-istio-adapter-chart = {
      url = "github:newrelic/newrelic-istio-adapter";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, newrelic-istio-adapter-chart, nixpkgs-release }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs-release = import nixpkgs-release {
            inherit system;
            config.allowUnfree = true;
          };

          pkgs = import nixpkgs {
            inherit system;
            overlays = [];
            config.allowUnfree = true;
          };
        in
        rec {
          inherit pkgs;
          devShell = import ./shell.nix { inherit pkgs; };

          defaultApp = apps.repl;
          apps = {
            repl = flake-utils.lib.mkApp
              {
                drv = pkgs.writeShellScriptBin "repl" ''
                  confnix=$(mktemp)
                  echo "builtins.getFlake (toString $(git rev-parse --show-toplevel))" >$confnix
                  trap "rm $confnix" EXIT
                  nix repl $confnix
                '';
              };
          };
        });
}
