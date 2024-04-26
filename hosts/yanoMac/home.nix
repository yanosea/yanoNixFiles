{ homePath, username, ... }: {
  imports = [
    # cli
    ../../home/programs/cli
    # develop
    ../../home/programs/develop
    # languages
    ../../home/programs/languages/go.nix
    ../../home/programs/languages/java.nix
    ../../home/programs/languages/js.nix
    ../../home/programs/languages/python.nix
    ../../home/programs/languages/rust.nix
    # darwin specific
    ../../home/os/darwin.nix
  ];
  # home
  home = {
    enableNixpkgsReleaseCheck = false;
    homeDirectory = "${homePath}/${username}";
    stateVersion = "24.05";
    username = username;
  };
  # programs
  programs = { home-manager = { enable = true; }; };
}
