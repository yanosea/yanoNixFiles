{ pkgs, ... }:
{
  # home
  home = {
    packages = with pkgs; [
      docker
      docker-compose
    ];
  };
}
