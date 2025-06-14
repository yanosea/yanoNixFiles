{ config, pkgs, ... }:
{
  # home
  home = {
    activation = {
      updateSheldonPlugins =
        let
          script = pkgs.writeShellScript "update-sheldon-plugins" ''
            set -euo pipefail
            export PATH=${pkgs.sheldon}/bin:$PATH
            sheldon lock --update
          '';
        in
        config.lib.dag.entryAfter [ "writeBoundary" ] ''
          echo ""
          echo "updating sheldon plugins..."
          echo ""
          ${script}
        '';
    };
    packages = with pkgs; [
      inshellisense
      sheldon
      starship
      tmux
      zellij
      zoxide
      zsh
    ];
  };
}
