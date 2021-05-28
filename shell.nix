{ pkgs ? import <nixpkgs> { } }:

with pkgs;

mkShell {
  buildInputs = [ terraform_0_14 kubernetes-helm gitAndTools.gh aws-iam-authenticator istioctl fluxcd kustomize yq kubeval ];
}
