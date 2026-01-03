# home ai module
{ pkgs, ... }:
{
  # home
  home = {
    packages = with pkgs; [
      claude-code
      gemini-cli-bin
      spec-kit
    ];
  };
}
