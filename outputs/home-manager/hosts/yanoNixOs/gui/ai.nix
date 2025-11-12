# home ai module
{
  config,
  lib,
  pkgs,
  ...
}:
{
  # home
  home = {
    packages = with pkgs; [
      cuda-comfyui
      invokeai
      fooocus
    ];
    file = {
      ".local/bin/start-comfyui" = {
        executable = true;
        text = ''
          #!/usr/bin/env bash
          set -e
          # Setup config
          mkdir -p ${config.home.homeDirectory}/.local/share/comfyui
          ln -sf ${config.xdg.configHome}/comfyui/extra_model_paths.yaml ${config.home.homeDirectory}/.local/share/comfyui/extra_model_paths.yaml
          cd ${config.home.homeDirectory}/.local/share/comfyui
          # Set environment
          export CUDA_VISIBLE_DEVICES=0
          export NIX_COMFYUI_STATE_DIRS=custom_nodes
          export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True
          echo "Starting ComfyUI on http://127.0.0.1:8188"
          echo "Press Ctrl+C to stop"
          # Start ComfyUI
          exec ${lib.getExe' pkgs.cuda-comfyui "comfyui"} --listen 127.0.0.1 --port 8188 --output-directory ${config.home.homeDirectory}/google_drive/ai/outputs/comfyui
        '';
      };
      ".local/bin/start-fooocus" = {
        executable = true;
        text = ''
          #!/usr/bin/env bash
          set -e
          # Setup config
          ln -sf ${config.xdg.configHome}/fooocus/config.txt ${config.home.homeDirectory}/.local/share/Fooocus/config.txt
          # Set environment
          export CUDA_VISIBLE_DEVICES=0
          export FOOOCUS_ROOT=${config.home.homeDirectory}/.local/share/Fooocus
          export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True
          echo "Starting Fooocus on http://127.0.0.1:7865"
          echo "Press Ctrl+C to stop"
          # Run inside FHS environment
          exec ${pkgs.fooocus}/bin/fooocus ${pkgs.writeShellScript "fooocus-inner" ''
            set -e
            cd ${config.home.homeDirectory}/.local/share
            # Initial setup if needed
            if [ ! -f "Fooocus/.fooocus-installed" ]; then
              if [ ! -d "Fooocus" ]; then
                echo "Cloning Fooocus repository..."
                git clone https://github.com/lllyasviel/Fooocus.git
              fi
              cd ${config.home.homeDirectory}/.local/share/Fooocus
              echo "Creating virtual environment..."
              python3.11 -m venv venv
              source venv/bin/activate
              echo "Installing dependencies..."
              pip install --upgrade pip
              pip install -r requirements_versions.txt
              if [ $? -eq 0 ]; then
                touch ${config.home.homeDirectory}/.local/share/Fooocus/.fooocus-installed
              else
                echo "Installation failed!"
                exit 1
              fi
            fi
            # Start  Fooocus
            if [ -f "Fooocus/.fooocus-installed" ] && [ -d "Fooocus/venv" ]; then
              cd ${config.home.homeDirectory}/.local/share/Fooocus
              source venv/bin/activate
              exec python launch.py --listen 127.0.0.1 --port 7865
            else
              echo "Fooocus not properly installed!"
              exit 1
            fi
          ''}
        '';
      };
      ".local/bin/start-invokeai" = {
        executable = true;
        text = ''
          #!/usr/bin/env bash
          set -e
          # Setup config
          rm -f ${config.home.homeDirectory}/.local/share/invokeai/invokeai.yaml
          cp ${config.xdg.configHome}/invokeai/invokeai.yaml ${config.home.homeDirectory}/.local/share/invokeai/invokeai.yaml
          # Set environment
          export CUDA_VISIBLE_DEVICES=0
          export INVOKEAI_ROOT=${config.home.homeDirectory}/.local/share/invokeai
          export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True
          echo "Starting InvokeAI on http://127.0.0.1:9090"
          echo "Press Ctrl+C to stop"
          # Run inside FHS environment
          exec ${pkgs.invokeai}/bin/invokeai ${pkgs.writeShellScript "invokeai-inner" ''
            set -e
            cd ${config.home.homeDirectory}/.local/share/invokeai
            # Initial setup if needed
            if [ ! -f ".invokeai-installed" ]; then
              echo "Setting up InvokeAI for the first time..."
              python3.11 -m venv venv
              source venv/bin/activate
              pip install --upgrade pip
              pip install "InvokeAI[xformers]" --upgrade
              if [ $? -eq 0 ]; then
                touch ${config.home.homeDirectory}/.local/share/invokeai/.invokeai-installed
              else
                echo "Installation failed!"
                exit 1
              fi
            fi
            # Start InvokeAI
            if [ -f ".invokeai-installed" ] && [ -d "venv" ]; then
              source venv/bin/activate
              exec invokeai-web --root ${config.home.homeDirectory}/.local/share/invokeai
            else
              echo "InvokeAI not properly installed!"
              exit 1
            fi
          ''}
        '';
      };
    };
  };
  # systemd
  systemd = {
    user = {
      tmpfiles = {
        rules = [
          "d ${config.home.homeDirectory}/google_drive/ai 0755 - - -"
          "d ${config.home.homeDirectory}/google_drive/ai/models 0755 - - -"
          "d ${config.home.homeDirectory}/google_drive/ai/loras 0755 - - -"
          "d ${config.home.homeDirectory}/google_drive/ai/embeddings 0755 - - -"
          "d ${config.home.homeDirectory}/google_drive/ai/vae 0755 - - -"
          "d ${config.home.homeDirectory}/google_drive/ai/controlnet 0755 - - -"
          "d ${config.home.homeDirectory}/google_drive/ai/upscalers 0755 - - -"
          "d ${config.home.homeDirectory}/google_drive/ai/outputs 0755 - - -"
          "d ${config.home.homeDirectory}/.local/share/comfyui 0755 - - -"
          "d ${config.home.homeDirectory}/.local/share/comfyui/custom_nodes 0755 - - -"
          "d ${config.home.homeDirectory}/.local/share/invokeai 0755 - - -"
        ];
      };
    };
  };
}
