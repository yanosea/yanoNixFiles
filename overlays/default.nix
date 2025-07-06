# overlays
inputs: [
  # rust
  inputs.fenix.overlays.default
  # packages
  ## mediaplayer
  (final: prev: {
    mediaplayer = inputs.mediaplayer.packages.${prev.system}.default;
  })
  # quickshell
  (final: prev: {
    quickshell = inputs.quickshell.packages.${prev.system}.default;
  })
]
