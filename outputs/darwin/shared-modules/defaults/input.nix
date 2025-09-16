# input configuration
{ ... }:
{
  # system
  system = {
    defaults = {
      magicmouse = {
        MouseButtonMode = "TwoButton";
      };
      hitoolbox = {
        AppleFnUsageType = null;
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
      CustomUserPreferences = {
        "com.apple.AppleMultitouchTrackpad" = {
          TrackpadThreeFingerHorizSwipeGesture = 0;
          TrackpadFourFingerHorizSwipeGesture = 0;
          TrackpadThreeFingerVertSwipeGesture = 0;
          TrackpadFourFingerVertSwipeGesture = 0;
        };
        "com.apple.driver.AppleBluetoothMultitouch.trackpad" = {
          TrackpadThreeFingerHorizSwipeGesture = 0;
          TrackpadFourFingerHorizSwipeGesture = 0;
          TrackpadThreeFingerVertSwipeGesture = 0;
          TrackpadFourFingerVertSwipeGesture = 0;
        };
      };
    };
  };
}
