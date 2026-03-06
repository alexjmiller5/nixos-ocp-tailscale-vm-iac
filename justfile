# Oracle Cloud Infrastructure Management

# Show available commands
default:
    @just --list

# Initialize Terraform
init:
    terraform init

# Authenticate OCI session with default region and profile
oci-auth:
    oci session authenticate --region sa-bogota-1 --profile-name default

# Plan infrastructure changes
plan:
    terraform plan

# Apply infrastructure changes
apply:
    terraform apply

# Destroy infrastructure
destroy:
    terraform destroy

# Get instance IP
ip:
    @terraform output -raw instance_public_ip

# Check Nix flake
check:
    nix flake check

# Update flake inputs (gets latest commits for the specified nixpkgs branch)
update:
    nix flake update

# Format Nix files
fmt:
    nix fmt

# SSH into Ubuntu instance (before NixOS installation)
ssh:
    #!/usr/bin/env bash
    ssh oci-vm

# Install NixOS via nixos-infect
install-infect:
    #!/usr/bin/env bash
    set -euo pipefail
    INSTANCE_IP=$(terraform output -raw instance_public_ip)

    echo "==> Uploading config..."
    ssh ubuntu@$INSTANCE_IP 'sudo mkdir -p /etc/nixos'
    scp configuration.nix secrets.nix ubuntu@$INSTANCE_IP:/tmp/
    ssh ubuntu@$INSTANCE_IP 'sudo cp /tmp/configuration.nix /tmp/secrets.nix /etc/nixos/'

    echo "==> Running nixos-infect..."
    ssh ubuntu@$INSTANCE_IP 'curl https://raw.githubusercontent.com/elitak/nixos-infect/master/nixos-infect | sudo NIXOS_IMPORT=./configuration.nix NIX_CHANNEL=nixos-25.11 bash -x 2>&1 | tee /tmp/infect.log'

    echo ""
    echo "System will reboot automatically into NixOS."
    echo "Wait 2-3 minutes, then: just ssh"

# Copy hardware-configuration.nix from server (run after first install)
fetch-hardware-config:
    #!/usr/bin/env bash
    INSTANCE_IP=$(terraform output -raw instance_public_ip)
    scp root@$INSTANCE_IP:/etc/nixos/hardware-configuration.nix .
    echo "Saved hardware-configuration.nix locally for flake-based rebuilds"

# Update NixOS configuration on running instance via flake
update-nixos:
    #!/usr/bin/env bash
    set -euo pipefail
    INSTANCE_IP=$(terraform output -raw instance_public_ip)
    echo "Copying flake to $INSTANCE_IP..."
    rsync -av --exclude='.terraform' --exclude='terraform.tfstate*' --exclude='*.tfvars' . root@$INSTANCE_IP:/etc/nixos/
    ssh root@$INSTANCE_IP "cd /etc/nixos && nixos-rebuild switch --flake .#oci-vm"