{ config, ... }:
{
  xdg = {
    configFile = {
      "vim" = {
        source = ./vim;
        recursive = true;
      };
    };
  };
}
