{ ... }: {
  # virtualisation
  virtualisation = {
    # docker
    docker = {
      enable = true;
      rootless = {
        enable = true;
        setSocketVariable = true;
      };
    };
  };
}
