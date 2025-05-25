{ ... }:
{
  xdg = {
    configFile = {
      "git" = {
        source = ./git;
        recursive = true;
      };
    };
  };
}
