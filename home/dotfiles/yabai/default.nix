{ ... }:
{
  xdg = {
    configFile = {
      "yabai" = {
        source = ./yabai;
        recursive = true;
      };
    };
  };
}
