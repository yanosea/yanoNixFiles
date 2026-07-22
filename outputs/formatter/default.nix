# formatter configuration
inputs:
with inputs.nixpkgs.lib;
genAttrs [ "x86_64-linux" "aarch64-darwin" ] (
  system:
  (inputs.treefmt-nix.lib.evalModule inputs.nixpkgs.legacyPackages.${system} {
    projectRootFile = "flake.nix";
    programs = {
      # github actions
      actionlint = {
        enable = true;
      };
      # zsh
      beautysh = {
        enable = true;
        includes = [ "*.zsh" ];
      };
      # c
      clang-format = {
        enable = true;
      };
      # nix
      deadnix = {
        enable = true;
        excludes = [
          "outputs/nixos/yanoNixOs/hardware-configuration.nix"
        ];
      };
      # json
      jsonfmt = {
        enable = true;
        includes = [ "*.json" ];
      };
      # kdl
      kdlfmt = {
        enable = true;
        includes = [ "*.kdl" ];
      };
      # nix
      nixfmt = {
        enable = true;
      };
      # css, html, javascript, markdown
      prettier = {
        enable = true;
        includes = [
          "*.css"
          "*.html"
          "*.js"
          "*.md"
        ];
        excludes = [
          "configs/quickshell/Assets/MatugenTemplates/**"
          "configs/quickshell/Helpers/FuzzySort.js"
        ];
      };
      # qml
      qmlformat = {
        enable = true;
        package = inputs.nixpkgs.legacyPackages.${system}.qt6.qtdeclarative;
      };
      # python
      ruff-check = {
        enable = true;
      };
      # python
      ruff-format = {
        enable = true;
      };
      # rust
      rustfmt = {
        enable = true;
      };
      # shell
      shellcheck = {
        enable = true;
      };
      # shell
      shfmt = {
        enable = true;
      };
      # nix
      statix = {
        enable = true;
        excludes = [
          "outputs/nixos/yanoNixOs/hardware-configuration.nix"
        ];
      };
      # lua
      stylua = {
        enable = true;
      };
      # toml
      taplo = {
        enable = true;
      };
      # all files
      typos = {
        enable = true;
      };
      # xml
      xmllint = {
        enable = true;
      };
      # yaml
      yamlfmt = {
        enable = true;
        includes = [
          "*.yaml"
          "*.yml"
        ];
      };
      # github actions
      zizmor = {
        enable = true;
      };
      # edn
      zprint = {
        enable = true;
      };
    };
    settings = {
      formatter = {
        gitleaks =
          let
            pkgs = inputs.nixpkgs.legacyPackages.${system};
            gitleaks-treefmt = pkgs.writeShellApplication {
              name = "gitleaks-treefmt";
              runtimeInputs = [ pkgs.gitleaks ];
              # `gitleaks dir` takes a single path, so scan each file treefmt passes
              text = ''
                for file in "$@"; do
                  gitleaks dir "$file" --no-banner --redact --exit-code 1
                done
              '';
            };
          in
          {
            command = "${gitleaks-treefmt}/bin/gitleaks-treefmt";
            includes = [ "*" ];
          };
      };
    };
  }).config.build.wrapper
)
