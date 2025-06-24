# nixos desktop fuse module
{
  # programs
  programs = {
    fuse = {
      userAllowOther = true;
    };
  };
}
