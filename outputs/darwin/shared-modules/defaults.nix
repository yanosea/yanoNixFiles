# darwin defaults configuration aggregator
{ hostname, username, ... }:
let
  # import all defaults modules
  global = import ./defaults/global.nix { inherit hostname username; };
  dock = import ./defaults/dock.nix { inherit hostname username; };
  finder = import ./defaults/finder.nix { inherit hostname username; };
  input = import ./defaults/input.nix { inherit hostname username; };
  ui = import ./defaults/ui.nix { inherit hostname username; };
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
