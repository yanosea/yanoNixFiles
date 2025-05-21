{ pkgs, ... }:
{
  imports = [
    ../../dotfiles/helix
    ../../dotfiles/nvim
    ../../dotfiles/vim
  ];
  home = {
    packages = with pkgs; [
      helix
      neovim
      vim
    ];
  };
}
