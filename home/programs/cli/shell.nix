{ pkgs, ... }:
{
  home = {
    packages = with pkgs; [
      # shell
      inshellisense
      sheldon
      starship
      tmux
      zellij
      zoxide
      zsh
    ];
  };
}
