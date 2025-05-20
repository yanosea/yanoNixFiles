{ homePath, username, ... }: {
  imports = [
    # cli
    ../../home/programs/cli
    # languages
    ../../home/programs/languages
    # darwin specific
    ../../home/os/darwin.nix
  ];
  # home
  home = {
    enableNixpkgsReleaseCheck = true;
    homeDirectory = "${homePath}/${username}";
    # this is not latest but ok because this option have to set the first version of Nix configured for me
    stateVersion = "24.05";
    username = username;
  };
  # programs
  programs = { home-manager = { enable = true; }; };
}
