{ ... }: {
  xdg = {
    configFile = {
      "sheldon" = {
        source = ./sheldon;
        recursive = true;
      };
    };
  };
}
