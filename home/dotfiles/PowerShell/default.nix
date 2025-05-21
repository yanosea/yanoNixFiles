{ ... }:
{
  xdg = {
    configFile = {
      "PowerShell" = {
        source = ./PowerShell;
        recursive = true;
      };
    };
  };
}
