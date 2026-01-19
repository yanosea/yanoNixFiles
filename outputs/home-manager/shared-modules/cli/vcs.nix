# home vcs module
{
  config,
  lib,
  pkgs,

  ...
}:
with lib;
let
  cfg = config.home.cli.vcs;
in
{
  options = {
    home = {
      cli = {
        vcs = {
          syncRepos = mkOption {
            type = types.bool;
            default = if builtins.getEnv "EXPERIMENTAL_MODE" == "1" then false else true;
            description = "sync repositories during activation";
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
          jj-starship
          jjui
          jujutsu
          lazygit
          lazyjj
        ];
      };
    }
    (mkIf cfg.syncRepos {
      # home
      home = {
        activation = {
          syncRepos =
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
              script = pkgs.writeShellScript "sync-repos" ''
                set -euo pipefail
                export PATH=${pkgs.git}/bin:${pkgs.jujutsu}/bin:$PATH
                for repo in ${builtins.concatStringsSep " " repositories}; do
                  ${pkgs.ghq}/bin/ghq get --update "$repo"
                  repoPath="$HOME/ghq/$repo"
                  if [ ! -d "$repoPath/.jj" ]; then
                    (cd "$repoPath" && jj git init --colocate)
                  fi
                  # track default remote branch (main or master) and fetch
                  (cd "$repoPath" && {
                    if jj bookmark list --all 2>/dev/null | grep -q "main@origin"; then
                      jj bookmark track main --remote origin 2>/dev/null || true
                    elif jj bookmark list --all 2>/dev/null | grep -q "master@origin"; then
                      jj bookmark track master --remote origin 2>/dev/null || true
                    fi
                    jj git fetch 2>/dev/null || true
                  })
                done
              '';
            in
            config.lib.dag.entryAfter [ "writeBoundary" ] ''
              echo ""
              echo "sync repos..."
              echo ""
              ${script}
              echo ""
            '';
        };
      };
    })
  ];
}
