# home openclaw module
{
  config,
  inputs,
  pkgs,
  username,
  ...
}:
let
  # any --import brings node's ESM loader up first, which is what makes the
  # bundled discord plugin's dual CJS/ESM dependency resolve
  esmLoaderShim = pkgs.writeText "openclaw-esm-loader-shim.mjs" "";
in
{
  imports = [
    inputs.openclaw.homeManagerModules.openclaw
  ];
  # sops
  sops = {
    secrets = {
      # `$include` refuses paths outside the config root
      OPENCLAW_DISCORD_GUILDS = {
        path = "${config.programs.openclaw.stateDir}/guilds.json5";
      };
    };
  };
  # programs
  programs = {
    openclaw = {
      enable = true;
      # sessions, sqlite and logs; the generated config sits here too
      stateDir = "${config.xdg.stateHome}/openclaw";
      # keeps the persona files out of this public repo; `bootstrapFiles` stays
      # unset because it would rewrite them on every activation. the real path,
      # not the ~/google_drive symlink, which has no ordering against this
      workspaceDir = "${config.home.homeDirectory}/GoogleDrive/${username}/openclaw/workspace";
      # a path in a variable not ending in _FILE is read at runtime
      environment = {
        OPENCLAW_DISCORD_BOT_TOKEN = config.sops.secrets.OPENCLAW_DISCORD_BOT_TOKEN.path;
        OPENCLAW_DISCORD_USER_ID = config.sops.secrets.OPENCLAW_DISCORD_USER_ID.path;
        # without a fixed token every paired client drops on restart
        OPENCLAW_GATEWAY_TOKEN = config.sops.secrets.OPENCLAW_GATEWAY_TOKEN.path;
        NODE_OPTIONS = "--import file://${esmLoaderShim}";
      };
      # the subscription route delegates to the claude cli
      runtimePackages = [
        pkgs.claude-code
      ];
      config = {
        agents = {
          defaults = {
            model = {
              primary = "anthropic/claude-opus-5-5";
            };
            models = {
              "anthropic/claude-opus-5-5" = {
                agentRuntime = {
                  id = "claude-cli";
                };
              };
            };
          };
        };
        gateway = {
          # reachable from the home lan; the fixed token and this origin list are
          # what a non-loopback bind requires
          bind = "lan";
          controlUi = {
            allowedOrigins = [
              "http://yanoMac.local:18789"
            ];
          };
        };
        memory = {
          search = {
            # threads and dms are separate sessions, so recall across them is the
            # only way the agent carries context between them
            rememberAcrossConversations = true;
          };
        };
        plugins = {
          # bundled but off until named here
          entries = {
            "active-memory" = {
              enabled = true;
            };
            "discord" = {
              enabled = true;
            };
            "document-extract" = {
              enabled = true;
            };
            "llm-task" = {
              enabled = true;
            };
            "logbook" = {
              enabled = true;
            };
            "memory-wiki" = {
              enabled = true;
            };
            "migrate-claude" = {
              enabled = true;
            };
            "oc-path" = {
              enabled = true;
            };
            "policy" = {
              enabled = true;
            };
            "web-readability" = {
              enabled = true;
            };
            "webhooks" = {
              enabled = true;
            };
            "workboard" = {
              enabled = true;
            };
          };
        };
        channels = {
          discord = {
            enabled = true;
            # an allowlisted sender counts as approved, so no pairing handshake
            allowFrom = [
              "\${OPENCLAW_DISCORD_USER_ID}"
            ];
            dmPolicy = "allowlist";
            # a thread otherwise starts blank; seed it from the channel it grew out of
            thread = {
              inheritParent = true;
            };
            # keyed by the numeric server id, which ${VAR} cannot template out
            guilds = {
              "$include" = config.sops.secrets.OPENCLAW_DISCORD_GUILDS.path;
            };
            token = {
              source = "env";
              provider = "default";
              id = "OPENCLAW_DISCORD_BOT_TOKEN";
            };
          };
        };
      };
    };
  };
}
