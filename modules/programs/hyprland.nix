{ inputs, ... }: {
  imports = [
    inputs.hyprland.nixosModules.default
  ];
  # programs
  programs = {
    hyprland = {
      enable = true;
    };
  };
  # services
  services = {
    xremap = {
      withWlroots = true;
    };
  };
}
