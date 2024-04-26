{ ... }: {
  xdg = {
    configFile = {
      "raycast" = {
        source = ./raycast;
        recursive = true;
      };
    };
  };
}
