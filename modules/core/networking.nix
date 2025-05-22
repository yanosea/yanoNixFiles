{ hostname, ... }:
{
  # networking
  networking = {
    hostName = hostname;
    networkmanager = {
      enable = true;
    };
    firewall = {
      enable = true;
    };
  };
  # systemd
  systemd = {
    services = {
      NetworkManager-wait-online = {
        enable = false;
      };
    };
  };
}
