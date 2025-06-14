{ pkgs, ... }:
{
  # home
  home = {
    packages = with pkgs; [ nixfmt-rfc-style ];
  };
}
