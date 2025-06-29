# home daw module
{ pkgs, ... }:
{
  # home
  home = {
    packages = with pkgs; [
      bitwig-studio
    ];
    sessionVariables = {
      DISABLE_VK_LAYER_LUNARG_api_dump = "1";
      DISABLE_VK_LAYER_LUNARG_core_validation = "1";
      VK_INSTANCE_LAYERS = "";
      VK_DRIVER_FILES = "";
    };
  };
}
