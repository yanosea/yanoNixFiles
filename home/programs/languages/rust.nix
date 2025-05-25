{ pkgs, ... }:
{
  home = {
    packages = with pkgs; [
      cargo
      cargo-cross
      cargo-make
      cargo-update
      rustfmt
    ];
  };
}
