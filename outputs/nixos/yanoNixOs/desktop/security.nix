# nixos desktop security module
{ ... }:
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
        greetd = {
          enableGnomeKeyring = true;
        };
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
  };
}
