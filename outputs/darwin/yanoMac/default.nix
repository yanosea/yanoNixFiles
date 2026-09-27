# mac configuration
{
  homePath,
  pkgs,
  username,
  ...
}:
{
  # environment
  environment = {
    systemPackages = [ pkgs.ffmpeg ];
  };
  # system
  system = {
    stateVersion = 6;
    activationScripts = {
      postActivation = {
        text = ''
          mkdir -p /usr/local/bin
          for bin in ffmpeg ffprobe; do
            ln -sfn ${pkgs.ffmpeg}/bin/$bin /usr/local/bin/$bin
          done
        '';
      };
    };
  };
  # users
  users = {
    users = {
      "${username}" = {
        home = "${homePath}/${username}";
        shell = pkgs.zsh;
      };
    };
  };
}
