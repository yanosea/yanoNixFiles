{ ... }: {
  xdg = {
    configFile = {
      "tmux" = {
        source = ./tmux;
        recursive = true;
      };
    };
  };
}
