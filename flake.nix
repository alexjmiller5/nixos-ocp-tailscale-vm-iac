{
  description = "OCI NixOS VM base — reusable NixOS module + Terraform module";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  };

  outputs = { self, nixpkgs }: {
    nixosModules.base = import ./modules/base.nix;
    # Terraform module is consumed via git:: source pointing at terraform/oci-vm/,
    # not via flake outputs.
  };
}
