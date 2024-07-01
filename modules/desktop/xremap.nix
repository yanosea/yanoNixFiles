{ inputs, username, ... }: {
  imports = [
    inputs.xremap.nixosModules.default
  ];
  # hardware
  hardware = {
    uinput = {
      enable = true;
    };
  };
  # users
  users = {
    groups = {
      uinput = {
        members = [ username ];
      };
      input = {
        members = [ username ];
      };
    };
  };
  # services
  services = {
    xremap = {
      userName = username;
      serviceMode = "user";
      config = {
        modmap = [
          {
            name = "CapsLock is dead";
            remap = {
              F13 = "VK243";
            };
          }
        ];
      };
    };
  };
}
