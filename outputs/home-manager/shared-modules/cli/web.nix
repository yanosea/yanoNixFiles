# home web module
{
  config,
  lib,
  pkgs,

  ...
}:
with lib;
let
  cfg = config.home.cli.web;
in
{
  options = {
    home = {
      cli = {
        web = {
          syncWebTools = mkOption {
            type = types.bool;
            default = if builtins.getEnv "EXPERIMENTAL_MODE" == "1" then false else true;
            description = "sync web development tools during activation";
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
          bun
          deno
          nodePackages_latest.nodejs
          nodePackages_latest.pnpm
          posting
          wget
          wrangler
          xh
        ];
      };
    }
    (mkIf cfg.syncWebTools {
      # home
      home = {
        activation = {
          syncWebTools =
            let
              denoPackages = [
                {
                  name = "denoflare";
                  url = "https://raw.githubusercontent.com/skymethod/denoflare/master/cli/cli.ts";
                  permissions = "--unstable-worker-options --allow-read --allow-net --allow-env --allow-run --allow-write --allow-import";
                }
              ];
              syncDenoTools = pkgs.writeShellScript "sync-deno-tools" ''
                set -euo pipefail
                export PATH="${pkgs.deno}/bin:$PATH"
                export DENO_INSTALL_ROOT="${config.home.homeDirectory}/.deno"
                echo "Syncing Deno tools..."
                ${builtins.concatStringsSep "\n" (
                  map (pkg: ''
                    echo "  Installing/updating ${pkg.name}..."
                    ${pkgs.deno}/bin/deno install --global ${pkg.permissions} --name ${pkg.name} --reload --force ${pkg.url}
                  '') denoPackages
                )}
              '';
              script = pkgs.writeShellScript "sync-web-tools" ''
                set -euo pipefail
                ${syncDenoTools}
              '';
            in
            config.lib.dag.entryAfter [ "writeBoundary" ] ''
              echo ""
              echo "update web development tools..."
              echo ""
              ${script}
              echo ""
            '';
        };
      };
    })
  ];
}
