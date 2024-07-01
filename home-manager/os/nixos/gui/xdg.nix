{ pkgs, ... }: {
  # xdg
  xdg = {
    enable = true;
  };
  # home
  home = {
    packages = with pkgs; [ xdg-utils ];
  };
}
