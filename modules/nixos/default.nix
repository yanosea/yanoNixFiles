{ config, lib, pkgs, ... }:
let
  timestamp = builtins.readFile (pkgs.runCommandNoCC "timestamp" { } "date +%Y%m%d%H%M%S > $out");
in
{
  imports = [
    ../font.nix
    ./font.nix
  ];
  # boot
  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 10;
      };
      efi = {
        canTouchEfiVariables = true;
      };
    };
    initrd = {
      kernelModules = [
        "nvidia"
      ];
    };
    extraModulePackages = [
      config.boot.kernelPackages.nvidia_x11
    ];
    binfmt = {
      emulatedSystems = [
        "aarch64-linux"
      ];
    };
    kernelPackages = pkgs.linuxPackages_latest;
  };
  # hardware
  hardware = {
    opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
      extraPackages = with pkgs; [
        vaapiVdpau
        libvdpau-va-gl
      ];
      extraPackages32 = with pkgs.pkgsi686Linux; [
        libva
      ];
      setLdLibraryPath = true;
    };
    nvidia = {
      modesetting = {
        enable = true;
      };
      open = false;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      forceFullCompositionPipeline = true;
      powerManagement.enable = true;
    };
    pulseaudio = {
      enable = false;
    };
  };
  # sound
  sound = {
    enable = true;
  };
  # networking
  networking = {
    networkmanager = {
      enable = true;
    };
    firewall = {
      enable = true;
    };
  };
  # security
  security = {
    rtkit = {
      enable = true;
    };
    sudo = {
      wheelNeedsPassword = true;
    };
  };
  # time
  time = {
    timeZone = "Asia/Tokyo";
    hardwareClockInLocalTime = true;
  };
  # language
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ALL = "en_US.UTF-8";
      LC_ADDRESS = "ja_JP.UTF-8";
      LC_IDENTIFICATION = "ja_JP.UTF-8";
      LC_MEASUREMENT = "ja_JP.UTF-8";
      LC_MONETARY = "ja_JP.UTF-8";
      LC_NAME = "ja_JP.UTF-8";
      LC_NUMERIC = "ja_JP.UTF-8";
      LC_PAPER = "ja_JP.UTF-8";
      LC_TELEPHONE = "ja_JP.UTF-8";
      LC_TIME = "ja_JP.UTF-8";
    };
    inputMethod = {
      enabled = "fcitx5";
      fcitx5.addons = with pkgs; [
        fcitx5-mozc
        fcitx5-skk
      ];
    };
  };
  # services
  services = {
    libinput = {
      enable = true;
    };
    xserver = {
      enable = true;
      excludePackages = [
        pkgs.xterm
      ];
      videoDrivers = [ "nvidia" ];
      displayManager = {
        gdm = {
          enable = true;
          wayland = true;
        };
      };
      desktopManager = {
        gnome = {
          enable = true;
        };
      };
      xkb = {
        variant = "";
        layout = "us";
      };
    };
    dbus = {
      enable = true;
    };
    gvfs = {
      enable = true;
    };
    tumbler = {
      enable = true;
    };
    gnome = {
      sushi = {
        enable = true;
      };
      gnome-keyring = {
        enable = true;
      };
    };
    pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      pulse = {
        enable = true;
      };
      jack = {
        enable = true;
      };
    };
    printing = {
      enable = true;
    };
  };
  # nix
  nix = {
    envVars = {
      ZDOTDIR = "$HOME/.config/zsh";
    };
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [
        "yanosea"
      ];
      auto-optimise-store = true;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 1w";
    };
  };
  # nixpkgs
  nixpkgs = {
    config = {
      allowUnfree = true;
    };
  };
  # environment
  environment = {
    sessionVariables = {
      POLKIT_AUTH_AGENT = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      GSETTINGS_SCHEMA_DIR = "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}/glib-2.0/schemas";
      LIBVA_DRIVER_NAME = "nvidia";
      XDG_SESSION_TYPE = "wayland";
      GBM_BACKEND = "nvidia-drm";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      WLR_NO_HARDWARE_CURSORS = "1";
      NIXOS_OZONE_WL = "1";
      MOZ_ENABLE_WAYLAND = "1";
      SDL_VIDEODRIVER = "wayland";
      _JAVA_AWT_WM_NONREPARENTING = "1";
      CLUTTER_BACKEND = "wayland";
      WLR_RENDERER = "vulkan";
      XDG_CURRENT_DESKTOP = "Hyprland";
      XDG_SESSION_DESKTOP = "Hyprland";
      GTK_USE_PORTAL = "1";
      NIXOS_XDG_OPEN_USE_PORTAL = "1";
      WLR_DRM_NO_ATOMIC = "1";
      XCURSOR_SIZE = "22";
    };
    systemPackages = with pkgs; [
      cargo-make
      gcc
      git
      openssl
      openssl.dev
      pkg-config
      zsh
    ];
    extraInit = ''
      export OPENSSL_LIB_DIR=${pkgs.openssl.out}/lib
      export OPENSSL_INCLUDE_DIR=${pkgs.openssl.dev}/include
    '';
  };
  # programs
  programs = {
    fuse = {
      userAllowOther = true;
      mountMax = 1000;
    };
    gnupg = {
      agent = {
        enable = true;
        enableSSHSupport = true;
      };
    };
    mtr = {
      enable = true;
    };
    zsh = {
      enable = true;
    };
    hyprland = {
      enable = true;
      xwayland = {
        enable = true;
      };
    };
    waybar = {
      enable = true;
      package = pkgs.waybar.overrideAttrs (oldAttrs: {
        mesonFlags = oldAttrs.mesonFlags ++ [ "-Dexperimental=true" ];
      });
    };
    thunar = {
      enable = true;
      plugins = with pkgs.xfce; [
        thunar-archive-plugin
        thunar-volman
      ];
    };
  };
  # xdg
  xdg = {
    autostart = {
      enable = true;
    };
    portal = {
      enable = true;
      extraPortals = [
        pkgs.xdg-desktop-portal
      ];
    };
  };
  # lock
  security = {
    pam.services.swaylock = {
      text = ''
        auth include login
      '';
    };
  };
  # systemd
  systemd = {
    services = {
      rclone = {
        enable = true;
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        wantedBy = [ "default.target" ];
        description = "rclone service";
        serviceConfig = {
          ExecStart = "${pkgs.rclone}/bin/rclone mount yanosea: /mnt/google_drive/yanosea --allow-other --vfs-cache-mode full --buffer-size 128M --vfs-read-ahead 512M --drive-chunk-size 64M";
        };
      };
    };
  };
  # home-manager
  home-manager.backupFileExtension = "backup-${timestamp}";
  # system
  system = {
    stateVersion = "24.05";
  };
}
