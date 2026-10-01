# home openclaw module
{
  aiModels,
  config,
  hostname,
  inputs,
  lib,
  openclawFeeds,
  pkgs,
  system,
  username,
  ...
}:
let
  # the gateway listens here; the control ui is served off the same port
  gatewayPort = 18789;
  # any --import brings node's ESM loader up first, which is what makes the
  # bundled discord plugin's dual CJS/ESM dependency resolve
  esmLoaderShim = pkgs.writeText "openclaw-esm-loader-shim.mjs" "";
  launchdLabel = config.programs.openclaw.launchd.label;
  # the same real path as the main workspace, not the symlink
  devWorkspaceDir = "${config.home.homeDirectory}/GoogleDrive/${username}/openclaw/workspace-dev";
  # the private details live in the workspace skills AGENTS.md names, so the
  # prompt itself says nothing private. the stock one ends by asking for
  # `NO_REPLY` when nothing needs attention, which those skills contradict
  heartbeatPrompt = "Follow the heartbeat check-in skill named in AGENTS.md. Send at most one check-in with the message tool, then reply exactly NO_REPLY.";
  # feedsArgv <workspace>: the command a feeds job runs; its config is private
  # and sits in the workspace
  feedsArgv =
    workspace:
    lib.escapeShellArg (
      builtins.toJSON [
        (lib.getExe openclawFeeds)
        "${workspace}/skills/feeds/config.json"
      ]
    );
  secretKeys = [
    "OPENCLAW_DISCORD_BOT_TOKEN"
    "OPENCLAW_DISCORD_CHANNEL_ID"
    # keeps the channel id out of this public repository
    "OPENCLAW_DISCORD_DEV_CHANNEL_ID"
    "OPENCLAW_DISCORD_USER_ID"
    "OPENCLAW_GATEWAY_TOKEN"
  ];
  secretPath = key: "${config.programs.openclaw.stateDir}/secrets/${key}";
  # `imports` is resolved before the module system settles, so the `pkgs`
  # module argument cannot be used to build one. take a bare nixpkgs instead
  patchPkgs = inputs.nixpkgs.legacyPackages.${system};
  # upstream declares every provider record open — zod `.catchall` for tts,
  # typebox `additionalProperties: true` for talk — because the provider keys
  # come from the extensions, not the core schema. nix-openclaw's generator
  # drops that tail, so the options it emits accept `apiKey` and nothing else
  # and `tts.providers."tts-local-cli".command` fails to evaluate. restore the
  # freeform tail on the six records that have it upstream; the count is
  # asserted so a regenerated file cannot quietly stop matching
  openclawSrc = patchPkgs.runCommand "nix-openclaw-freeform-providers" { } ''
    ${patchPkgs.coreutils}/bin/cp -r ${inputs.openclaw} $out
    ${patchPkgs.coreutils}/bin/chmod -R u+w $out
    ${patchPkgs.lib.getExe patchPkgs.python3} - "$out/nix/generated/openclaw-config-options.nix" <<'PY'
    import re, sys, pathlib

    path = pathlib.Path(sys.argv[1])
    text = path.read_text()
    # `apiKey` as the first field is what marks the open provider records
    # (tts x4, talk x2). `models.providers` and `secrets.providers` share the
    # shape but are closed upstream, and lead with a different field
    pattern = re.compile(
        r"(providers = lib\.mkOption \{\n\s*type = t\.nullOr "
        r"\(t\.attrsOf \(t\.submodule \{) (options = \{\n\s*apiKey = )"
    )
    text, count = pattern.subn(r"\1 freeformType = t.attrsOf t.anything; \2", text)
    if count != 6:
        raise SystemExit(f"expected 6 open provider records, patched {count}")
    path.write_text(text)
    PY
  '';
