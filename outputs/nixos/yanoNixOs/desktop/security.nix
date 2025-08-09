# nixos desktop security module
{ pkgs, username, ... }:
{
  # programs
  programs = {
    seahorse = {
      enable = true;
    };
  };
  # security
  security = {
    polkit = {
      enable = true;
    };
    pam = {
      services = {
        login = {
          enableGnomeKeyring = true;
        };
      };
    };
  };
  # services
  services = {
    gnome = {
      gnome-keyring = {
        enable = true;
      };
    };
    greetd = {
      enable = true;
      settings = {
        default_session = {
          command = ''
            ${pkgs.tuigreet}/bin/tuigreet --time --cmd Hyprland
          '';
          user = username;
        };
      };
    };
  };
}
