# home symlinks module
{ lib, ... }:
{
  home = {
    activation = {
      linkNixosScripts = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        # create .local/bin directory if it doesn't exist
        $DRY_RUN_CMD mkdir -p $HOME/.local/bin
        # create symbolic links to nixos-specific scripts
        $DRY_RUN_CMD ln -sf $HOME/ghq/github.com/yanosea/yanoNixFiles/ops/scripts/nixos/check-recording.sh $HOME/.local/bin/check-recording
        $DRY_RUN_CMD ln -sf $HOME/ghq/github.com/yanosea/yanoNixFiles/ops/scripts/nixos/ime.sh $HOME/.local/bin/ime
        $DRY_RUN_CMD ln -sf $HOME/ghq/github.com/yanosea/yanoNixFiles/ops/scripts/nixos/ModTheSpire.sh $HOME/.local/bin/ModTheSpire
        $DRY_RUN_CMD ln -sf $HOME/ghq/github.com/yanosea/yanoNixFiles/ops/scripts/nixos/wallpaper-engine.sh $HOME/.local/bin/wallpaper-engine
      '';
    };
  };
}
