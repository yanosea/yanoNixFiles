{ pkgs, ... }:
{
  # home
  home = {
    packages = with pkgs; [
      cmatrix
      cowsay
      figlet
      genact
      rig
      sl
      unimatrix
    ];
  };
}
