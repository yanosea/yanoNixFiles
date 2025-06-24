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
