{ pkgs, ... }:
{
  home = {
    packages = with pkgs; [
      # jokeey
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
