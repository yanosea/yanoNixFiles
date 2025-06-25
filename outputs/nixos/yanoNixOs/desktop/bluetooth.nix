# nixos desktop bluetooth configuration
{
  # hardware
  hardware = {
    bluetooth = {
      enable = true;
    };
  };
  # services
  services = {
    # blueman
    blueman = {
      enable = true;
    };
  };
}
