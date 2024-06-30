{
  # services
  services = {
    gnome = {
      gnome-keyring = {
        enable = true;
      };
    };
  };
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
        swaylock = {
          text = "auth include login";
        };
      };
    };
  };
}
