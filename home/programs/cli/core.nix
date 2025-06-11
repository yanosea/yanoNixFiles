{ pkgs, ... }:
{
  home = {
    packages = with pkgs; [
      # core
      bat
      broot
      cron
      delta
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
