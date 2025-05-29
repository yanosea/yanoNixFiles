{ pkgs, ... }:
{
  home = {
    packages = with pkgs; [
      go
      goreleaser
      gotests
      mockgen
      wails
    ];
  };
}
