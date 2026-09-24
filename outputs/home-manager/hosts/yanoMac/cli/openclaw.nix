# home openclaw module
{
  config,
  inputs,
  lib,
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
  # home
  home = {
    activation = {
      # sops-nix can only place a symlink and `$include` rejects one that
      # resolves out of the config root, so decrypt this one straight in
      openclawGuilds =
        lib.hm.dag.entryBetween [ "openclawLaunchdRelink" ] [ "generateAgeKey" "openclawDirs" ]
          ''
            dst="${config.programs.openclaw.stateDir}/guilds.json5"
            # a stale symlink here would redirect the write into the sops store
            $DRY_RUN_CMD ${pkgs.coreutils}/bin/rm -f "$dst"
            $DRY_RUN_CMD env SOPS_AGE_KEY_FILE="${config.xdg.configHome}/sops/age/keys.txt" \
              ${pkgs.sops}/bin/sops --decrypt \
              --extract '["OPENCLAW_DISCORD_GUILDS"]' \
              "${config.sops.defaultSopsFile}" >"$dst"
            $DRY_RUN_CMD ${pkgs.coreutils}/bin/chmod 600 "$dst"
          '';
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
        # launchd inherits no login shell, and the claude cli keeps its
        # credentials here rather than in its default ~/.claude
        CLAUDE_CONFIG_DIR = "${config.xdg.configHome}/claude";
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
              "$include" = "${config.programs.openclaw.stateDir}/guilds.json5";
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
