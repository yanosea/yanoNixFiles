{ pkgs, ... }:
{
  # home
  home = {
    packages = with pkgs; [
      aider-chat
    ];
  };
}
