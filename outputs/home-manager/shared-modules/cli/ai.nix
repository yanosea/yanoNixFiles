# home ai module
{ pkgs, ... }:
{
  # home
  home = {
    packages = with pkgs; [
      agentsview
      agy-acp-server
      anthy
      antigravity-cli
      claude-code
      claude-history
      claude-powerline
      codex
      grok-build
      kiro-cli
      openclaw
      spec-kit
      toad
    ];
  };
}
