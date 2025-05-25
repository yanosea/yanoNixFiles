{ ... }:
{
  xdg = {
    configFile = {
      "bash" = {
        source = ./bash;
        recursive = true;
      };
    };
  };
}
