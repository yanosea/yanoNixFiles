{ pkgs, ... }:
{
  home = {
    packages = with pkgs; [
      cargo-cross
      cargo-make
      cargo-update
      rustup
    ];
  };
}
