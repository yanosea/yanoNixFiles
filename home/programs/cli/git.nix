{ pkgs, ... }:
{
  imports = [
    ../../dotfiles/gh
    ../../dotfiles/gh-copilot
    ../../dotfiles/git
    ../../dotfiles/github-copilot
    ../../dotfiles/lazygit
  ];
  home = {
    packages = with pkgs; [
      gh
      gh-dash
      ghq
      git-credential-oauth
      git-lfs
      github-cli
      lazygit
    ];
  };
}
