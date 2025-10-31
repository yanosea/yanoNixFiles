# nixos desktop camera priority module
{ pkgs, ... }:
{
  systemd = {
    services = {
      camera-priority = {
        description = "Ensure OBS virtual camera gets video0";
        after = [ "systemd-modules-load.service" ];
        before = [ "systemd-udevd.service" ];
        wantedBy = [ "sysinit.target" ];
        unitConfig = {
          DefaultDependencies = false;
        };
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          # unbind all USB cameras before udev processes them
          for usb_dev in /sys/bus/usb/devices/*/idVendor; do
            dev_path=$(dirname "$usb_dev")
            vendor=$(cat "$usb_dev" 2>/dev/null)
            product=$(cat "$dev_path/idProduct" 2>/dev/null)
            # Game Capture HD60 S+ (0fd9:006b) or Anker PowerConf C300 (291a:3361)
            if [ "$vendor" = "0fd9" ] || [ "$vendor" = "291a" ]; then
              dev_name=$(basename "$dev_path")
              echo "Unbinding USB camera: $dev_name"
              echo "$dev_name" > /sys/bus/usb/drivers/usb/unbind 2>/dev/null || true
            fi
          done
          # remove v4l2loopback if loaded
          ${pkgs.kmod}/bin/rmmod v4l2loopback 2>/dev/null || true
          # load v4l2loopback with video_nr=0
          ${pkgs.kmod}/bin/modprobe v4l2loopback devices=1 video_nr=0 card_label="OBS Virtual Camera" exclusive_caps=1
          # wait a moment for the module to initialize
          sleep 1
          # rebind USB cameras
          for usb_dev in /sys/bus/usb/devices/*/idVendor; do
            dev_path=$(dirname "$usb_dev")
            vendor=$(cat "$usb_dev" 2>/dev/null)
            product=$(cat "$dev_path/idProduct" 2>/dev/null)

            if [ "$vendor" = "0fd9" ] || [ "$vendor" = "291a" ]; then
              dev_name=$(basename "$dev_path")
              if [ ! -e "$dev_path/driver" ]; then
                echo "Rebinding USB camera: $dev_name"
                echo "$dev_name" > /sys/bus/usb/drivers/usb/bind 2>/dev/null || true
              fi
            fi
          done
        '';
      };
    };
  };
}
