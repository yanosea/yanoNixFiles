{ pkgs, ... }: {
  home = { packages = with pkgs; [ nixfmt-classic stylua taplo treefmt ]; };
}
