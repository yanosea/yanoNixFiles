# home editor module
{ pkgs, ... }:
{
  # home
  home = {
    packages = with pkgs; [
      helix
      neovim
      vim
    ];
  };
}
