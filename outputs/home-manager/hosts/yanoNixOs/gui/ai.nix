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
