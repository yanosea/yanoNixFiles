{ pkgs, ... }:
{
  imports = [
    ../dotfiles/CorvusSKK
    ../dotfiles/glzr
    ../dotfiles/PowerShell
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
