{ pkgs, ... }:
{
  # home
  home = {
    packages = with pkgs; [
      claude-code
      aider-chat
    ];
  };
}
