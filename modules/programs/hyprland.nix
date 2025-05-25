{ inputs, ... }:
{
  imports = [ inputs.hyprland.nixosModules.default ];
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
