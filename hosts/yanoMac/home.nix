{ homePath, username, ... }:
{
  imports = [
    # cli
    ../../home/programs/cli
    # gui (terminal)
    ../../home/programs/gui/terminal.nix
    # languages
    ../../home/programs/languages
    # darwin specific
    ../../home/os/darwin.nix
  ];
  # home
  home = {
    enableNixpkgsReleaseCheck = true;
    homeDirectory = "${homePath}/${username}";
    sessionVariables = {
      ZDOTDIR = "${homePath}/${username}/.config/zsh";
    };
    stateVersion = "24.05"; # DO NOT CHANGE
    username = username;
  };
  # programs
  programs = {
    home-manager = {
      enable = true;
    };
    zsh = {
      enable = true;
    };
  };
}
