# overlays
inputs: [
  # modules
  ## rust
  (
    _: super:
    let
      pkgs = inputs.fenix.inputs.nixpkgs.legacyPackages.${super.stdenv.hostPlatform.system};
    in
    inputs.fenix.overlays.default pkgs pkgs
  )
  # packages
  ## comfyui
  (
    _final: prev:
    let
      buildFHSUserEnv = prev.buildFHSUserEnv or prev.buildFHSEnv;
    in
    {
      comfyui = buildFHSUserEnv {
        name = "comfyui";
        targetPkgs =
          pkgs:
          (with pkgs; [
            cudaPackages.cudatoolkit
            cudaPackages.cudnn
            gcc
            git
            git-lfs
            glib
            gnumake
            gtk3
            libGL
            libGLU
            linuxPackages.nvidia_x11
            pkg-config
            python312
            python312Packages.pip
            python312Packages.virtualenv
            stdenv.cc.cc.lib
            wget
            zlib
          ]);
        profile = ''
          export COMFYUI_ROOT=~/.local/share/comfyui
        '';
        runScript = "${prev.bash}/bin/bash";
        meta = with prev.lib; {
          description = "ComfyUI in FHS environment";
          homepage = "https://github.com/comfyanonymous/ComfyUI";
          license = licenses.gpl3;
          platforms = platforms.linux;
        };
      };
    }
  )
  ## claude-code
  (_final: prev: {
    claude-code = inputs.claude-code.packages.${prev.stdenv.hostPlatform.system}.default;
  })
  ## invokeai
  (
    _final: prev:
    let
      buildFHSUserEnv = prev.buildFHSUserEnv or prev.buildFHSEnv;
    in
    {
      invokeai = buildFHSUserEnv {
        name = "invokeai";
        targetPkgs =
          pkgs:
          (with pkgs; [
            alsa-lib
            gcc
            glib
            gnumake
            gtk3
            libGL
            libGLU
            opencv4
            pkg-config
            python312
            python312Packages.pip
            python312Packages.virtualenv
            stdenv.cc.cc.lib
            libx11
            libxext
            libxrender
            zlib
          ]);
        profile = ''
          export INVOKEAI_ROOT=~/.local/share/invokeai
        '';
        runScript = "${prev.bash}/bin/bash";
        meta = with prev.lib; {
          description = "InvokeAI";
          homepage = "https://invoke-ai.github.io/InvokeAI";
          license = licenses.mit;
          platforms = platforms.linux;
        };
      };
    }
  )
  ## terminal-browser
  (
    _final: prev:
    let
      # release tarballs pinned as non-flake inputs; hashes tracked in flake.lock
      srcs = {
        aarch64-darwin = inputs.terminal-browser-darwin;
        x86_64-linux = inputs.terminal-browser-linux;
      };
      system = prev.stdenv.hostPlatform.system;
    in
    prev.lib.optionalAttrs (srcs ? ${system}) {
      terminal-browser = prev.stdenv.mkDerivation {
        pname = "terminal-browser";
        version = prev.lib.removePrefix "v" (prev.lib.trim (builtins.readFile "${srcs.${system}}/VERSION"));
        src = srcs.${system};
        nativeBuildInputs = prev.lib.optionals prev.stdenv.hostPlatform.isLinux [
          prev.autoPatchelfHook
        ];
        buildInputs = prev.lib.optionals prev.stdenv.hostPlatform.isLinux (
          with prev;
          [
            alsa-lib
            at-spi2-atk
            at-spi2-core
            atk
            cairo
            cups
            dbus
            expat
            gdk-pixbuf
            glib
            gtk3
            libGL
            libdrm
            libgbm
            libxkbcommon
            nspr
            nss
            pango
            stdenv.cc.cc.lib
            systemd
            xorg.libX11
            xorg.libXcomposite
            xorg.libXdamage
            xorg.libXext
            xorg.libXfixes
            xorg.libXrandr
            xorg.libxcb
          ]
        );
        dontConfigure = true;
        dontBuild = true;
        # prebuilt binaries; stripping would break the signed darwin app bundle
        dontStrip = true;
        installPhase = ''
          runHook preInstall
          # drop AppleDouble sidecar files (._*) from the tarball; the extra
          # files break the darwin codesign resource seal ("damaged" error)
          find . -name '._*' -delete
          mkdir -p $out/bin $out/opt
          cp -R . $out/opt/terminal-browser
          ln -s $out/opt/terminal-browser/bin/terminal-browser $out/bin/terminal-browser
          runHook postInstall
        '';
        meta = {
          description = "A real browser that runs inside your terminal";
          homepage = "https://github.com/zenbu-labs/terminal-browser";
          mainProgram = "terminal-browser";
          platforms = [
            "aarch64-darwin"
            "x86_64-linux"
          ];
        };
      };
    }
  )
]
