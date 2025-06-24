{ pkgs, ... }:
{
  # home
  home = {
    packages = with pkgs; [
      bitwarden
      blender
      remmina
    ];
  };
}
