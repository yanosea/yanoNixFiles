# home core module
{ pkgs, ... }:
{
  # home
  home = {
    packages = with pkgs; [
      bat
      broot
      cron
      delta
      eza
      fd
      ffmpeg
      fzf
      lf
      lsd
      ripgrep
      trash-cli
      tree
      unzip
      yazi
    ];
  };
}
