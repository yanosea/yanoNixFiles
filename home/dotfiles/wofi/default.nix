{ ... }:
{
  xdg = {
    configFile = {
      "wofi" = {
        source = ./wofi;
        recursive = true;
      };
    };
  };
}
