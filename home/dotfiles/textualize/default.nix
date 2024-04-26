{ ... }: {
  xdg = {
    configFile = {
      "textualize" = {
        source = ./textualize;
        recursive = true;
      };
    };
  };
}
