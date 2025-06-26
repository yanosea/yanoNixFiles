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
      '';
    };
  };
}
