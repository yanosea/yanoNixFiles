{
  inputs,
  pkgs,
  lib,
  ...
}: {
  imports = [
    inputs.lanzaboote.nixosModules.lanzaboote
  ];

  # environment
  environment = {
    systemPackages = with pkgs; [
      sbctl
    ];
  };

  # boot
  boot = {
    loader = {
      systemd-boot.enable = lib.mkForce false;
    };
    lanzaboote = {
      enable = true;
      pkiBundle = "/etc/secureboot";
    };
  };
}
