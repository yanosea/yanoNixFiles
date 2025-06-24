# home js module
{ pkgs, ... }:
{
  # home
  home = {
    packages = with pkgs; [
      bun
      deno
      nodePackages_latest.nodejs
      nodePackages_latest.pnpm
      typescript
    ];
  };
}
