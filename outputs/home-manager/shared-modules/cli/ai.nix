# home ai module
{ pkgs, ... }:
{
  # home
  home = {
    packages = with pkgs; [
      aider-chat
      claude-code
      gemini-cli
      opencode
    ];
  };
}
