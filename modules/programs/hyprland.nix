{ inputs, ... }: {
  imports = [ inputs.hyprland.nixosModules.default ];
  # programs
  programs = {
    hyprland = {
      enable = true;
      xwayland = { enable = true; };
    };
    waybar = { enable = true; };
  };
}
