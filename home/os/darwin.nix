{ pkgs, ... }:
{
  imports = [
    ../config
  ];
  # home
  home = {
    packages = with pkgs; [
      xcode-install
    ];
  };
}
