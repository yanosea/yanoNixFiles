# home git module
{
  config,
  lib,
  pkgs,

  ...
}:
with lib;
let
  cfg = config.home.cli.git;
in
{
  options = {
    home = {
      cli = {
        git = {
          syncGitRepos = mkOption {
            type = types.bool;
            default = if builtins.getEnv "EXPERIMENTAL_MODE" == "1" then false else true;
            description = "sync Git repositories during activation";
          };
        };
      };
    };
  };
  config = mkMerge [
    {
      # home
      home = {
        packages = with pkgs; [
          gh
          gh-copilot
          gh-dash
          ghq
          git-credential-oauth
          git-lfs
          github-cli
          gitlogue
          lazygit
        ];
      };
    }
    (mkIf cfg.syncGitRepos {
      # home
      home = {
        activation = {
          syncGitRepos =
            let
              repositories = [
                "github.com/dimdenGD/OldTweetDeck"
                "github.com/tmux-plugins/tpm"
                "github.com/yanosea/cmf"
                "github.com/yanosea/jrp"
                "github.com/yanosea/mindnum"
                "github.com/yanosea/spotlike"
                "github.com/yanosea/yanoNixFiles"
                "github.com/yanosea/yanoPortfolio"
              ];
              script = pkgs.writeShellScript "sync-git-repos" ''
                set -euo pipefail
                export PATH=${pkgs.git}/bin:$PATH
                for repo in ${builtins.concatStringsSep " " repositories}; do
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
      };
    })
  ];
}
