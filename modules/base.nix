{ config, lib, pkgs, ... }:
# Consumers ship their tailscale auth key to /etc/nixos/secrets.nix on the VM
# (see install-infect in consumer deploy stacks). If the file is absent we
# silently fall back to no auth key, which means tailscaled will not register.
let
  secrets = if builtins.pathExists /etc/nixos/secrets.nix
            then import /etc/nixos/secrets.nix
            else { tailscaleAuthKey = null; };
in {
  networking.useDHCP = true;

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
    allowedUDPPorts = [ config.services.tailscale.port ];
    trustedInterfaces = [ "tailscale0" ];
    checkReversePath = "loose";
  };

  services.tailscale = {
    enable = true;
    useRoutingFeatures = "server";
    authKeyFile = lib.mkIf (secrets.tailscaleAuthKey != null) "/etc/tailscale/authkey";
  };

  environment.etc."tailscale/authkey" = lib.mkIf (secrets.tailscaleAuthKey != null) {
    text = secrets.tailscaleAuthKey;
    mode = "0400";
  };

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

  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    htop
    jq
  ];

  time.timeZone = lib.mkDefault "UTC";

  system.autoUpgrade = {
    enable = true;
    allowReboot = false;
  };

  system.stateVersion = "25.11";
}
