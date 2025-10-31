# nixos desktop hyprland module
{ ... }:
{
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
