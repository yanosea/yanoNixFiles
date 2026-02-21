# nixos desktop xdg mime module
{
  # xdg mime and default applications
  xdg = {
    mime = {
      enable = true;
      defaultApplications = {
        # web browser
        "text/html" = [ "vivaldi-stable.desktop" ];
        "x-scheme-handler/http" = [ "vivaldi-stable.desktop" ];
        "x-scheme-handler/https" = [ "vivaldi-stable.desktop" ];
        "x-scheme-handler/chrome" = [ "vivaldi-stable.desktop" ];
        "application/x-extension-htm" = [ "vivaldi-stable.desktop" ];
        "application/x-extension-html" = [ "vivaldi-stable.desktop" ];
        "application/x-extension-shtml" = [ "vivaldi-stable.desktop" ];
        "application/xhtml+xml" = [ "vivaldi-stable.desktop" ];
        "application/x-extension-xhtml" = [ "vivaldi-stable.desktop" ];
        "application/x-extension-xht" = [ "vivaldi-stable.desktop" ];
        # text editor
        "text/plain" = [
          "nvim.desktop"
          "vim.desktop"
        ];
        "text/x-shellscript" = [
          "nvim.desktop"
          "vim.desktop"
        ];
        "application/x-shellscript" = [
          "nvim.desktop"
          "vim.desktop"
        ];
        "text/x-python" = [
          "nvim.desktop"
          "vim.desktop"
        ];
        "text/x-c" = [
          "nvim.desktop"
          "vim.desktop"
        ];
        "text/x-c++" = [
          "nvim.desktop"
          "vim.desktop"
        ];
        "text/x-java" = [
          "nvim.desktop"
          "vim.desktop"
        ];
        "text/x-javascript" = [
          "nvim.desktop"
          "vim.desktop"
        ];
        "application/json" = [
          "nvim.desktop"
          "vim.desktop"
        ];
        "text/markdown" = [
          "nvim.desktop"
          "vim.desktop"
        ];
        "text/x-markdown" = [
          "nvim.desktop"
          "vim.desktop"
        ];
        "text/x-makefile" = [
          "nvim.desktop"
          "vim.desktop"
        ];
        "text/x-nix" = [
          "nvim.desktop"
          "vim.desktop"
        ];
        "text/x-yaml" = [
          "nvim.desktop"
          "vim.desktop"
        ];
        "text/x-toml" = [
          "nvim.desktop"
          "vim.desktop"
        ];
        "text/x-lua" = [
          "nvim.desktop"
          "vim.desktop"
        ];
        "text/x-rust" = [
          "nvim.desktop"
          "vim.desktop"
        ];
        "text/x-go" = [
          "nvim.desktop"
          "vim.desktop"
        ];
        # file manager
        "inode/directory" = [
          "nemo.desktop"
          "lf.desktop"
        ];
        # pdf viewer
        "application/pdf" = [ "evince.desktop" ];
        # image viewer
        "image/png" = [ "qimgv.desktop" ];
        "image/jpeg" = [ "qimgv.desktop" ];
        "image/gif" = [ "qimgv.desktop" ];
        "image/svg+xml" = [ "qimgv.desktop" ];
        "image/webp" = [ "qimgv.desktop" ];
        "image/bmp" = [ "qimgv.desktop" ];
        "image/tiff" = [ "qimgv.desktop" ];
        # video player
        "video/mp4" = [
          "mpv.desktop"
          "totem.desktop"
        ];
        "video/x-matroska" = [
          "mpv.desktop"
          "totem.desktop"
        ];
        "video/avi" = [
          "mpv.desktop"
          "totem.desktop"
        ];
        "video/webm" = [
          "mpv.desktop"
          "totem.desktop"
        ];
        "video/quicktime" = [
          "mpv.desktop"
          "totem.desktop"
        ];
        "video/x-msvideo" = [
          "mpv.desktop"
          "totem.desktop"
        ];
        "video/x-flv" = [
          "mpv.desktop"
          "totem.desktop"
        ];
        "video/x-ms-wmv" = [
          "mpv.desktop"
          "totem.desktop"
        ];
        # audio player
        "audio/mpeg" = [
          "mpv.desktop"
          "spotify.desktop"
        ];
        "audio/x-wav" = [ "mpv.desktop" ];
        "audio/flac" = [ "mpv.desktop" ];
        "audio/ogg" = [ "mpv.desktop" ];
        "audio/x-m4a" = [ "mpv.desktop" ];
        "audio/mp3" = [
          "mpv.desktop"
          "spotify.desktop"
        ];
        "audio/x-vorbis+ogg" = [ "mpv.desktop" ];
        # archive manager (using command line tools)
        "application/zip" = [ "org.gnome.FileRoller.desktop" ];
        "application/x-rar" = [ "org.gnome.FileRoller.desktop" ];
        "application/x-tar" = [ "org.gnome.FileRoller.desktop" ];
        "application/x-7z-compressed" = [ "org.gnome.FileRoller.desktop" ];
        "application/x-bzip2" = [ "org.gnome.FileRoller.desktop" ];
        "application/x-gzip" = [ "org.gnome.FileRoller.desktop" ];
        "application/x-xz" = [ "org.gnome.FileRoller.desktop" ];
      };
    };
  };
  # environment variables for default applications
  environment = {
    sessionVariables = {
      DEFAULT_BROWSER = "vivaldi";
      BROWSER = "vivaldi";
      EDITOR = "nvim";
      VISUAL = "nvim";
      TERMINAL = "wezterm";
      FILE_MANAGER = "nemo";
      PAGER = "less";
    };
  };
}
