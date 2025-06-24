# nixos virtualisation module
{
  # virtualisation
  virtualisation = {
    docker = {
      enable = true;
      rootless = {
        enable = true;
        setSocketVariable = true;
      };
    };
  };
}
