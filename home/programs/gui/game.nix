{ pkgs, ... }:
{
  # home
  home = {
    packages = with pkgs; [
      discord
      discord-ptb
      steam
    ];
  };
}
