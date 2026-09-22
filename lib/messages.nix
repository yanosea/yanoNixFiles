# status messages shared by the apps and the home activation scripts
let
  # magenta and yellow are what nix and homebrew print warnings in, so neither marks progress here
  colors = {
    reset = "\\033[0m";
    title = "\\033[1;34m"; # bold blue
    step = "\\033[36m"; # cyan
    done = "\\033[32m"; # green
    hint = "\\033[33m"; # yellow
    error = "\\033[31m"; # red
  };
  say = color: msg: ''echo -e "${color}${msg}${colors.reset}"'';
  blank = ''echo ""'';
  # every message sits between blank lines and neighbours share one: a phase
  # ends on a blank line, so a script only has to print one before its first
  phase =
    color:
    {
      start,
      done,
      body,
      # a body that prints nothing would otherwise leave two blank lines
      quiet ? false,
    }:
    ''
      ${say color start}
      ${blank}
      ${body}
      ${if quiet then "" else blank}
      ${say colors.done done}
      ${blank}
    '';
  # a phase made of phases: the last one already left the blank line
  group =
    color:
    {
      start,
      done,
      body,
    }:
    ''
      ${say color start}
      ${blank}
      ${body}
      ${say colors.done done}
      ${blank}
    '';
in
{
  inherit blank colors;
  error = say colors.error;
  hint = msg: ''
    ${say colors.hint msg}
    ${blank}
  '';
  step = phase colors.step;
  title = phase colors.title;
  titleGroup = group colors.title;
}
