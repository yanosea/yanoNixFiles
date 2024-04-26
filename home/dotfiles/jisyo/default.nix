{ ... }: {
  xdg = {
    configFile = {
      "jisyo" = {
        source = ./jisyo;
        recursive = true;
      };
    };
  };
}
