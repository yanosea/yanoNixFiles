# home tools module
{ pkgs, ... }:
{
  # home
  home = {
    packages = with pkgs; [
      bitwarden-cli
      btop
      chafa
      discordo
      duf
      dust
      era
      fastfetch
      fontforge
      fzf-make
      gum
      htop
      hyperfine
      jnv
      jq
      mermaid-cli
      ncdu
      onefetch
      vhs
      wakatime-cli
    ];
  };
}
