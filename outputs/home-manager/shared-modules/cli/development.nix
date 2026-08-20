# home development environment module
{ pkgs, ... }:
{
  # home
  home = {
    packages = with pkgs; [
      glib.out
      gcc_latest.cc.lib
      libsecret
      vips
    ];
    sessionVariables = {
      # gcc_latest, not stdenv.cc.cc.lib: this wins over every binary's own RPATH, and
      # the default stdenv trails nixpkgs' newest gcc, so anything built with the newer
      # one (hyprctl) fails on missing GLIBCXX symbols. libstdc++ is backwards compatible
      LD_LIBRARY_PATH = "\${LD_LIBRARY_PATH:+$LD_LIBRARY_PATH:}${pkgs.glib.out}/lib:${pkgs.libsecret}/lib:${pkgs.gcc_latest.cc.lib}/lib:${pkgs.vips}/lib";
    };
  };
}
