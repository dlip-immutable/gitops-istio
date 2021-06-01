{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { self
    , nixpkgs
    , flake-utils
    }:
    flake-utils.lib.eachDefaultSystem
      (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
        bootstrapCluster = with pkgs; writeScriptBin "bootstrap-cluster" ''
          set -euo pipefail
          kubectl create namespace flux-system || true
          eval $(${_1password}/bin/op signin imtbl)
          ${_1password}/bin/op list items --vault "Platform Ops" | op get item "gitops pgp key" --fields notesPlain | \
          kubectl create secret generic sops-gpg \
            --namespace=flux-system \
            --from-file=sops.asc=/dev/stdin
          ${fluxcd}/bin/flux bootstrap github \
            --owner=dlip-immutable \
            --repository=gitops-istio \
            --path=clusters/my-cluster \
            --personal
        '';
      in
      rec {
        inherit pkgs;
        defaultApp = apps.repl;
        apps = {
          repl = flake-utils.lib.mkApp
            {
              drv = with pkgs; writeShellScriptBin "repl" ''
                confnix=$(mktemp)
                echo "builtins.getFlake (toString $(git rev-parse --show-toplevel))" >$confnix
                trap "rm $confnix" EXIT
                nix repl $confnix
              '';
            };
          bootstrapCluster = flake-utils.lib.mkApp
            {
              drv = bootstrapCluster;
            };
        };
        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [
            _1password
            aws-iam-authenticator
            fluxcd
            gitAndTools.gh
            istioctl
            kubernetes-helm
            kubeval
            kustomize
            terraform_0_14
            yq
          ];
        };
      });
}
