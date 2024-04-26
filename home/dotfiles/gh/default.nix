{ pkgs, ... }: {
  xdg = {
    configFile = {
      "gh" = {
        source = ./gh;
        recursive = true;
      };
    };
  };
  # programs
  programs = {
    gh = {
      enable = true;
      package = pkgs.gh;
      extensions = [ pkgs.gh-copilot ];
    };
  };
}
