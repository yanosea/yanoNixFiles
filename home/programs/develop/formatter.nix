{ pkgs, ... }: {
  home = {
    packages = with pkgs; [ nixfmt-classic shfmt stylua taplo treefmt ];
  };
}
