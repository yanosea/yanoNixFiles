{ pkgs, ... }: {
  # home
  home = { packages = with pkgs; [ xdg-utils ]; };
  # xdg
  xdg = { enable = true; };
}
