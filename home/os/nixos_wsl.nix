{ pkgs, ... }: {
  imports = [
    ../dotfiles/CorvusSKK
    ../dotfiles/glaze-wm
    ../dotfiles/PowerShell
    ../dotfiles/scoop
    ../dotfiles/UniGetUI
  ];
  home = {
    packages = with pkgs; [
      # cli
      cron
      # jokeey
      bsdgames
    ];
  };
}
