{ pkgs, ... }: {
  imports = [
    ../../dotfiles/helix
    ../../dotfiles/lvim
    ../../dotfiles/nvim
    ../../dotfiles/vim
  ];
  home = { packages = with pkgs; [ helix lunarvim neovim vim ]; };
}
