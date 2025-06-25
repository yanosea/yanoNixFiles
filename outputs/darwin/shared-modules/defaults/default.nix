# darwin defaults configuration aggregator
{ hostname, username, ... }:
let
  # import all defaults modules
  global = import ./global.nix { inherit hostname username; };
  dock = import ./dock.nix { inherit hostname username; };
  finder = import ./finder.nix { inherit hostname username; };
  input = import ./input.nix { inherit hostname username; };
  ui = import ./ui.nix { inherit hostname username; };
  system = import ./system.nix { inherit hostname username; };
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
