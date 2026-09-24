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
  ## agy-acp-server
  (
    _final: prev:
    let
      # release archives pinned as non-flake inputs; hashes tracked in flake.lock
      srcs = {
        aarch64-darwin = inputs.agy-acp-server-darwin;
        x86_64-linux = inputs.agy-acp-server-linux;
      };
      system = prev.stdenv.hostPlatform.system;
    in
    prev.lib.optionalAttrs (srcs ? ${system}) {
      agy-acp-server = prev.stdenv.mkDerivation {
        pname = "agy-acp-server";
        version = "1.1.1";
        src = srcs.${system};
        nativeBuildInputs = [
          prev.makeWrapper
        ]
        ++ prev.lib.optionals prev.stdenv.hostPlatform.isLinux [
          prev.autoPatchelfHook
        ];
        buildInputs = prev.lib.optionals prev.stdenv.hostPlatform.isLinux (
          with prev;
          [
            stdenv.cc.cc.lib
            zlib
          ]
        );
        dontConfigure = true;
        dontBuild = true;
        # prebuilt mach-o/elf binary; stripping would break the vendored runtime
        dontStrip = true;
        installPhase =
          let
            # the registry passes an empty uid on linux only
            extraFlags = prev.lib.optionalString prev.stdenv.hostPlatform.isLinux "--add-flags --uid=";
          in
          ''
            runHook preInstall
            mkdir -p $out/bin $out/libexec
            install -m555 agy_acp_server.par $out/libexec/agy_acp_server
            makeWrapper $out/libexec/agy_acp_server $out/bin/agy_acp_server ${extraFlags}
            runHook postInstall
          '';
        meta = {
          description = "Agent Client Protocol server for the Google Antigravity CLI";
          homepage = "https://antigravity.google/docs/ide/extensions";
          mainProgram = "agy_acp_server";
          platforms = [
            "aarch64-darwin"
            "x86_64-linux"
          ];
        };
      };
    }
  )
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
  ## openclaw
  # the home-manager module reads pkgs.openclawPackages, so take the whole overlay
  inputs.openclaw.overlays.default
  ## openclaw discord bundling
  (
    _final: prev:
    let
      # only plugins inside the host package get durable state, so the
      # `plugins.load.paths` route is refused (openclaw/nix-openclaw#158)
      gateway = prev.openclaw-gateway.overrideAttrs (old: {
        installPhase = ''
          ${old.installPhase}
          ext="$out/lib/node_modules/openclaw/dist/extensions/discord"
          cp -r ${prev.openclawRuntimePlugins.discord} "$ext"
          chmod -R u+w "$ext"
          # pins the peer to the gateway it was built against, which would load
          # a second runtime copy; bundled extensions resolve it from the parent
          rm -f "$ext/node_modules/openclaw"
        '';
      });
      withDiscord =
        set:
        set
        // {
          openclaw-gateway = gateway;
          openclaw = set.openclaw.override { openclaw-gateway = gateway; };
        };
    in
    {
      openclaw-gateway = gateway;
      openclaw = prev.openclaw.override { openclaw-gateway = gateway; };
      # the module composes a fresh set when a tool override applies
      openclawPackages = (withDiscord prev.openclawPackages) // {
        withTools = args: withDiscord (prev.openclawPackages.withTools args);
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
            libx11
            libxcb
            libxcomposite
            libxdamage
            libxext
            libxfixes
            libxkbcommon
            libxrandr
            nspr
            nss
            pango
            stdenv.cc.cc.lib
            systemd
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
  ## toad
  (_final: prev: {
    # not in nixpkgs; uvx resolves the pypi wheel at launch
    toad = prev.writeShellScriptBin "toad" ''
      exec ${prev.uv}/bin/uvx --python ${prev.python314}/bin/python3.14 --from batrachian-toad toad "$@"
    '';
  })
]
