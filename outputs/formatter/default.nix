# formatter configuration
inputs:
with inputs.nixpkgs.lib;
genAttrs [ "x86_64-linux" "aarch64-darwin" ] (
  system:
  (inputs.treefmt-nix.lib.evalModule inputs.nixpkgs.legacyPackages.${system} {
    projectRootFile = "flake.nix";
    programs = {
      # css, html
      prettier = {
        enable = true;
        includes = [
          "*.css"
          "*.html"
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
      # markdown
      mdformat = {
        enable = true;
        includes = [ "*.md" ];
        settings = {
          number = true;
        };
      };
      # nix
      nixfmt = {
        enable = true;
      };
      # rust
      rustfmt = {
        enable = true;
      };
      # shell
      shfmt = {
        enable = true;
      };
      # toml
      taplo = {
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
    };
  }).config.build.wrapper
)
