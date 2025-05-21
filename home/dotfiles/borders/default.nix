{ pkgs, ... }:
{
  xdg = {
    configFile = {
      "borders" = {
        source = ./borders;
        recursive = true;
      };
    };
  };
}
