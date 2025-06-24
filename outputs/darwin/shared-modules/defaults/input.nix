# input devices configuration (trackpad, mouse, keyboard)
{ hostname, username, ... }:
{
  magicmouse = {
    MouseButtonMode = "TwoButton";
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

  hitoolbox = {
    AppleFnUsageType = null;
  };
}
