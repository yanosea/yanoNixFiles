# home ai module
{ lib, pkgs, ... }:
{
  # home
  home = {
    packages = with pkgs; [
      agentsview
      anthy
      antigravity-cli
      claude-code
      claude-history
      claude-powerline
      codex
      deja-vu
      grok-build
      graphify
      kiro-cli
      # yanoMac builds its own (programs.openclaw.package) with discord bundled
      # cli only, so leave out the darwin app bundle
      (lib.lowPrio (openclaw.override { openclaw-app = null; }))
      opencode
      spec-kit
    ];
  };
}
