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
  ## comfyui (FHS environment for full compatibility)
  (
    final: prev:
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
            python311
            python311Packages.pip
            python311Packages.virtualenv
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
  ## fooocus
  (
    final: prev:
    let
      buildFHSUserEnv = prev.buildFHSUserEnv or prev.buildFHSEnv;
      openblas-pc = prev.writeTextFile {
        name = "openblas-pc";
        destination = "/lib/pkgconfig/openblas.pc";
        text = ''
          libdir=${prev.openblas}/lib
          includedir=${prev.openblas}/include
          Name: OpenBLAS
          Description: OpenBLAS is an optimized BLAS library
          Version: ${prev.openblas.version}
          Libs: -L''${libdir} -lopenblas
          Cflags: -I''${includedir}
        '';
      };
    in
    {
      fooocus = buildFHSUserEnv {
        name = "fooocus";
        targetPkgs =
          pkgs:
          (with pkgs; [
            alsa-lib
            cmake
            cudaPackages.cudatoolkit
            cudaPackages.cudnn
            gcc
            gfortran
            git
            git-lfs
            glib
            gnumake
            gtk3
            libGL
            libGLU
            linuxPackages.nvidia_x11
            openblas
            openblas-pc
            pkg-config
            python311
            python311Packages.pip
            python311Packages.virtualenv
            stdenv.cc.cc.lib
            xorg.libX11
            xorg.libXext
            xorg.libXrender
            zlib
          ]);
        multiPkgs = pkgs: (with pkgs; [ openblas ]);
        profile = ''
          export FOOOCUS_ROOT=~/.local/share/Fooocus
          export PKG_CONFIG_PATH="${openblas-pc}/lib/pkgconfig:$PKG_CONFIG_PATH"
          export LDFLAGS="-L${prev.openblas}/lib $LDFLAGS"
          export CPPFLAGS="-I${prev.openblas}/include $CPPFLAGS"
        '';
        runScript = "${prev.bash}/bin/bash";
        meta = with prev.lib; {
          description = "Fooocus";
          homepage = "https://github.com/lllyasviel/Fooocus";
          license = licenses.gpl3;
          platforms = platforms.linux;
        };
      };
    }
  )
  ## invokeai
  (
    final: prev:
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
            python311
            python311Packages.pip
            python311Packages.virtualenv
            stdenv.cc.cc.lib
            xorg.libX11
            xorg.libXext
            xorg.libXrender
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
  ## mediaplayer
  (final: prev: {
    mediaplayer = inputs.mediaplayer.packages.${prev.stdenv.hostPlatform.system}.default;
  })
  ## wrangler
  (final: prev: {
    wrangler = inputs.wrangler.packages.${prev.stdenv.hostPlatform.system}.default;
  })
]
