inputs: [
  inputs.fenix.overlays.default
  (final: prev: {
    mediaplayer = inputs.mediaplayer.packages.${prev.system}.default;
  })
]
