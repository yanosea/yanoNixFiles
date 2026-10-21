# home ai module
{ lib, pkgs, ... }:
{
  # home
  home = {
    packages = with pkgs; [
      agentsview
      anthy
      antigravity-cli
      deja-vu
      grok-build
      graphify
      kiro-cli
      minisign
      openclaw
      opencode
      spec-kit
    ];
    activation.syncHappier = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      if [ -z "''${DRY_RUN_CMD:-}" ]; then
        PATH="${
          lib.makeBinPath [
            pkgs.bash
            pkgs.curl
            pkgs.minisign
            pkgs.coreutils
            pkgs.gnutar
            pkgs.gzip
            pkgs.gawk
            pkgs.gnugrep
            pkgs.procps
          ]
        }:$PATH" \
          ${pkgs.python3}/bin/python3 ${../../../../configs/agents/remote-control.py} sync
      fi
    '';
  };
}
