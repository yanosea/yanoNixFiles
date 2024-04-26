{ ... }: {
  xdg = {
    configFile = {
      "lazygit" = {
        source = ./lazygit;
        recursive = true;
      };
    };
  };
}
