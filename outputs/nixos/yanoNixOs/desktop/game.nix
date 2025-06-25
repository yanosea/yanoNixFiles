# nixos desktop game module
{
  # programs
  programs = {
    steam = {
      enable = true;
      dedicatedServer = {
        openFirewall = true;
      };
      localNetworkGameTransfers = {
        openFirewall = true;
      };
      remotePlay = {
        openFirewall = true;
      };
    };
  };
}
