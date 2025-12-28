# home shell module
{
  config,
  lib,
  pkgs,

  ...
}:
with lib;
let
  cfg = config.home.cli.shell;
in
{
  options = {
    home = {
      cli = {
        shell = {
          updateSheldonPlugins = mkOption {
            type = types.bool;
            default = if builtins.getEnv "EXPERIMENTAL_MODE" == "1" then false else true;
            description = "update Sheldon plugins during activation";
          };
        };
      };
    };
  };
  config = mkMerge [
    {
      # home
      home = {
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
      # programs
      programs = {
        direnv = {
          enable = true;
          nix-direnv = {
            enable = true;
          };
        };
        zsh = {
          enable = true;
          dotDir = "${config.xdg.configHome}/zsh";
          envExtra = ''source "$ZDOTDIR/env/init.zsh"'';
          initContent = ''source "$ZDOTDIR/rc/init.zsh"'';
        };
      };
    }
    (mkIf cfg.updateSheldonPlugins {
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
      };
    })
  ];
}
