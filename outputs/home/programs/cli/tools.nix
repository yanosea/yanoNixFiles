{ pkgs, ... }:
{
  # home
  home = {
    packages = with pkgs; [
      btop
      duf
      dust
      era
      fastfetch
      fontforge
      fzf-make
      htop
      hyperfine
      jnv
      jq
      mermaid-cli
      ncdu
      onefetch
      vhs
      wakatime
    ];
  };
}
