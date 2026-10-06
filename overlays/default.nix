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
  ## aivisspeech-engine
  (
    _final: prev:
    prev.lib.optionalAttrs (prev.stdenv.hostPlatform.system == "aarch64-darwin") {
      aivisspeech-engine = prev.stdenv.mkDerivation rec {
        pname = "aivisspeech-engine";
        version = "1.2.0";
        # the release ships a single-volume 7z, which fetchzip cannot open
        src = prev.fetchurl {
          url = "https://github.com/Aivis-Project/AivisSpeech-Engine/releases/download/${version}/AivisSpeech-Engine-macOS-arm64-${version}.7z.001";
          hash = "sha256-WBp/NK+yxTQ/+LJ9bYiFkIM3WGhgdlfelfrVBpORhd8=";
        };
        nativeBuildInputs = [
          prev._7zz
          prev.makeWrapper
        ];
        unpackPhase = ''
          runHook preUnpack
          7zz x -y $src
          runHook postUnpack
        '';
        sourceRoot = "macOS-arm64";
        dontConfigure = true;
        dontBuild = true;
        # prebuilt pyinstaller bundle; stripping would break the vendored runtime
        dontStrip = true;
        # the engine resolves its resources next to `sys.executable`, so the
        # bundle stays whole and bin/ gets a wrapper rather than a symlink
        installPhase = ''
          runHook preInstall
          mkdir -p $out/bin $out/opt
          cp -R . $out/opt/aivisspeech-engine
          makeWrapper $out/opt/aivisspeech-engine/run $out/bin/aivisspeech-engine
          runHook postInstall
        '';
        meta = {
          description = "Style-Bert-VITS2 based Japanese text to speech engine";
          homepage = "https://github.com/Aivis-Project/AivisSpeech-Engine";
          license = prev.lib.licenses.lgpl3Only;
          mainProgram = "aivisspeech-engine";
          platforms = [ "aarch64-darwin" ];
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
          export COMFYUI_ROOT="$HOME/.local/share/comfyui"
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
  ## llm-agents
  (
    _final: prev:
    let
      llm-agents = inputs.llm-agents.packages.${prev.stdenv.hostPlatform.system};
    in
    {
      inherit (llm-agents) agentsview;
      inherit (llm-agents) claude-code;
      inherit (llm-agents) codex;
      grok-build = llm-agents.grok;
    }
  )
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
          export INVOKEAI_ROOT="$HOME/.local/share/invokeai"
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
  ## toad
  (_final: prev: {
    # not in nixpkgs; uvx resolves the pypi wheel at launch
    toad = prev.writeShellScriptBin "toad" ''
      exec ${prev.uv}/bin/uvx --python ${prev.python314}/bin/python3.14 --from batrachian-toad toad "$@"
    '';
  })
]
