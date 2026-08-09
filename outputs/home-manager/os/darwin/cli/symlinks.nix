# home symlinks module
{ username, lib, ... }:
{
  home = {
    activation = {
      # every ln here uses -n so that an existing symlink is replaced instead
      # of being followed (plain `ln -sf` would create the link *inside* it)
      linkDarwinSpecific = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        # create google drive symlink (adjust path as needed)
        if [ -d "$HOME/GoogleDrive/${username}" ]; then
          $DRY_RUN_CMD ln -sfn $HOME/GoogleDrive/${username} $HOME/google_drive
        fi
        # AquaSKK expects its config under ~/Library/Application Support, but
        # it's managed under ~/.config/AquaSKK for cross-platform consistency
        $DRY_RUN_CMD ln -sfn "$HOME/.config/AquaSKK" "$HOME/Library/Application Support/AquaSKK"
      '';
      # vesktop ignores XDG_CONFIG_HOME, so point the themes directory it does
      # read at the home-manager managed one. Linking the directory itself (not
      # each theme's resolved store path) keeps this valid across generations:
      # resolving store paths left dangling links behind once the old generation
      # was garbage collected, and `readlink -f` then aborted activation.
      linkVesktopThemes = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        vesktopThemeSrc="$HOME/.config/vesktop/themes"
        vesktopThemeDest="$HOME/Library/Application Support/vesktop/themes"
        if [ -d "$vesktopThemeSrc" ]; then
          $DRY_RUN_CMD mkdir -p "$(dirname "$vesktopThemeDest")"
          if [ -L "$vesktopThemeDest" ]; then
            $DRY_RUN_CMD rm -f "$vesktopThemeDest"
          elif [ -d "$vesktopThemeDest" ]; then
            # reclaim it only when vesktop left it empty, never drop real themes
            $DRY_RUN_CMD rmdir "$vesktopThemeDest" || true
          fi
          if [ -e "$vesktopThemeDest" ]; then
            echo "vesktop: $vesktopThemeDest is not empty, skipping theme link" >&2
          else
            $DRY_RUN_CMD ln -sfn "$vesktopThemeSrc" "$vesktopThemeDest"
          fi
        fi
      '';
    };
  };
}
