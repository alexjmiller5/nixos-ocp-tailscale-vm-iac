{ config, pkgs, lib, ... }:

let
  secrets = if builtins.pathExists ./secrets.nix
            then import ./secrets.nix
            else { tailscaleAuthKey = null; };
in {
  # Networking
  networking.hostName = "oci-vm";
  networking.useDHCP = true;

  # Firewall configuration for Tailscale exit node
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
    allowedUDPPorts = [ config.services.tailscale.port ];
    trustedInterfaces = [ "tailscale0" ];
    checkReversePath = "loose";
  };

  # NAT for exit node (masquerade traffic from Tailscale to internet)
  networking.nat = {
    enable = true;
    externalInterface = "ens3";
    internalInterfaces = [ "tailscale0" ];
  };

  # Tailscale exit node
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "server";
    authKeyFile = lib.mkIf (secrets.tailscaleAuthKey != null) "/etc/tailscale/authkey";
    extraUpFlags = [ "--advertise-exit-node" ];
  };

  environment.etc."tailscale/authkey" = lib.mkIf (secrets.tailscaleAuthKey != null) {
    text = secrets.tailscaleAuthKey;
    mode = "0400";
  };

  # SSH
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
    };
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO7ZCS39YKZ+E/U0aFXe6qfBTfPOgT6NWN7LoOddv7/0"
  ];

  # Packages
  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    htop
  ];

  time.timeZone = "America/Bogota";

  system.autoUpgrade = {
    enable = true;
    allowReboot = false;
  };

  system.stateVersion = "25.11";
}
