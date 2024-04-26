{ ... }: {
  xdg = {
    configFile = {
      "gh-copilot" = {
        source = ./gh-copilot;
        recursive = true;
      };
    };
  };
}
