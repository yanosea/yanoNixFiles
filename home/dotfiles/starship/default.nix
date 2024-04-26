{ ... }: {
  xdg = {
    configFile = {
      "starship" = {
        source = ./starship;
        recursive = true;
      };
    };
  };
}
