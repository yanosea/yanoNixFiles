# overlays
inputs: [
  # rust
  inputs.fenix.overlays.default
  # packages
  ## mediaplayer
  (final: prev: {
    mediaplayer = inputs.mediaplayer.packages.${prev.system}.default;
  })
]
