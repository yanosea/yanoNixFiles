# nixos desktop bluetooth configuration
{
  # hardware
  hardware = {
    bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings = {
        General = {
          ControllerMode = "dual";
          FastConnectable = true;
          Experimental = true;
        };
      };
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
