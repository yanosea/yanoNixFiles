# home development environment module
{ pkgs, ... }:
{
  # home
  home = {
    packages = with pkgs; [
      glib.out
      libsecret
      stdenv.cc.cc.lib
      vips
    ];
    sessionVariables = {
      LD_LIBRARY_PATH = "\${LD_LIBRARY_PATH:+$LD_LIBRARY_PATH:}${pkgs.glib.out}/lib:${pkgs.libsecret}/lib:${pkgs.stdenv.cc.cc.lib}/lib:${pkgs.vips}/lib";
    };
  };
}
