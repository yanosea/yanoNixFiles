# home go module
{ config, pkgs, ... }:
{
  # home
  home = {
    activation = {
      syncGoPackages =
        let
          goPackages = [
            "github.com/arrow2nd/jisyo@latest"
            "github.com/giannimassi/trello-tui@latest"
            "github.com/koki-develop/clive@latest"
            "github.com/nao1215/gup@latest"
            "github.com/sheepla/longgopher@latest"
            "github.com/sheepla/og@latest"
            "github.com/skanehira/rtty@latest"
            "github.com/Songmu/gocredits/cmd/gocredits@latest"
            "github.com/wadey/gocovmerge@latest"
            "github.com/yanosea/jrp/v2/app/presentation/api/jrp-server@latest"
            "github.com/yanosea/jrp/v2/app/presentation/cli/jrp@latest"
            "github.com/yanosea/mindnum/v2/app/presentation/cli/mindnum@latest"
          ];
          script = pkgs.writeShellScript "sync-go-packages" ''
            set -euo pipefail
            export GOPATH="$HOME/go"
            export GOBIN="$GOPATH/bin"
            export PATH="${pkgs.go}/bin:$GOBIN:$PATH"
            for pkg in ${builtins.concatStringsSep " " goPackages}; do
              ${pkgs.go}/bin/go install "$pkg"
            done
            if [ -x "$GOBIN/gup" ]; then
              echo "found gup at $GOBIN/gup, running update..."
              "$GOBIN/gup" update
            fi
          '';
        in
        config.lib.dag.entryAfter [ "writeBoundary" ] ''
          echo ""
          echo "update go packages..."
          echo ""
          ${script}
          echo ""
        '';
    };
    packages = with pkgs; [
      cobra-cli
      go-swag
      go
      goreleaser
      gotests
      gotools
      mockgen
      wails
    ];
  };
}
