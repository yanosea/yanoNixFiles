{ ... }: {
  xdg = {
    configFile = {
      "sonic-pi.net" = {
        source = ./sonic-pi.net;
        recursive = true;
      };
    };
  };
}
