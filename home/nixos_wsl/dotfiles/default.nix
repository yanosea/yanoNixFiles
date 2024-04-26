{ pkgs, ... }: {
  imports = [
    ./CorvusSKK
    ./glaze-wm
    ./PowerShell
    ./scoop
  ];
  home.packages = with pkgs; [
    sheldon
  ];
}
