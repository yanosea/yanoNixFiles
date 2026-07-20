# formatter configuration
inputs:
with inputs.nixpkgs.lib;
genAttrs [ "x86_64-linux" "aarch64-darwin" ] (
  system:
  (inputs.treefmt-nix.lib.evalModule inputs.nixpkgs.legacyPackages.${system} {
    projectRootFile = "flake.nix";
    programs = {
      # all files
      typos = {
        enable = true;
      };
      # github actions
      actionlint = {
        enable = true;
      };
      # c
      clang-format = {
        enable = true;
      };
      # edn
      zprint = {
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
      # lua
      stylua = {
        enable = true;
      };
      # nix
      deadnix = {
        enable = true;
        excludes = [
          "outputs/nixos/yanoNixOs/hardware-configuration.nix"
        ];
      };
      nixfmt = {
        enable = true;
      };
      statix = {
        enable = true;
        excludes = [
          "outputs/nixos/yanoNixOs/hardware-configuration.nix"
        ];
      };
      # python
      ruff-check = {
        enable = true;
      };
      ruff-format = {
        enable = true;
      };
      # qml
      qmlformat = {
        enable = true;
        package = inputs.nixpkgs.legacyPackages.${system}.qt6.qtdeclarative;
      };
      # rust
      rustfmt = {
        enable = true;
      };
      # shell
      shellcheck = {
        enable = true;
      };
      shfmt = {
        enable = true;
      };
      # toml
      taplo = {
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
      # zsh
      beautysh = {
        enable = true;
        includes = [ "*.zsh" ];
      };
    };
  }).config.build.wrapper
)
