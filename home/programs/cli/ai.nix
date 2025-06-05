{ pkgs, ... }:
{
  home = {
    packages = with pkgs; [
      # ai
      aider-chat
    ];
  };
}
