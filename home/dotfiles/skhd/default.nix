{ ... }:
{
  xdg = {
    configFile = {
      "skhd" = {
        source = ./skhd;
        recursive = true;
      };
    };
  };
}
