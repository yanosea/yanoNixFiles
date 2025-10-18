# home development environment module
{ pkgs, ... }:
{
  # home
  home = {
    packages = with pkgs; [
      stdenv.cc.cc.lib
      vips
    ];
    sessionVariables = {
      LD_LIBRARY_PATH = "\${LD_LIBRARY_PATH:+$LD_LIBRARY_PATH:}${pkgs.stdenv.cc.cc.lib}/lib:${pkgs.vips}/lib";
    };
  };
}
