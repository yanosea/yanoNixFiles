{ ... }: {
  imports = [ ../../modules/darwin ];
  users.users.yanosea = {
    home = "/Users/yanosea";
  };
  networking = { hostName = "yanoMac"; };
}
