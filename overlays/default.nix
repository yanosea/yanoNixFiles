# overlays
inputs: [
  # rust
  (
    _: super:
    let
      pkgs = inputs.fenix.inputs.nixpkgs.legacyPackages.${super.stdenv.hostPlatform.system};
    in
    inputs.fenix.overlays.default pkgs pkgs
  )
  # packages
  ## mediaplayer
  (final: prev: {
    mediaplayer = inputs.mediaplayer.packages.${prev.stdenv.hostPlatform.system}.default;
  })
  ## wrangler
  (final: prev: {
    wrangler = inputs.wrangler.packages.${prev.stdenv.hostPlatform.system}.default;
  })
]
