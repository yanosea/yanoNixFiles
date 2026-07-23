# home ai module
{ pkgs, ... }:
{
  # home
  home = {
    packages = with pkgs; [
      antigravity-cli
      claude-code
      kiro-cli
      spec-kit
    ];
  };
}
