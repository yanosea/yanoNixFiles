{ pkgs, ... }:
{
  home = {
    packages = with pkgs; [
      deno
      nodePackages_latest.nodejs
      nodePackages_latest.pnpm
      typescript
    ];
  };
}
