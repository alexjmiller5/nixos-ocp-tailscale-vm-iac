# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Reusable building blocks for deploying NixOS to Oracle Cloud Infrastructure (OCI) Always Free ARM VMs. This repo is a **library**, not a deploy stack — it does not provision any VM by itself.

**Two outputs:**

1. **Nix flake** — exports `nixosModules.base`: SSH (root key-only), Tailscale daemon, firewall basics, auto-upgrades, sensible defaults. Consumers add their own service modules on top.
2. **Terraform module** at `terraform/oci-vm/` — provisions one OCI Always Free ARM instance with its own VCN/subnet/IGW. Consumers reference via `module "vm" { source = "git::https://github.com/alexjmiller5/nixos-oci-vm.git//terraform/oci-vm?ref=main" }`.

Deployment flow (executed by consuming repos, not here): `terraform apply` provisions Ubuntu 22.04 ARM → `nixos-infect` converts in-place to NixOS 25.11 → consumer's flake.nix wires `base` + service module(s) + hardware-configuration → `nixos-rebuild switch`.

## Architecture

### `modules/base.nix`

Imported by every consumer's deploy flake. Declares:

- `services.openssh` (root key-only, no password)
- `services.tailscale` (server routing features, optional authKeyFile sourced from `/etc/nixos/secrets.nix` if present)
- `networking.firewall` (TCP 22 + tailscale UDP, `tailscale0` trusted, reverse-path loose)
- `networking.useDHCP = true`
- `system.autoUpgrade.enable = true; allowReboot = false`
- `system.stateVersion = "25.11"` (locked — never change)
- Root SSH key authorized
- `time.timeZone` defaults to `UTC` via `lib.mkDefault` — consumers override

The module does **not** set `networking.hostName` — each consumer's deploy flake provides it.

### `terraform/oci-vm/`

Standalone Terraform module that creates VCN + subnet + IGW + instance. Variables:

- `compartment_id` (required), `region` (default `us-ashburn-1`)
- `vcn_cidr`, `subnet_cidr` — picked per consumer to avoid overlap
- `shape`, `ocpus`, `memory_gb`, `boot_volume_size_gb` — defaults match Always Free ARM
- `availability_domain_index` (default `0`) — override if Always Free quota lives in a non-zero AD in your region
- `display_name`, `ssh_public_key`

Outputs: `instance_public_ip`, `instance_ocid`.

## Consumers

- `notion-task-burndown-chart` — burndown chart service VM (1 OCPU / 6 GB / 50 GB)
- `change-detection-deployment` (to be renamed `changedetection.io-tailscale-nixos-module`) — changedetection.io VM (2 OCPU / 12 GB / 50 GB)
- `tailscale-exit-node-nixos-module` — module repo only (no deploy stack); composed into other deploys when an exit-node is wanted

## Key Constraints

- `system.stateVersion` in `modules/base.nix` must remain `25.11`. Never change once an installed VM exists with that value.
- Root SSH ed25519 key is hardcoded — change it here and re-deploy every VM if it ever rotates.
- Always Free tier shares 4 OCPU / 24 GB RAM / 200 GB boot across all instances in the tenancy. Sum across consumers.
