{ inputs, ... }:
{
  imports = [ inputs.hyprland.nixosModules.default ];
  programs = {
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
