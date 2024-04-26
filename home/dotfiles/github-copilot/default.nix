{ ... }: {
  xdg = {
    configFile = {
      "github-copilot" = {
        source = ./github-copilot;
        recursive = true;
      };
    };
  };
}
