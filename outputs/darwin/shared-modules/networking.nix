# darwin networking module
{ hostname, ... }:
{
  # networking
  networking = {
    applicationFirewall = {
      enable = true;
      allowSigned = true;
      allowSignedApp = true;
      enableStealthMode = false;
    };
    hostName = hostname;
  };
}
