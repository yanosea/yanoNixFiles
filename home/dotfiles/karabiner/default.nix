{ ... }: {
  xdg = {
    configFile = {
      "karabiner" = {
        source = ./karabiner;
        recursive = true;
      };
    };
  };
}
