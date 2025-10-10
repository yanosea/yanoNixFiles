# home symlinks module
{ lib, ... }:
{
  # home
  home = {
    activation = {
      linkScripts = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        # create .local/bin directory if it doesn't exist
        $DRY_RUN_CMD mkdir -p $HOME/.local/bin
        # create symbolic links to scripts
        $DRY_RUN_CMD ln -sf $HOME/ghq/github.com/yanosea/yanoNixFiles/ops/scripts/common/installCcSdd.sh $HOME/.local/bin/installCcSdd
        $DRY_RUN_CMD ln -sf $HOME/ghq/github.com/yanosea/yanoNixFiles/ops/scripts/common/installChromeDevtoolsMcp.sh $HOME/.local/bin/installChromeDevtoolsMcp
        $DRY_RUN_CMD ln -sf $HOME/ghq/github.com/yanosea/yanoNixFiles/ops/scripts/common/installGitEmojiPrefixTemplate.sh $HOME/.local/bin/installGitEmojiPrefixTemplate
        $DRY_RUN_CMD ln -sf $HOME/ghq/github.com/yanosea/yanoNixFiles/ops/scripts/common/installNixFmtPreCommitHook.sh $HOME/.local/bin/installNixFmtPreCommitHook
        $DRY_RUN_CMD ln -sf $HOME/ghq/github.com/yanosea/yanoNixFiles/ops/scripts/common/installSerenaMcp.sh $HOME/.local/bin/installSerenaMcp
        $DRY_RUN_CMD ln -sf $HOME/ghq/github.com/yanosea/yanoNixFiles/ops/scripts/common/uninstallCcSdd.sh $HOME/.local/bin/uninstallCcSdd
        $DRY_RUN_CMD ln -sf $HOME/ghq/github.com/yanosea/yanoNixFiles/ops/scripts/common/uninstallChromeDevtoolsMcp.sh $HOME/.local/bin/uninstallChromeDevtoolsMcp
        $DRY_RUN_CMD ln -sf $HOME/ghq/github.com/yanosea/yanoNixFiles/ops/scripts/common/uninstallSerenaMcp.sh $HOME/.local/bin/uninstallSerenaMcp
        # create vim configuration symlink
        $DRY_RUN_CMD ln -sf $XDG_CONFIG_HOME/vim $HOME/.vim
      '';
    };
  };
}
