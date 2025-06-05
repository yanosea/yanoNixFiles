{ config, pkgs, ... }:
{
  imports = [
    ../../dotfiles/gh
    ../../dotfiles/gh-copilot
    ../../dotfiles/git
    ../../dotfiles/github-copilot
    ../../dotfiles/lazygit
  ];
  home = {
    activation = {
      syncGitRepos =
        let
          repositories = [
            "github.com/tmux-plugins/tpm"
            "github.com/yanosea/cmf"
            "github.com/yanosea/jrp"
            "github.com/yanosea/mindnum"
            "github.com/yanosea/spotlike"
            "github.com/yanosea/yanoNixFiles"
            "github.com/yanosea/yanoPortfolio"
            "github.com/yurihs/waybar-media"
          ];
          script = pkgs.writeShellScript "sync-git-repos" ''
            set -euo pipefail
            export PATH=${pkgs.git}/bin:$PATH
            for repo in ${builtins.concatStringsSep " " repositories}; do
              echo "Processing $repo..."
              ${pkgs.ghq}/bin/ghq get --update "$repo"
            done
          '';
        in
        config.lib.dag.entryAfter [ "writeBoundary" ] ''
          echo ""
          echo "sync git repos..."
          echo ""
          ${script}
          echo ""
        '';
    };
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
