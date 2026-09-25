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
  launchdLabel = config.programs.openclaw.launchd.label;
  secretKeys = [
    "OPENCLAW_DISCORD_BOT_TOKEN"
    "OPENCLAW_DISCORD_CHANNEL_ID"
    "OPENCLAW_DISCORD_USER_ID"
    "OPENCLAW_GATEWAY_TOKEN"
  ];
  secretPath = key: "${config.programs.openclaw.stateDir}/secrets/${key}";
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
      # sops-nix decrypts onto a ram disk on darwin, so at login nothing it
      # places exists yet and launchd hands the gateway these paths verbatim
      openclawSecrets =
        lib.hm.dag.entryBetween [ "openclawLaunchdRelink" ] [ "generateAgeKey" "openclawDirs" ]
          ''
            dir="${config.programs.openclaw.stateDir}/secrets"
            $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p "$dir"
            $DRY_RUN_CMD ${pkgs.coreutils}/bin/chmod 700 "$dir"
            for key in ${lib.concatStringsSep " " secretKeys}; do
              # a stale symlink here would redirect the write into the sops store
              $DRY_RUN_CMD ${pkgs.coreutils}/bin/rm -f "$dir/$key"
              $DRY_RUN_CMD env SOPS_AGE_KEY_FILE="${config.xdg.configHome}/sops/age/keys.txt" \
                ${pkgs.sops}/bin/sops --decrypt \
                --extract "[\"$key\"]" \
                "${config.sops.defaultSopsFile}" >"$dir/$key"
              $DRY_RUN_CMD ${pkgs.coreutils}/bin/chmod 600 "$dir/$key"
            done
          '';
      # upstream points this plist at `/nix/store`, a `noauto` volume a launchd
      # daemon mounts, so at login it can still be a dangling symlink
      openclawLaunchdRelink = lib.mkForce (
        lib.hm.dag.entryAfter [ "linkGeneration" "openclawConfigFiles" ] ''
          plist="${config.home.homeDirectory}/Library/LaunchAgents/${launchdLabel}.plist"
          if [ -L "$plist" ]; then
            $DRY_RUN_CMD /bin/launchctl bootout "gui/$UID/${launchdLabel}" 2>/dev/null || true
            $DRY_RUN_CMD ${pkgs.coreutils}/bin/rm -f "$plist"
          fi
          # home-manager skips an unchanged plist, so restart for a new config
          $DRY_RUN_CMD /bin/launchctl kickstart -k "gui/$UID/${launchdLabel}" 2>/dev/null || true
        ''
      );
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
      # the generated wrapper cats a value that names a file, unless the key
      # ends in _FILE; openclaw itself would take the path as the secret
      environment = {
        OPENCLAW_DISCORD_BOT_TOKEN = secretPath "OPENCLAW_DISCORD_BOT_TOKEN";
        OPENCLAW_DISCORD_CHANNEL_ID = secretPath "OPENCLAW_DISCORD_CHANNEL_ID";
        OPENCLAW_DISCORD_USER_ID = secretPath "OPENCLAW_DISCORD_USER_ID";
        # launchd inherits no login shell, and the claude cli keeps its
        # credentials here rather than in its default ~/.claude
        CLAUDE_CONFIG_DIR = "${config.xdg.configHome}/claude";
        # without a fixed token every paired client drops on restart
        OPENCLAW_GATEWAY_TOKEN = secretPath "OPENCLAW_GATEWAY_TOKEN";
        NODE_OPTIONS = "--import file://${esmLoaderShim}";
      };
      # the subscription route delegates to the claude cli
      runtimePackages = [
        pkgs.claude-code
      ];
      config = {
        agents = {
          defaults = {
            heartbeat = {
              # the scheduler otherwise wakes the model every 30m all night, and
              # only the agent itself knows these hours
              activeHours = {
                start = "09:00";
                end = "23:00";
              };
              # a dm neither threads nor archives, so send the unprompted ones
              # to the channel that does
              target = "discord";
              to = "channel:\${OPENCLAW_DISCORD_CHANNEL_ID}";
            };
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
        session = {
          # the channel is otherwise sealed off in both directions and never
          # sees the dms, `rememberAcrossConversations` included
          groupScope = "main";
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
