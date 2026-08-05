# text editing key bindings module
_: {
  # home
  home = {
    file = {
      # override macOS's built-in Emacs-style bindings that otherwise
      # intercept ctrl-a/c/v/x before NSUserKeyEquivalents sees them
      "Library/KeyBindings/DefaultKeyBinding.dict" = {
        text = ''
          {
            "^a" = "selectAll:";
            "^c" = "copy:";
            "^v" = "paste:";
            "^x" = "cut:";
            "^~\UF702" = "moveWordBackward:";
            "^~\UF703" = "moveWordForward:";
          }
        '';
      };
    };
  };
}
