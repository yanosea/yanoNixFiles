# home symlinks module
{ lib, ... }:
{
  # nixos wsl specific symbolic links
  home = {
    activation = {
      # this is just a memoization of the symlinks
      linkWslSpecific = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        # WSL-specific symlinks (uncomment and adjust paths as needed)
        # $DRY_RUN_CMD ln -sf <WINDOWS_WIN32YANK_PATH> $HOME/.local/bin/win32yank.exe
        # $DRY_RUN_CMD ln -sf <WINDOWS_GOOGLE_DRIVE_PATH> $HOME/google_drive
        # $DRY_RUN_CMD ln -sf <WINDOWS_HOME_PATH> $HOME/windows_home
      '';
    };
  };
}
