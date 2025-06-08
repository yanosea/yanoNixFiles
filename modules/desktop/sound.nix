{
  # security
  security = {
    rtkit = {
      enable = true;
    };
  };
  # services
  services = {
    pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      jack = {
        enable = true;
      };
      pulse = {
        enable = true;
      };
    };
  };
}
