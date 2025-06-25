# darwin defaults configuration aggregator
{ hostname, username, ... }:
let
  # import all defaults modules
  global = import ./defaults/global.nix;
  dock = import ./defaults/dock.nix;
  finder = import ./defaults/finder.nix;
  input = import ./defaults/input.nix;
  ui = import ./defaults/ui.nix;
  system = import ./defaults/system.nix { inherit hostname username; };
in
{
  # system
  system = {
    defaults = global // dock // finder // input // ui // system;
    keyboard = {
      enableKeyMapping = true;
      nonUS = {
        remapTilde = true;
      };
      remapCapsLockToControl = true;
      remapCapsLockToEscape = false;
      swapLeftCommandAndLeftAlt = false;
      swapLeftCtrlAndFn = false;
    };
    primaryUser = username;
    profile = "/nix/var/nix/profiles/system";
    startup = {
      chime = false;
    };
  };
}
