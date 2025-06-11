{ pkgs, ... }:
{
  home = {
    packages = with pkgs; [
      helix
      neovim
      vim
    ];
  };
}
