# UI and window management configuration
{ ... }:
{
  # system
  system = {
    defaults = {
      ActivityMonitor = {
        IconType = 5;
        OpenMainWindow = false;
        ShowCategory = 100;
        SortColumn = null;
        SortDirection = null;
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
      spaces = {
        spans-displays = false;
      };
      universalaccess = {
        closeViewScrollWheelToggle = false;
        closeViewZoomFollowsFocus = false;
        mouseDriverCursorSize = 1.0;
        reduceMotion = false;
        reduceTransparency = false;
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
    };
  };
}
