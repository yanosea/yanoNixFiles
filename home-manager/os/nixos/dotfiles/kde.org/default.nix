{ ... }: {
  xdg.configFile."kde.org" = {
    source = ./kde.org;
    recursive = true;
  };
}
