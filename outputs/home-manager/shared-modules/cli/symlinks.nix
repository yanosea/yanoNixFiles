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
        $DRY_RUN_CMD ln -sf $HOME/ghq/github.com/yanosea/yanoNixFiles/ops/scripts/common/installChromeDevtoolsMcp.sh $HOME/.local/bin/installChromeDevtoolsMcp
        $DRY_RUN_CMD ln -sf $HOME/ghq/github.com/yanosea/yanoNixFiles/ops/scripts/common/installContext7Mcp.sh $HOME/.local/bin/installContext7Mcp
        $DRY_RUN_CMD ln -sf $HOME/ghq/github.com/yanosea/yanoNixFiles/ops/scripts/common/installGitEmojiPrefixTemplate.sh $HOME/.local/bin/installGitEmojiPrefixTemplate
        $DRY_RUN_CMD ln -sf $HOME/ghq/github.com/yanosea/yanoNixFiles/ops/scripts/common/installNixFmtPreCommitHook.sh $HOME/.local/bin/installNixFmtPreCommitHook
        $DRY_RUN_CMD ln -sf $HOME/ghq/github.com/yanosea/yanoNixFiles/ops/scripts/common/uninstallChromeDevtoolsMcp.sh $HOME/.local/bin/uninstallChromeDevtoolsMcp
        $DRY_RUN_CMD ln -sf $HOME/ghq/github.com/yanosea/yanoNixFiles/ops/scripts/common/uninstallContext7Mcp.sh $HOME/.local/bin/uninstallContext7Mcp
        # create vim configuration symlink
        $DRY_RUN_CMD ln -sf $XDG_CONFIG_HOME/vim $HOME/.vim
      '';
    };
  };
}
