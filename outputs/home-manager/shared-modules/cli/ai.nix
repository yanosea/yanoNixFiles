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
      (lib.lowPrio openclaw)
      opencode
      spec-kit
    ];
  };
}
