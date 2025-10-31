# overlays
inputs: [
  # rust
  (
    _: super:
    let
      pkgs = inputs.fenix.inputs.nixpkgs.legacyPackages.${super.system};
    in
    inputs.fenix.overlays.default pkgs pkgs
  )
  # packages
  ## mediaplayer
  (final: prev: {
    mediaplayer = inputs.mediaplayer.packages.${prev.system}.default;
  })
  ## wrangler - use emrldnix flake with cachix for better cache hits
  (final: prev: {
    wrangler = inputs.wrangler.packages.${prev.system}.default;
  })
]
