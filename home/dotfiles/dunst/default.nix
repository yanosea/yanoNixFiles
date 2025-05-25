{ ... }:
{
  xdg = {
    configFile = {
      "dunst" = {
        source = ./dunst;
        recursive = true;
      };
    };
  };
}
