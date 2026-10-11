# home ai module
{ lib, pkgs, ... }:
{
  # home
  home = {
    packages = with pkgs; [
      agentsview
      agy-acp-server
      anthy
      antigravity-cli
      (claude-agent-acp.override { inherit (pkgs) claude-code; })
      claude-code
      claude-history
      claude-powerline
      codex
      # the npm test suite fails on darwin builders reading managed preferences
      ((codex-acp.override { inherit (pkgs) codex; }).overrideAttrs {
        doCheck = !stdenv.hostPlatform.isDarwin;
      })
      goose-cli
      grok-build
      kiro-cli
      minisign
      openclaw
      opencode
      spec-kit
      toad
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
