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
      comfyui
      invokeai
    ];
    file = {
      ".local/bin/start-comfyui" = {
        executable = true;
        text = ''
          #!/usr/bin/env bash
          set -e
          # Setup config directories
          mkdir -p ${config.home.homeDirectory}/google_drive/ai/workflows
          ln -sf ${config.xdg.configHome}/comfyui/extra_model_paths.yaml ${config.home.homeDirectory}/.local/share/extra_model_paths.yaml
          # Set environment
          export CUDA_VISIBLE_DEVICES=0
          export COMFYUI_ROOT=${config.home.homeDirectory}/.local/share/comfyui
          export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True
          echo "Starting ComfyUI on http://127.0.0.1:8188"
          echo "Press Ctrl+C to stop"
          # Run inside FHS environment
          exec ${pkgs.comfyui}/bin/comfyui ${pkgs.writeShellScript "comfyui-inner" ''
            set -e
            cd ${config.home.homeDirectory}/.local/share
            # Initial setup if needed
            if [ ! -f "comfyui/.comfyui-installed" ]; then
              # Check if ComfyUI is actually cloned (not just an empty directory)
              if [ ! -f "comfyui/main.py" ]; then
                echo "Cloning ComfyUI repository..."
                rm -rf comfyui
                git clone https://github.com/comfyanonymous/ComfyUI.git comfyui
              fi
              cd comfyui
              echo "Creating virtual environment..."
              python3.12 -m venv venv
              source venv/bin/activate
              echo "Installing dependencies..."
              pip install --upgrade pip
              pip install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu121
              pip install -r requirements.txt
              pip install websocket-client
              # Setup custom_nodes and workflows directories
              mkdir -p custom_nodes
              mkdir -p user/default
              # Link custom nodes from Google Drive
              for node_dir in ${config.home.homeDirectory}/google_drive/ai/custom_nodes/*/; do
                if [ -d "$node_dir" ]; then
                  node_name=$(basename "$node_dir")
                  if [ ! -e "custom_nodes/$node_name" ]; then
                    ln -sf "$node_dir" "custom_nodes/$node_name"
                    echo "Linked custom node: $node_name"
                  fi
                fi
              done
              # Setup workflows symlink to Google Drive
              if [ ! -L "user/default/workflows" ]; then
                rm -rf user/default/workflows
                ln -sf ${config.home.homeDirectory}/google_drive/ai/workflows user/default/workflows
                echo "Created symlink: workflows -> ~/google_drive/ai/workflows"
              fi
              # Link extra_model_paths.yaml
              ln -sf ${config.home.homeDirectory}/.local/share/extra_model_paths.yaml extra_model_paths.yaml
              # Install ComfyUI Manager
              if [ ! -d "custom_nodes/ComfyUI-Manager" ]; then
                echo "Installing ComfyUI Manager..."
                cd custom_nodes
                git clone https://github.com/ltdrdata/ComfyUI-Manager.git
                cd ComfyUI-Manager
                pip install -r requirements.txt
                cd ../..
              else
                echo "ComfyUI Manager already installed, skipping..."
              fi
              # Install custom node dependencies
              echo "Installing custom node dependencies..."
              for req_file in custom_nodes/*/requirements.txt; do
                if [ -f "$req_file" ]; then
                  echo "Installing dependencies from $req_file..."
                  pip install -r "$req_file" --quiet || true
                fi
              done
              if [ $? -eq 0 ]; then
                touch .comfyui-installed
              else
                echo "Installation failed!"
                exit 1
              fi
            fi
            # Start ComfyUI
            cd ${config.home.homeDirectory}/.local/share/comfyui
            if [ -f ".comfyui-installed" ] && [ -d "venv" ]; then
              source venv/bin/activate
              # Link custom nodes from Google Drive (check on every startup)
              for node_dir in ${config.home.homeDirectory}/google_drive/ai/custom_nodes/*/; do
                if [ -d "$node_dir" ]; then
                  node_name=$(basename "$node_dir")
                  if [ ! -e "custom_nodes/$node_name" ]; then
                    ln -sf "$node_dir" "custom_nodes/$node_name"
                    echo "Linked custom node: $node_name"
                  fi
                fi
              done
              # Check if custom node dependencies need to be installed
              deps_hash=$(find custom_nodes -name "requirements.txt" -exec cat {} \; 2>/dev/null | md5sum | cut -d' ' -f1)
              if [ ! -f ".deps_hash" ] || [ "$(cat .deps_hash 2>/dev/null)" != "$deps_hash" ]; then
                echo "Installing custom node dependencies (this only runs when requirements change)..."
                for req_file in custom_nodes/*/requirements.txt; do
                  if [ -f "$req_file" ]; then
                    node_name=$(dirname "$req_file" | xargs basename)
                    echo "  Installing deps for $node_name..."
                    pip install -r "$req_file" --quiet 2>/dev/null || true
                  fi
                done
                # Install extra dependencies not listed in requirements.txt
                pip install soundfile av --quiet 2>/dev/null || true
                echo "$deps_hash" > .deps_hash
              fi
              echo "Starting ComfyUI server..."
              exec python main.py --listen 127.0.0.1 --port 8188 --output-directory ${config.home.homeDirectory}/google_drive/ai/outputs/comfyui
            else
              echo "ComfyUI not properly installed!"
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
          # Setup models directory and symlinks
          mkdir -p ${config.home.homeDirectory}/.local/share/invokeai/models
          echo "Creating symlinks for AI resources from Google Drive..."
          # Function to link files from a directory
          link_resources() {
            local source_dir=$1
            local resource_type=$2
            local extensions=$3
            if [ -d "$source_dir" ]; then
              for ext in $extensions; do
                for file in "$source_dir"/*."$ext"; do
                  if [ -f "$file" ]; then
                    file_name=$(basename "$file")
                    target="${config.home.homeDirectory}/.local/share/invokeai/models/$file_name"
                    if [ ! -e "$target" ]; then
                      ln -s "$file" "$target"
                      echo "  Linked $resource_type: $file_name"
                    fi
                  fi
                done
              done
            fi
          }
          # Link main models
          link_resources "${config.home.homeDirectory}/google_drive/ai/models" "model" "safetensors ckpt"
          # Link LoRAs
          link_resources "${config.home.homeDirectory}/google_drive/ai/loras" "LoRA" "safetensors"
          # Link embeddings
          link_resources "${config.home.homeDirectory}/google_drive/ai/embeddings" "embedding" "safetensors pt bin"
          # Link VAE
          link_resources "${config.home.homeDirectory}/google_drive/ai/vae" "VAE" "safetensors pt pth ckpt"
          # Link ControlNet
          link_resources "${config.home.homeDirectory}/google_drive/ai/controlnet" "ControlNet" "safetensors pth"
          # Link upscalers
          link_resources "${config.home.homeDirectory}/google_drive/ai/upscalers" "upscaler" "pth"
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
                          python3.12 -m venv venv
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
                        # Install and patch CLIP Interrogator node if not present
                        if [ -f "venv/bin/activate" ]; then
                          source venv/bin/activate
                          if [ ! -d "nodes/clipInterrogator-invokeai-node" ]; then
                            echo "Installing CLIP Interrogator node..."
                            mkdir -p nodes
                            cd nodes
                            git clone https://github.com/Trase1/clipInterrogator-invokeai-node.git
                            cd clipInterrogator-invokeai-node
                            pip install clip-interrogator==0.6.0
                            # Patch for InvokeAI 6.9.0 compatibility
                            echo "Patching CLIP Interrogator node for InvokeAI 6.9.0..."
                            cat > clipInterrogator_node.py << 'PATCH_EOF'
            from invokeai.invocation_api import (
                BaseInvocation,
                BaseInvocationOutput,
                invocation,
                invocation_output,
                InputField,
                OutputField,
                InvocationContext,
                ImageField,
            )
            from PIL import Image
            import torch
            try:
                from clip_interrogator import Config, Interrogator
            except ImportError:
                print("clip-interrogator is not installed, please install it with 'pip install clip-interrogator'")
                exit(1)
            @invocation_output("clip_interrogator_output")
            class CLIPInterrogatorOutput(BaseInvocationOutput):
                """Output for CLIP Interrogator with positive and negative prompts"""
                positive: str = OutputField(description="Positive prompt describing the image")
                negative: str = OutputField(description="Negative prompt for undesired elements")
            @invocation(
                "CLIPInterrogator",
                title="CLIP Interrogator",
                tags=["CLIP", "prompt", "interrogation"],
                category="image",
                version="0.1.0",
            )
            class clipInterrogatorInvocation(BaseInvocation):
                """Generates prompt from given picture with CLIP interrogator"""
                image: ImageField = InputField(description="The input image")
                clip_model: str = InputField(
                    default="ViT-L-14/openai",
                    description="CLIP model to use (ViT-L-14/openai: 75-79% SFW-filtered, ViT-H-14/laion2b_s32b_b79k: 80.5% NSFW-capable - BEST FOR 12GB VRAM, ViT-bigG-14/laion2b_s39b_b160k: 82.1% NSFW-capable - requires 16GB+ VRAM)"
                )
                mode: str = InputField(
                    default="best",
                    description="Interrogation mode: 'best' for highest quality, 'fast' for speed, 'classic' for SD1.5"
                )
                chunk_size: int = InputField(
                    default=2048,
                    description="Batch size for CLIP processing (higher = more VRAM, faster processing, ViT-L-14 default: 2048)"
                )
                caption_max_length: int = InputField(
                    default=64,
                    description="Maximum caption length in tokens (default: 32, higher = more detailed captions)"
                )
                caption_model_name: str = InputField(
                    default="blip-large",
                    description="BLIP caption model (blip-base: faster/lower VRAM, blip-large: better quality)"
                )
                flavor_intermediate_count: int = InputField(
                    default=2048,
                    description="Number of flavor candidates before ranking (default: 2048, low VRAM: 1024)"
                )
                max_flavors: int = InputField(
                    default=32,
                    description="Maximum flavor phrases for best mode (higher = more detailed prompts, 8-32 recommended)"
                )
                min_flavors: int = InputField(
                    default=32,
                    description="Minimum flavor phrases for best mode (higher = more consistent detail, default: 8, recommended: 16-24)"
                )
                def invoke(self, context: InvocationContext) -> CLIPInterrogatorOutput:
                    device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
                    if not torch.cuda.is_available():
                        context.logger.warning("CUDA is not available, using CPU. Warning: this will be very slow!")
                    config = Config(
                        device=device,
                        clip_model_name=self.clip_model,
                        chunk_size=self.chunk_size,
                        caption_max_length=self.caption_max_length,
                        caption_model_name=self.caption_model_name,
                        flavor_intermediate_count=self.flavor_intermediate_count,
                        quiet=False
                    )
                    image = context.images.get_pil(self.image.image_name).convert('RGB')
                    ci = Interrogator(config)
                    # Generate positive prompt based on mode
                    if self.mode == 'best':
                        prompt = ci.interrogate(image, min_flavors=self.min_flavors, max_flavors=self.max_flavors)
                    elif self.mode == 'fast':
                        prompt = ci.interrogate_fast(image, max_flavors=self.max_flavors)
                    elif self.mode == 'classic':
                        prompt = ci.interrogate_classic(image)
                    else:
                        prompt = ci.interrogate_fast(image, max_flavors=self.max_flavors)  # fallback to fast
                    context.logger.info(f"Generated prompt ({self.mode} mode): {prompt}")
                    return CLIPInterrogatorOutput(positive=prompt, negative="")
            PATCH_EOF
                            echo "CLIP Interrogator node patched successfully!"
                            cd ../..
                          else
                            # Ensure dependencies are installed (e.g. after venv recreation)
                            if ! python -c "import clip_interrogator" 2>/dev/null; then
                              echo "Reinstalling CLIP Interrogator dependencies..."
                              pip install clip-interrogator==0.6.0
                            fi
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
          "d ${config.home.homeDirectory}/google_drive/ai/svd 0755 - - -"
          "d ${config.home.homeDirectory}/google_drive/ai/outputs 0755 - - -"
          "d ${config.home.homeDirectory}/google_drive/ai/outputs/comfyui 0755 - - -"
          "d ${config.home.homeDirectory}/google_drive/ai/workflows 0755 - - -"
          "d ${config.home.homeDirectory}/google_drive/ai/custom_nodes 0755 - - -"
          "d ${config.home.homeDirectory}/google_drive/ai/prompts 0755 - - -"
          "d ${config.home.homeDirectory}/.local/share/invokeai 0755 - - -"
          "d ${config.home.homeDirectory}/.local/share/invokeai/models 0755 - - -"
        ];
      };
    };
  };
}
