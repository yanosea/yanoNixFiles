# nix latest functions
nix-latest() {
  # show help if no arguments provided
  if [ $# -eq 0 ]; then
    nix-latest help
    return 0
  fi
  # check subcommand
  case "$1" in
    # package execution
    run|shell)
      shift
      local cmd="nix shell"
      for pkg in "$@"; do
        cmd="$cmd 'github:nixos/nixpkgs/master#$pkg'"
      done
      eval "$cmd"
      ;;
    # search packages
    search)
      shift
      nix search "github:nixos/nixpkgs/master" "$@"
      ;;
    # development environment
    develop|dev)
      shift
      if [ $# -eq 1 ]; then
        nix develop "github:nixos/nixpkgs/master#$1"
      else
        echo -e "[31merror: develop accepts only one package[0m" >&2
        return 1
      fi
      ;;
    # build package
    build)
      shift
      local cmd="nix build"
      for pkg in "$@"; do
        cmd="$cmd 'github:nixos/nixpkgs/master#$pkg'"
      done
      eval "$cmd"
      ;;
    # run once
    run-once)
      shift
      if [ $# -eq 1 ]; then
        nix run "github:nixos/nixpkgs/master#$1"
      else
        echo -e "[31merror: run-once accepts only one package[0m" >&2
        return 1
      fi
      ;;
    # show package info
    show|info)
      shift
      if [ $# -eq 1 ]; then
        nix show-derivation "github:nixos/nixpkgs/master#$1"
      else
        echo -e "[31merror: show accepts only one package[0m" >&2
        return 1
      fi
      ;;
    # evaluate expression
    eval)
      shift
      nix eval "github:nixos/nixpkgs/master#$*"
      ;;
    # flake operations
    flake)
      shift
      nix flake "$@" "github:nixos/nixpkgs/master"
      ;;
    # show build log
    log)
      shift
      if [ $# -eq 1 ]; then
        nix log "github:nixos/nixpkgs/master#$1"
      else
        echo -e "[31merror: log accepts only one package[0m" >&2
        return 1
      fi
      ;;
    # show help
    help|-h|--help)
      echo "nix-latest - use latest nixpkgs (master branch)"
      echo ""
      echo "usage:"
      echo "  nix-latest run <pkg>       - run package in shell"
      echo "  nix-latest search <term>   - search packages"
      echo "  nix-latest develop <pkg>   - enter development shell"
      echo "  nix-latest build <pkg>     - build package"
      echo "  nix-latest run-once <pkg>  - run package once"
      echo "  nix-latest show <pkg>      - show package info"
      echo "  nix-latest eval <expr>     - evaluate expression"
      echo "  nix-latest log <pkg>       - show build log"
      echo "  nix-latest flake <cmd>     - flake commands"
      echo "  nix-latest help            - show this help"
      ;;
    # unknown subcommand error
    *)
      echo -e "[31merror: unknown subcommand '$1'[0m" >&2
      echo "run 'nix-latest help' for usage information" >&2
      return 1
      ;;
  esac
}
# short version
nixl() {
  nix-latest "$@"
}