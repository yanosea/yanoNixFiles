# mac configuration
{
  homePath,
  pkgs,
  username,
  ...
}:
{
  # system
  system = {
    stateVersion = 6;
  };
  # users
  users = {
    users = {
      "${username}" = {
        home = "/${homePath}/${username}";
        shell = pkgs.zsh;
      };
    };
  };
}
