{ pkgs, ... }: {
  home = {
    packages = with pkgs; [ delve go goreleaser gotests mockgen wails ];
  };
}