in
{
  imports = [
    "${openclawSrc}/nix/modules/home-manager/openclaw.nix"
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
      # openclaw hardcodes `.claude/projects` and never reads CLAUDE_CONFIG_DIR,
      # so it found no transcript and resumed no claude-cli session
      openclawClaudeProjects = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        link="${config.home.homeDirectory}/.claude/projects"
        $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p "${config.xdg.configHome}/claude/projects" \
          "${config.home.homeDirectory}/.claude"
        # `ln` would nest the link inside a real directory left here
        if [ -d "$link" ] && [ ! -L "$link" ]; then
          $DRY_RUN_CMD ${pkgs.coreutils}/bin/mv "$link" "$link.$(${pkgs.coreutils}/bin/date +%s).bak"
        fi
        $DRY_RUN_CMD ${pkgs.coreutils}/bin/ln -sfn "${config.xdg.configHome}/claude/projects" "$link"
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
      # openclaw has no config surface for scheduled jobs: `cron` in the schema
      # only carries global behaviour, and the jobs shipped by features declare
      # themselves in code. so the jobs these workspaces want are declared from
      # here instead, where it is reviewable and survives a rebuild.
      # `--declaration-key` is an upsert: re-running this updates the existing
      # job in place rather than adding a second one, so activation is safe to
      # repeat. that key is the job's identity — renaming it creates a second
      # job and orphans the first, so it has to stay put
      openclawAutomations = lib.hm.dag.entryAfter [ "openclawLaunchdRelink" ] ''
        # without the env the cli reads its own default config, points at
        # `ws://` and never reaches this gateway. the redirections matter just
        # as much: the cli reaches for the terminal, and activation does not
        # always own one, so a bare call earns SIGTTOU and suspends the switch
        openclaw() {
          ${lib.getExe config.programs.openclaw.package} "$@" \
            </dev/null >/dev/null 2>&1
        }
        export OPENCLAW_CONFIG_PATH="${config.programs.openclaw.stateDir}/openclaw.json"
        export OPENCLAW_STATE_DIR="${config.programs.openclaw.stateDir}"
        # the gateway was just kicked; the cli talks to it over the socket, so
        # wait for it to answer before declaring anything
        ready=""
        for _ in $(${pkgs.coreutils}/bin/seq 1 30); do
          if openclaw automations list; then
            ready=1
            break
          fi
          ${pkgs.coreutils}/bin/sleep 1
        done
        devChannel="${secretPath "OPENCLAW_DISCORD_DEV_CHANNEL_ID"}"
        if [ -z "$ready" ]; then
          echo "openclaw gateway did not answer; skipped declaring automations" >&2
        else
          # the main session, not an isolated one: an isolated run would sit
          # next to the heartbeat instead of in the conversation it continues
          if ! $DRY_RUN_CMD openclaw automations add \
            --name daily-thread \
            --display-name "Daily thread" \
            --declaration-key workspace:daily-thread \
            --cron "0 0 * * *" --tz Asia/Tokyo --exact \
            --session main \
            --system-event "Use the daily-thread skill."; then
            echo "failed to declare the daily-thread automation" >&2
          fi
          # the feeds jobs run openclaw-feeds with no model turn. the scheduler
          # kills a command after 10 minutes by default, and the grok sections
          # alone may take 20. GROK_HOME is where grok signs in, and
          # OPENCLAW_FEEDS keeps my grok hooks out of the run. once each morning:
          # the grok sections have to fit the plan's weekly allowance
          if ! $DRY_RUN_CMD openclaw automations add \
            --name feeds \
            --display-name "Feeds" \
            --declaration-key workspace:feeds \
            --agent main \
            --cron "0 6 * * *" --tz Asia/Tokyo --exact \
            --no-deliver \
            --timeout-seconds 1800 \
            --command-argv ${feedsArgv config.programs.openclaw.workspaceDir} \
            --command-env "GROK_HOME=${config.xdg.configHome}/grok" \
            --command-env OPENCLAW_FEEDS=1; then
            echo "failed to declare the feeds automation" >&2
          fi
          if ! $DRY_RUN_CMD openclaw automations add \
            --name dev-feeds \
            --display-name "Dev feeds" \
            --declaration-key workspace-dev:feeds \
            --agent dev \
            --cron "30 6 * * *" --tz Asia/Tokyo --exact \
            --no-deliver \
            --timeout-seconds 1800 \
            --command-argv ${feedsArgv devWorkspaceDir} \
            --command-env "GROK_HOME=${config.xdg.configHome}/grok" \
            --command-env OPENCLAW_FEEDS=1; then
            echo "failed to declare the dev-feeds automation" >&2
          fi
          # both dev jobs post with the message tool into today's thread, so
          # nothing is delivered from the final reply. `--to` stays because
          # it is what gives the run its current channel; an empty id would
          # leave the run with no channel to post in. the half-hour lead on
          # dev-trends leaves dev-feeds time to refresh the file it reads
          if [ ! -s "$devChannel" ]; then
            echo "missing $devChannel; skipped declaring dev-trends and dev-daily-thread" >&2
          else
            if ! $DRY_RUN_CMD openclaw automations add \
              --name dev-trends \
              --display-name "Dev trends" \
              --declaration-key workspace-dev:dev-trends \
              --agent dev \
              --cron "0 7,19 * * *" --tz Asia/Tokyo --exact \
              --session isolated \
              --no-deliver --channel discord \
              --to "channel:$(${pkgs.coreutils}/bin/cat "$devChannel")" \
              --message "Use the dev-trends skill."; then
              echo "failed to declare the dev-trends automation" >&2
            fi
            if ! $DRY_RUN_CMD openclaw automations add \
              --name dev-daily-thread \
              --display-name "Dev daily thread" \
              --declaration-key workspace-dev:daily-thread \
              --agent dev \
              --cron "0 0 * * *" --tz Asia/Tokyo --exact \
              --session isolated \
              --no-deliver --channel discord \
              --to "channel:$(${pkgs.coreutils}/bin/cat "$devChannel")" \
              --message "Use the daily-thread skill."; then
              echo "failed to declare the dev-daily-thread automation" >&2
            fi
          fi
        fi
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
  # services
  services = {
    # the dev agent signs unattended with my key, so one passphrase entry has
    # to last until the next login. the agent still forgets it on restart
    gpg-agent = {
      defaultCacheTtl = 31536000;
      maxCacheTtl = 31536000;
    };
  };
  # programs
  programs = {
    openclaw = {
      enable = true;
      # the mac app ships as a bundle of ~80k files, and upstream places it
      # through `home.file` with `recursive = true`, so every rebuild relinked
      # all of them one at a time — 99% of this generation's links and most of
      # `make home`'s wall clock. nothing here uses the gui; the gateway runs
      # under launchd, which this does not touch
      installApp = false;
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
        OPENCLAW_DISCORD_DEV_CHANNEL_ID = secretPath "OPENCLAW_DISCORD_DEV_CHANNEL_ID";
        OPENCLAW_DISCORD_USER_ID = secretPath "OPENCLAW_DISCORD_USER_ID";
        # launchd inherits no login shell, and the claude cli keeps its
        # credentials here rather than in its default ~/.claude
        CLAUDE_CONFIG_DIR = "${config.xdg.configHome}/claude";
        # without a fixed token every paired client drops on restart
        OPENCLAW_GATEWAY_TOKEN = secretPath "OPENCLAW_GATEWAY_TOKEN";
        # launchd sets no locale, and the agents count characters: with none,
        # `wc -m` counts bytes
        LANG = "ja_JP.UTF-8";
        NODE_OPTIONS = "--import file://${esmLoaderShim}";
        # the agents ask grok about x; it signs in from here, and my grok hooks
        # skip when this is set instead of editing the dotfiles repository
        GROK_HOME = "${config.xdg.configHome}/grok";
        OPENCLAW_FEEDS = "1";
      };
      # the subscription route delegates to the claude cli. gpg lets the dev
      # agent sign its commits as me: branch protection rejects unsigned ones.
      # openclaw-feeds is there for an agent to refresh its feeds by hand
      runtimePackages = [
        openclawFeeds
        pkgs.claude-code
        pkgs.gnupg
        pkgs.grok-build
      ];
      config = {
        agents = {
          defaults = {
            # the check-ins go out through the message tool into the day's
            # thread, so nothing from the turn itself is delivered: a preamble
            # the model writes before its tools would otherwise land in the
            # channel as is
            # hourly: the check-in skills only stay quiet mid-conversation, so
            # the interval alone sets how often they speak up
            heartbeat = {
              every = "1h";
              target = "none";
            };
            # the same tier the claude cli drops to outside plan mode, from
            # lib/ai-models.nix; this gateway never plans
            model = {
              primary = "anthropic/${aiModels.run}";
            };
          };
          # once any entry carries a heartbeat block, only the entries that
          # carry one run heartbeats, so main needs its own as well
          entries = {
            main = {
              default = true;
              workspace = config.programs.openclaw.workspaceDir;
              heartbeat = {
                prompt = heartbeatPrompt;
              };
            };
            dev = {
              workspace = devWorkspaceDir;
              heartbeat = {
                prompt = heartbeatPrompt;
              };
            };
          };
        };
        # the dev channel and its threads go to the dev agent; everything
        # else falls to main
        bindings = [
          {
            agentId = "dev";
            match = {
              channel = "discord";
              peer = {
                kind = "channel";
                id = "\${OPENCLAW_DISCORD_DEV_CHANNEL_ID}";
              };
            };
          }
        ];
        commands = {
          # only pairing registers a command owner, and an allowlisted sender
          # counts as approved without the handshake, so none was ever
          # recorded and every owner-only command came back unauthorized.
          # the pairing bootstrap writes the owner into the config too, which
          # nix owns here, so it could not have landed either way
          ownerAllowFrom = [ "discord:\${OPENCLAW_DISCORD_USER_ID}" ];
          # the only sender that reaches this gateway is already the owner, so
          # the second allowlist layer has nothing left to keep out
          allowFrom = {
            discord = [ "*" ];
          };
          # the rest of the chat commands that ship disabled. `/config`,
          # `/mcp` and `/plugins` persist into `openclaw.json`, which is a
          # read-only nix symlink here, so those read fine and fail on write
          bash = true;
          config = true;
          debug = true;
          mcp = true;
          plugins = true;
        };
        gateway = {
          # reachable from the home lan; the fixed token and this origin list are
          # what a non-loopback bind requires
          bind = "lan";
          controlUi = {
            allowedOrigins = [
              "https://${hostname}.local:${toString gatewayPort}"
              "https://${hostname}:${toString gatewayPort}"
            ];
          };
          # the ios app refuses full access over plaintext lan `ws://` and
          # silently pairs limited, so `operator.admin` is unreachable without
          # this. `autoGenerate` writes a self-signed pair on first start when
          # both files are missing; the phone has to accept that cert once
          tls = {
            enabled = true;
            autoGenerate = true;
            certPath = "${config.programs.openclaw.stateDir}/gateway-tls.crt";
            keyPath = "${config.programs.openclaw.stateDir}/gateway-tls.key";
          };
        };
        memory = {
          search = {
            # threads and dms are separate sessions, so recall across them is the
            # only way the agent carries context between them
            rememberAcrossConversations = true;
          };
        };
        models = {
          # pinning the runtime per model strands `/model`: anything else would
          # fall to the api key route, which this gateway has no key for
          providers = {
            anthropic = {
              agentRuntime = {
                id = "claude-cli";
              };
              # the claude cli only compacts near the 1M window by default;
              # this budget becomes its CLAUDE_CODE_AUTO_COMPACT_WINDOW.
              # both ids are listed because the run resolves either
              models =
                map
                  (id: {
                    inherit id;
                    name = id;
                    contextTokens = 300000;
                  })
                  [
                    "claude-opus-5"
                    "claude-opus-5-5"
                  ];
            };
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
          groupScope = "main";
        };
        tools = {
          # the two agents keep separate workspaces and memories; neither
          # should be able to drive the other
          agentToAgent = {
            enabled = false;
          };
          elevated = {
            enabled = true;
            allowFrom = {
              discord = [
                "\${OPENCLAW_DISCORD_USER_ID}"
              ];
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
