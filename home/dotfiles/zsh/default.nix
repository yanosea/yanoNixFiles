{ ... }: {
  xdg = {
    configFile = {
      "zsh" = {
        source = ./zsh;
        recursive = true;
      };
    };
  };
}
