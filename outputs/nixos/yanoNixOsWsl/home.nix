# nixos (wsl) home configuration
{
  homePath,
  username,
  ...
}:
{
  imports = [
    # host specific
    ../../home-manager/hosts/yanoNixOsWsl
    # nixos specific
    ../../home-manager/os/nixos
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
