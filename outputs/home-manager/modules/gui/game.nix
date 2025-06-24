{ pkgs, ... }:
{
  # home
  home = {
    packages = with pkgs; [
      discord
      steam
    ];
  };
}
