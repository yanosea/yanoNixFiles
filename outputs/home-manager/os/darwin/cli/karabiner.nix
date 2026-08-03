# karabiner compile module
{ lib, ... }:
{
  home = {
    activation = {
      # compile karabiner.edn to karabiner.json on activation, since goku's
      # watcher service isn't enabled; must run after linkGeneration, when
      # the edn symlink is updated to the new generation
      compileKarabinerConfig = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        if [ -x /opt/homebrew/bin/goku ]; then
          $DRY_RUN_CMD /opt/homebrew/bin/goku
        fi
      '';
    };
  };
}
