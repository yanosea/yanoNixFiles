{ ... }:
{
  xdg = {
    configFile = {
      "wezterm" = {
        source = ./wezterm;
        recursive = true;
      };
    };
  };
}
