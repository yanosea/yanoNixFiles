# home ai module
{ pkgs, ... }:
{
  # home
  home = {
    packages = with pkgs; [
      antigravity-cli
      claude-code
      spec-kit
    ];
  };
}
