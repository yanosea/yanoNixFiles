# home symlinks module
{ username, lib, ... }:
{
  home = {
    activation = {
      linkDarwinSpecific = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        # create google drive symlink (adjust path as needed)
        if [ -d "$HOME/GoogleDrive/${username}" ]; then
          $DRY_RUN_CMD ln -sf $HOME/GoogleDrive/${username} $HOME/google_drive
        fi
        # AquaSKK expects its config under ~/Library/Application Support, but
        # it's managed under ~/.config/AquaSKK for cross-platform consistency
        $DRY_RUN_CMD ln -sf "$HOME/.config/AquaSKK" "$HOME/Library/Application Support/AquaSKK"
      '';
      # vesktop ignores XDG_CONFIG_HOME; link each theme's resolved nix
      # store path (not the ~/.config symlink, to avoid a relink loop)
      linkVesktopThemes = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        if [ -d "$HOME/.config/vesktop/themes" ]; then
          $DRY_RUN_CMD mkdir -p "$HOME/Library/Application Support/vesktop/themes"
          for theme in "$HOME/.config/vesktop/themes"/*; do
            target="$(readlink -f "$theme")"
            $DRY_RUN_CMD ln -sf "$target" "$HOME/Library/Application Support/vesktop/themes/$(basename "$theme")"
          done
        fi
      '';
    };
  };
}
