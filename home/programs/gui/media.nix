{ inputs, pkgs, ... }: {
  # home
  home = { packages = (with pkgs; [ totem evince spotify ]); };
  # programs
  programs = {
    ncspot = { enable = true; };
    obs-studio = { enable = true; };
  };
  # services
  services = { easyeffects = { enable = true; }; };
}
