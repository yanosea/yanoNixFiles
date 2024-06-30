{ ... }: {
  imports = [
    ../dotfiles
    ./dotfiles
  ];
  home = {
    username = "yanosea";
    homeDirectory = "/home/yanosea";
    stateVersion = "24.05";
  };
  programs = {
    git-credential-oauth = {
      enable = true;
    };
    home-manager = {
      enable = true;
    };
  };
}
