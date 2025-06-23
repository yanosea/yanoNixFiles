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
          echo "update sheldon plugins..."
          echo ""
          ${script}
          echo ""
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
