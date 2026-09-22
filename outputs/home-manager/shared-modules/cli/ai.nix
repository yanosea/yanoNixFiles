# home ai module
{ pkgs, ... }:
{
  # home
  home = {
    packages = with pkgs; [
      agy-acp-server
      antigravity-cli
      claude-code
      claude-powerline
      codex
      grok-build
      kiro-cli
      spec-kit
      toad
    ];
  };
}
