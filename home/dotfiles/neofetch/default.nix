{ ... }:
{
  xdg = {
    configFile = {
      "neofetch" = {
        source = ./neofetch;
        recursive = true;
      };
    };
  };
}
