{ pkgs, ... }:
{
  # home
  home = {
    packages = with pkgs; [ jdk ];
  };
}
