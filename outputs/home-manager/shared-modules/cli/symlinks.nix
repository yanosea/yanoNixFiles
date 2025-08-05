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
        $DRY_RUN_CMD ln -sf $HOME/ghq/github.com/yanosea/yanoNixFiles/ops/scripts/common/installGitEmojiPrefixTemplate $HOME/.local/bin/installGitEmojiPrefixTemplate
        $DRY_RUN_CMD ln -sf $HOME/ghq/github.com/yanosea/yanoNixFiles/ops/scripts/common/installNixFmtPreCommitHook $HOME/.local/bin/installNixFmtPreCommitHook
        $DRY_RUN_CMD ln -sf $HOME/ghq/github.com/yanosea/yanoNixFiles/ops/scripts/common/installNixFmtPreCommitHook $HOME/.local/bin/installSerenaMcp
        $DRY_RUN_CMD ln -sf $HOME/ghq/github.com/yanosea/yanoNixFiles/ops/scripts/common/installNixFmtPreCommitHook $HOME/.local/bin/uninstallSerenaMcp
        # create vim configuration symlink
        $DRY_RUN_CMD ln -sf $XDG_CONFIG_HOME/vim $HOME/.vim
      '';
    };
  };
}
