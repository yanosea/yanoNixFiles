# macbook home configuration
{
  config,
  homePath,
  username,
  ...
}:
{
  imports = [
    # darwin specific
    ../../home-manager/os/darwin
    # configs (dotfiles)
    ../../../configs
  ];
  # home
  home = {
    enableNixpkgsReleaseCheck = true;
    homeDirectory = "${homePath}/${username}";
    stateVersion = "24.05"; # DO NOT CHANGE
    username = username;
  };
}
