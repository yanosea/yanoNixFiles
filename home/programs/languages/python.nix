{ pkgs, ... }: {
  home = {
    packages = with pkgs; [
      pyenv
      python312
      python312Packages.pydbus
      python312Packages.psutil
    ];
  };
}
