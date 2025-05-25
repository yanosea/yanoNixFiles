{ ... }:
{
  xdg = {
    configFile = {
      "dolphin" = {
        source = ./dolphin;
        recursive = true;
      };
    };
  };
}
