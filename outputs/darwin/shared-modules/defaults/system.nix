# system-level configurations
{ hostname, username, ... }:
{
  SoftwareUpdate = {
    AutomaticallyInstallMacOSUpdates = true;
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
}
