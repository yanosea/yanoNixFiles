{ inputs, pkgs, ... }:
{
  # home
  home = {
    packages = (
      with pkgs;
      [
        inputs.mediaplayer.packages.${pkgs.system}.default
        evince
        spotify
        totem
      ]
    );
  };
  # programs
  programs = {
    ncspot = {
      enable = true;
    };
    obs-studio = {
      enable = true;
    };
  };
  # services
  services = {
    easyeffects = {
      enable = true;
    };
  };
}
