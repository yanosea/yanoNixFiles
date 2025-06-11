{ pkgs, ... }:
{
  home = {
    packages = with pkgs; [
      # tools
      era
      fastfetch
      fontforge
      fzf-make
      hyperfine
      jnv
      jq
      mermaid-cli
      onefetch
      vhs
      wakatime
    ];
  };
}
