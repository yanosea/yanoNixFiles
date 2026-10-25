# home ai module
{ pkgs, ... }:
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
      openclaw
      opencode
      spec-kit
    ];
  };
}
