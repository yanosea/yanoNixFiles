{ pkgs, ... }:
{
  home = {
    packages = with pkgs; [
      # docker
      docker
      docker-compose
    ];
  };
}
