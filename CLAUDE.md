# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Oracle Cloud NixOS infrastructure that provisions Always Free ARM instances and installs NixOS via nixos-infect. Intentionally separates Terraform (infrastructure provisioning) from nixos-infect (OS installation).

**Two VMs share the Always Free tier (4 OCPU / 24GB RAM / 200GB boot total):**

- **Root (`/`)** — Tailscale exit node in `sa-bogota-1` (1 OCPU, 6GB, 50GB boot)


## Commands

### Tailscale Exit Node (root directory)

All operations go through `just`:

```bash
just init               # terraform init
just oci-auth           # OCI session auth (sa-bogota-1 region, DEFAULT profile)
just plan               # terraform plan
just apply              # terraform apply
just destroy            # terraform destroy
just ip                 # Get instance public IP

just deploy             # Full: apply → wait 60s → install-infect
just install-infect     # Run nixos-infect on provisioned Ubuntu instance
just ssh                # SSH as root (post-installation)

just fetch-hardware-config  # Copy hardware-configuration.nix from server
just update-nixos           # Push flake config + rebuild on server

just check              # nix flake check
just fmt                # Format Nix files
just update             # nix flake update
```

## Architecture

**Deployment flow** (same for both VMs): `terraform apply` → Ubuntu 22.04 boots → `nixos-infect` converts Ubuntu in-place to NixOS (GRUB, no repartitioning) → auto-reboot → NixOS boots

### Tailscale Exit Node (root)

**Terraform** (`main.tf`, `variables.tf`, `outputs.tf`, `terraform.tf`):

- OCI provider with SecurityToken auth (tokens expire — re-auth with `just oci-auth`)
- VCN (10.0.0.0/16) + subnet (10.0.0.0/24) + internet gateway
- VM.Standard.A1.Flex instance (ARM64, 1 OCPU, 6GB RAM, 50GB boot) in sa-bogota-1
- Ubuntu 22.04 as base image (converted to NixOS by nixos-infect)

**NixOS** (`flake.nix`, `configuration.nix`):

- Tailscale exit node with NAT masquerading (tailscale0 → ens3)
- Firewall: SSH 22, Tailscale UDP 41641
- Auto-upgrades enabled, no auto-reboot

### Secrets

**Secrets** (`secrets.nix` — gitignored):

- Contains `{ tailscaleAuthKey = "<auth-key>" }`, conditionally imported with null fallback
- Each VM needs its own Tailscale auth key
- SSH key (Ed25519) duplicated in `variables.tf` and `configuration.nix` — keep in sync

## Key Constraints

- `system.stateVersion` in `configuration.nix` must match the initial install version — never change it
- SSH public key must be consistent between `variables.tf` (Terraform metadata) and `configuration.nix` (NixOS authorized_keys)
- External interface is `ens3` — used in NAT config (exit node only)
- Terraform state is local (no remote backend) — each directory has its own state
- `hardware-configuration.nix` is generated on the server, not in this repo — fetch it after first install
- Always Free tier resources are shared: 4 OCPU, 24GB RAM, 200GB boot across both VMs (currently using 3/4 OCPU, 18/24GB, 100/200GB)
- Tailscale Funnel requires ACL policy to allow funnel for the changedetection node
