{ hostname, username, ... }:
{
  # nix
  nix = {
    enable = false;
    gc = {
      interval = {
        Weekday = 0;
        Hour = 0;
        Minute = 0;
      };
      options = "--delete-older-than 7d";
    };
    settings = {
      accept-flake-config = true;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
      trusted-users = [
        "root"
        "@wheel"
        username
      ];
    };
  };
  # nixpkgs
  nixpkgs = {
    config = {
      allowUnfree = true;
      allowUnsupportedSystem = true;
    };
  };
  # system
  system = {
    defaults = {
      ".GlobalPreferences" = {
        "com.apple.mouse.scaling" = 17.0;
        "com.apple.sound.beep.sound" = "/System/Library/Sounds/Purr.aiff";
      };
      ActivityMonitor = {
        IconType = 5;
        OpenMainWindow = false;
        ShowCategory = 100;
        SortColumn = null;
        SortDirection = null;
      };
      NSGlobalDomain = {
        AppleEnableMouseSwipeNavigateWithScrolls = true;
        AppleEnableSwipeNavigateWithScrolls = true;
        AppleFontSmoothing = 2;
        AppleICUForce24HourTime = true;
        AppleInterfaceStyle = "Dark";
        AppleInterfaceStyleSwitchesAutomatically = false;
        AppleKeyboardUIMode = null;
        AppleMeasurementUnits = "Centimeters";
        AppleMetricUnits = 1;
        ApplePressAndHoldEnabled = false;
        AppleScrollerPagingBehavior = true;
        AppleShowAllExtensions = true;
        AppleShowAllFiles = true;
        AppleShowScrollBars = "WhenScrolling";
        AppleSpacesSwitchOnActivate = true;
        AppleTemperatureUnit = "Celsius";
        AppleWindowTabbingMode = "always";
        InitialKeyRepeat = 15;
        KeyRepeat = 2;
        NSAutomaticCapitalizationEnabled = false;
        NSAutomaticDashSubstitutionEnabled = true;
        NSAutomaticInlinePredictionEnabled = true;
        NSAutomaticSpellingCorrectionEnabled = true;
        NSAutomaticWindowAnimationsEnabled = true;
        NSDisableAutomaticTermination = false;
        NSDocumentSaveNewDocumentsToCloud = false;
        NSNavPanelExpandedStateForSaveMode = true;
        NSNavPanelExpandedStateForSaveMode2 = true;
        NSScrollAnimationEnabled = true;
        NSTableViewDefaultSizeMode = 1;
        NSTextShowsControlCharacters = true;
        NSUseAnimatedFocusRing = true;
        NSWindowResizeTime = 0.2;
        NSWindowShouldDragOnGesture = true;
        PMPrintingExpandedStateForPrint = true;
        PMPrintingExpandedStateForPrint2 = true;
        _HIHideMenuBar = true;
        "com.apple.keyboard.fnState" = true;
        "com.apple.mouse.tapBehavior" = 1;
        "com.apple.sound.beep.feedback" = 0;
        "com.apple.sound.beep.volume" = 0.0;
        "com.apple.springing.delay" = 0.5;
        "com.apple.springing.enabled" = true;
        "com.apple.swipescrolldirection" = true;
        "com.apple.trackpad.enableSecondaryClick" = true;
        "com.apple.trackpad.forceClick" = false;
        "com.apple.trackpad.scaling" = 17.0;
        "com.apple.trackpad.trackpadCornerClickBehavior" = 1;
      };
      SoftwareUpdate = {
        AutomaticallyInstallMacOSUpdates = true;
      };
      WindowManager = {
        AppWindowGroupingBehavior = true;
        AutoHide = false;
        EnableStandardClickToShowDesktop = false;
        EnableTiledWindowMargins = true;
        EnableTilingByEdgeDrag = true;
        EnableTilingOptionAccelerator = true;
        EnableTopTilingByEdgeDrag = true;
        GloballyEnabled = false;
        HideDesktop = true;
        StageManagerHideWidgets = false;
        StandardHideDesktopIcons = false;
        StandardHideWidgets = false;
      };
      alf = {
        allowdownloadsignedenabled = 1;
        allowsignedenabled = 1;
        globalstate = 1;
        loggingenabled = 1;
        stealthenabled = 0;
      };
      controlcenter = {
        AirDrop = false;
        BatteryShowPercentage = true;
        Bluetooth = false;
        Display = false;
        FocusModes = false;
        NowPlaying = true;
        Sound = true;
      };
      dock = {
        enable-spring-load-actions-on-all-items = true;
        appswitcher-all-displays = false;
        autohide = true;
        autohide-delay = 0.25;
        autohide-time-modifier = 0.25;
        dashboard-in-overlay = true;
        expose-animation-duration = 1.0;
        expose-group-apps = true;
        largesize = 120;
        launchanim = true;
        magnification = true;
        mineffect = "genie";
        minimize-to-application = true;
        mouse-over-hilite-stack = true;
        mru-spaces = true;
        orientation = "bottom";
        persistent-apps = [
          {
            app = "/Applications/Vivaldi.app";
          }
          {
            app = "/Applications/WezTerm.app";
          }
          {
            app = "/Applications/Ableton Live 12 Suite.app";
          }
          {
            app = "/Applications/Native Instruments/Traktor DJ 2/Traktor DJ.app";
          }
          {
            app = "/Applications/Splice.app";
          }
          {
            app = "/Applications/SuperCollider.app";
          }
          {
            app = "/Applications/TouchDesigner.app";
          }
          {
            app = "/Applications/Processing.app";
          }
          {
            app = "/Applications/Sonic Pi.app";
          }
          {
            app = "/System/Applications/Utilities/Screen Sharing.app";
          }
          {
            app = "/System/Applications/System Settings.app";
          }
        ];
        persistent-others = null;
        scroll-to-open = true;
        show-process-indicators = true;
        show-recents = false;
        showhidden = true;
        slow-motion-allowed = true;
        static-only = false;
        tilesize = 128;
        wvous-bl-corner = 1;
        wvous-br-corner = 1;
        wvous-tl-corner = 1;
        wvous-tr-corner = 1;
      };
      finder = {
        AppleShowAllExtensions = true;
        AppleShowAllFiles = true;
        CreateDesktop = true;
        FXDefaultSearchScope = "SCcf";
        FXEnableExtensionChangeWarning = false;
        FXPreferredViewStyle = "Nlsv";
        FXRemoveOldTrashItems = false;
        NewWindowTarget = "Home";
        NewWindowTargetPath = null;
        QuitMenuItem = true;
        ShowExternalHardDrivesOnDesktop = false;
        ShowMountedServersOnDesktop = false;
        ShowPathbar = true;
        ShowRemovableMediaOnDesktop = false;
        ShowStatusBar = true;
        _FXShowPosixPathInTitle = true;
        _FXSortFoldersFirst = true;
        _FXSortFoldersFirstOnDesktop = true;
      };
      hitoolbox = {
        AppleFnUsageType = null;
      };
      iCal = {
        CalendarSidebarShown = false;
        "TimeZone support enabled" = true;
        "first day of week" = "System Setting";
      };
      loginwindow = {
        DisableConsoleAccess = false;
        GuestEnabled = false;
        LoginwindowText = "\\U03bb";
        PowerOffDisabledWhileLoggedIn = false;
        RestartDisabled = false;
        RestartDisabledWhileLoggedIn = false;
        SHOWFULLNAME = false;
        ShutDownDisabled = false;
        ShutDownDisabledWhileLoggedIn = false;
        SleepDisabled = false;
        autoLoginUser = username;
      };
      magicmouse = {
        MouseButtonMode = "TwoButton";
      };
      menuExtraClock = {
        FlashDateSeparators = true;
        IsAnalog = false;
        Show24Hour = true;
        ShowAMPM = false;
        ShowDate = 1;
        ShowDayOfMonth = true;
        ShowDayOfWeek = true;
        ShowSeconds = true;
      };
      screencapture = {
        disable-shadow = false;
        include-date = true;
        location = "/Users/${username}/Desktop";
        show-thumbnail = true;
        target = "clipboard";
        type = "png";
      };
      screensaver = {
        askForPassword = true;
        askForPasswordDelay = 0;
      };
      smb = {
        NetBIOSName = "${hostname}";
        ServerDescription = "${hostname}";
      };
      spaces = {
        spans-displays = false;
      };
      trackpad = {
        ActuationStrength = 0;
        Clicking = true;
        Dragging = false;
        FirstClickThreshold = 0;
        SecondClickThreshold = 0;
        TrackpadRightClick = true;
        TrackpadThreeFingerDrag = true;
        TrackpadThreeFingerTapGesture = 2;
      };
      universalaccess = {
        closeViewScrollWheelToggle = false;
        closeViewZoomFollowsFocus = false;
        mouseDriverCursorSize = 1.0;
        reduceMotion = false;
        reduceTransparency = false;
      };
    };
    keyboard = {
      enableKeyMapping = true;
      nonUS = {
        remapTilde = true;
      };
      remapCapsLockToControl = true;
      remapCapsLockToEscape = false;
      swapLeftCommandAndLeftAlt = false;
      swapLeftCtrlAndFn = false;
    };
    primaryUser = username;
    profile = "/nix/var/nix/profiles/system";
    startup = {
      chime = false;
    };
  };
}
