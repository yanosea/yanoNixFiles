{ pkgs, ... }:
{
  home = {
    packages = with pkgs; [
      cargo-cross
      cargo-make
      (fenix.combine [
        fenix.latest.toolchain
        fenix.targets.wasm32-unknown-unknown.latest.rust-std
        fenix.targets.wasm32-wasi.latest.rust-std
      ])
    ];
  };
}
