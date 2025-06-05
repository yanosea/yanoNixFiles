{ pkgs, ... }:
{
  imports = [
    ../../dotfiles/sheldon
    ../../dotfiles/starship
    ../../dotfiles/tmux
    ../../dotfiles/zellij
    ../../dotfiles/zsh
  ];
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
