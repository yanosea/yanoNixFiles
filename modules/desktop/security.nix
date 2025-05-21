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
  };
}
