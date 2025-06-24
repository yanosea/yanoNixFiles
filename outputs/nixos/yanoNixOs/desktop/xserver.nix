# nixos desktop xserver module
{
  # services
  services = {
    xserver = {
      enable = true;
      autoRepeatDelay = 300;
      autoRepeatInterval = 30;
      videoDrivers = [ "nvidia" ];
    };
    libinput = {
      enable = true;
      mouse = {
        accelProfile = "flat";
      };
    };
  };
  # xdg
  xdg = {
    portal = {
      enable = true;
    };
  };
}
