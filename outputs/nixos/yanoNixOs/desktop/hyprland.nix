# nixos desktop hyprland module
{ inputs, ... }:
{
  imports = [ inputs.hyprland.nixosModules.default ];
  # programs
  programs = {
    dconf = {
      enable = true;
    };
    hyprland = {
      enable = true;
      xwayland = {
        enable = true;
      };
    };
    waybar = {
      enable = true;
    };
  };
}
