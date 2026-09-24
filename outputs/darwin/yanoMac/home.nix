# mac home configuration
{
  homePath,
  username,
  ...
}:
{
  imports = [
    # host specific
    ../../home-manager/hosts/yanoMac
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
    inherit username;
  };
}
