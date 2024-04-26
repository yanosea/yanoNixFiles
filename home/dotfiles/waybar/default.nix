{ ... }: {
  xdg = {
    configFile = {
      "waybar" = {
        source = ./waybar;
        recursive = true;
      };
    };
  };
}
