{ ... }:
{
  xdg = {
    configFile = {
      "hammerspoon" = {
        source = ./hammerspoon;
        recursive = true;
      };
    };
  };
}
