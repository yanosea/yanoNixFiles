# nixos shell module
{ pkgs, lib, ... }:
{
  # programs
  programs = {
    zsh = {
      enable = true;
    };
  };

  # /bin/bash symlink for third-party scripts with hardcoded shebangs
  system = {
    activationScripts = {
      binbash = lib.stringAfter [ "usrbinenv" ] ''
        ln -sfn "${pkgs.bash}/bin/bash" /bin/bash
      '';
    };
  };
}
