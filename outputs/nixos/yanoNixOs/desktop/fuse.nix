# nixos desktop fuse module
{
  # boot
  boot = {
    kernelModules = [ "fuse" ];
  };
  # programs
  programs = {
    fuse = {
      userAllowOther = true;
    };
  };
  # services
  services = {
    udev = {
      extraRules = ''
        KERNEL=="fuse", GROUP="fuse", MODE="0666"
      '';
    };
  };
  # users
  users = {
    groups = {
      fuse = { };
    };
  };
}
