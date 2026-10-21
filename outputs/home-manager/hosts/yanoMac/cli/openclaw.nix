# home openclaw module
{
  agentPackages,
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
  # openclaw 2026.9.5 resolves every relative `.js` import under `dist/` as
  # ESM, and nix-openclaw copies the discord plugin's node_modules in there,
  # so the CJS `discord-api-types/v10.js` fails to load. the hook stands down
  # when NODE_OPTIONS carries an `--import` (openclaw#128663), so import this
  # empty file. drop it once a release ships openclaw#169543, which removes
  # the hook
  esmLoaderShim = pkgs.writeText "openclaw-esm-loader-shim.mjs" "";
  # the cli on PATH, the gateway wrapper, activation and the jobs all exec
  # this one, so each gets the shim. `--prefix` keeps a NODE_OPTIONS of my
  # own and never adds the shim twice; it splits on the separator, hence the
  # single `--import=` token. hiPrio wins `bin/openclaw` over the plain
  # package ai.nix installs
  openclawPackage = lib.hiPrio (
    pkgs.symlinkJoin {
      name = "${pkgs.openclaw.name}-esm-loader-shim";
      paths = [ pkgs.openclaw ];
      nativeBuildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        rm "$out/bin/openclaw"
        makeWrapper ${pkgs.openclaw}/bin/openclaw "$out/bin/openclaw" \
          --prefix NODE_OPTIONS " " "--import=file://${esmLoaderShim}"
      '';
      meta.mainProgram = "openclaw";
    }
  );
  # the agents share my claude config, so they would load every plugin
  # settings.json enables. the ones marked `-openclaw` in
  # configs/agents/plugins.conf run hooks on every session and prompt, which
  # the agents should not get. grok has no such switch, so the list keeps
  # those packages out of grok altogether
  openclawExcludedClaudePlugins = agentPackages.openclawExcluded;
  # the claude on the gateway PATH, with a `--settings` file that turns those
  # plugins off above the user settings. a later `--settings` replaces this
  # one instead of merging with it, and openclaw's own one (on the runs it
  # restricts) already turns every hook off
  openclawClaude = pkgs.symlinkJoin {
    name = "${pkgs.claude-code.name}-openclaw";
    paths = [ pkgs.claude-code ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      rm "$out/bin/claude"
      makeWrapper ${pkgs.claude-code}/bin/claude "$out/bin/claude" \
        --add-flags "--settings ${
          (pkgs.formats.json { }).generate "openclaw-claude-settings.json" {
            enabledPlugins = lib.genAttrs openclawExcludedClaudePlugins (_: false);
          }
        }"
    '';
    meta.mainProgram = "claude";
  };
  launchdLabel = config.programs.openclaw.launchd.label;
  # beside the main workspace in the same repository
  devWorkspaceDir = "${config.home.homeDirectory}/ghq/github.com/${username}/openclaw/workspace-dev";
  # the private details live in the workspace skills AGENTS.md names, so the
  # prompt itself says nothing private. the stock one ends by asking for
  # `NO_REPLY` when nothing needs attention, which those skills contradict.
  # the main session is long-lived, so the prompt makes the agent load the
  # skill again each turn; otherwise it skips check-ins from stale context
  heartbeatPrompt = "Read the SKILL.md of the check-in skill named in AGENTS.md now (it may have changed), read today's thread, and send exactly one check-in with the message tool unless that skill says to stay silent. Then reply exactly NO_REPLY.";
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
  # main and dev each name theirs, so one can move without the other. dev
  # runs the same model as opencode's manager
  devModel = "opencode-go/glm-5.3";
  # explore and worker
  goModel = "opencode-go/claude-haiku-5-5";
  # haiku did not keep main's long japanese persona rules, and qwen answered
  # the intimate roleplay turns with http 400. grok runs on the supergrok
  # login (models.providers.xai), which the grok cli and the feeds share
  mainModel = "xai/grok-4.7";
  # when the supergrok weekly allowance runs out (402) or the login is gone,
  # the same model on go answers instead
  mainFallback = "opencode-go/grok-4.7";
  # the opencode roles (configs/opencode/agents), as agents main and dev spawn
  # across agents: a child of the same agent keeps the parent's tools, so
  # only a separate agent can be read-only. each reads the AGENTS.md in its
  # workspace, which the openclaw repository keeps under helpers/
  readOnly = [
    "write"
    "edit"
    "apply_patch"
    "exec"
    "process"
    "code_execution"
  ];
  helperRoles = {
    explore = {
      name = "read-only research";
      model = goModel;
      deny = readOnly;
    };
    worker = {
      name = "isolated implementation";
      model = goModel;
      deny = [ ];
    };
    smart = {
      name = "hard design and debugging";
      model = "opencode-go/kimi-k3.1-pro";
      deny = [ ];
    };
    # the opencode planner: reads and plans before any edit, never edits
    planner = {
      name = "read-only planning";
      model = "opencode-go/kimi-k3.1-pro";
      deny = readOnly;
    };
    # another family than the manager, so it does not favour its own output
    reviewer = {
      name = "independent read-only review";
      model = "opencode-go/qwen3.8-max";
      deny = readOnly;
    };
    # pay-as-you-go on the service account, behind a fresh discord approval
    # each time (configs/agents/hooks/bridges/openclaw-paid-guard keys on
    # these names)
    paid-opus = {
      name = "pay-as-you-go planning and review";
      model = "opencode-premium/claude-opus-5-5";
      deny = readOnly;
    };
    paid-opus-heavy = {
      name = "pay-as-you-go heavy implementation";
      model = "opencode-premium/claude-opus-5-5";
      deny = [ ];
    };
    paid-fable-architect = {
      name = "pay-as-you-go design decisions";
      model = "opencode-premium/claude-fable-5-1";
      deny = readOnly;
    };
  };
  helperIds = owner: map (role: "${owner}-${role}") (builtins.attrNames helperRoles);
  # each helper may run its own model only, so neither `/model` nor a spawn
  # override moves it
  helpers =
    owner:
    lib.mapAttrs' (
      role: spec:
      lib.nameValuePair "${owner}-${role}" {
        name = "${owner}-${role}: ${spec.name}";
        workspace = "${config.home.homeDirectory}/ghq/github.com/${username}/openclaw/helpers/${owner}-${role}";
        inherit (spec) model;
        modelPolicy = {
          allow = [ spec.model ];
        };
        tools = lib.optionalAttrs (spec.deny != [ ]) { inherit (spec) deny; };
      }
    ) helperRoles;
  # dev stays on go, like opencode's manager, and main falls back to it;
  # fallbacks skip this policy, so main's one fallback stays on go
  goOnly = {
    allow = [ "opencode-go/*" ];
  };
  secretKeys = [
    # a personal console key: it calls models as me, so go's allowance applies
    "OPENCODE_API_KEY"
    # the service account behind the paid helpers, capped in the console
    "OPENCODE_PREMIUM_API_KEY"
    "OPENCLAW_DISCORD_BOT_TOKEN"
    "OPENCLAW_DISCORD_CHANNEL_ID"
    # keeps the channel id out of this public repository
    "OPENCLAW_DISCORD_DEV_CHANNEL_ID"
    "OPENCLAW_DISCORD_USER_ID"
    "OPENCLAW_GATEWAY_TOKEN"
  ];
  secretPath = key: "${config.programs.openclaw.stateDir}/secrets/${key}";
  # closes the daily threads (named yyyymmdd) older than today in the given
  # channels with the bot token. openclaw refuses Discord admin actions from
  # declared automations, so this runs as a plain command job instead.
  # DRY_RUN=1 only lists what it would close
  closeDailyThreads = pkgs.writeShellApplication {
    name = "openclaw-close-daily-threads";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.curl
      pkgs.jq
    ];
    text = ''
      if [ "$#" -lt 2 ]; then
        echo "usage: openclaw-close-daily-threads <token file> <channel id file>..." >&2
        exit 2
      fi
      token=$(cat -- "$1")
      shift
      api=https://discord.com/api/v10
      # discord: discord.com/developers/docs/reference#user-agent
      agent="DiscordBot (https://github.com/yanosea/yanoNixFiles, 1)"
      call() {
        curl -fsS --max-time 30 -H "Authorization: Bot $token" -H "User-Agent: $agent" "$@"
      }
      channels=()
      for file in "$@"; do
        channels+=("$(cat -- "$file")")
      done
      guild=$(call "$api/channels/''${channels[0]}" | jq -er .guild_id)
      today=$(TZ=Asia/Tokyo date +%Y%m%d)
      parents=$(printf '%s\n' "''${channels[@]}" | jq -R . | jq -sc .)
      active=$(call "$api/guilds/$guild/threads/active")
      mapfile -t old < <(jq -r --argjson parents "$parents" --arg today "$today" '
        .threads[]
        | select((.parent_id as $p | $parents | index($p)) and (.name | test("^[0-9]{8}$")) and .name < $today)
        | "\(.id) \(.name)"' <<<"$active")
      failed=0
      for line in "''${old[@]}"; do
        id=''${line%% *}
        if [ -n "''${DRY_RUN:-}" ]; then
          echo "would close $line"
        elif call -X PATCH -H "Content-Type: application/json" -d '{"archived":true}' "$api/channels/$id" | jq -e '.thread_metadata.archived == true' >/dev/null; then
          echo "closed $line"
        else
          echo "failed to close $line" >&2
          failed=1
        fi
        # stay well under discord's per-route rate limit
        sleep 1
      done
      exit "$failed"
    '';
  };
  # the token and channel ids stay in the secret files; only their paths are
  # in the job's argv
  closeThreadsArgv = lib.escapeShellArg (
    builtins.toJSON [
      (lib.getExe closeDailyThreads)
      (secretPath "OPENCLAW_DISCORD_BOT_TOKEN")
      (secretPath "OPENCLAW_DISCORD_CHANNEL_ID")
      (secretPath "OPENCLAW_DISCORD_DEV_CHANNEL_ID")
    ]
  );
  # wakes an agent's main session for its check-in unless the workspace pauses
  # it. the agents' `checkin` skill writes `state/checkin-pause` (an epoch
  # second, or `off`) when asked to stay quiet, so a paused hour starts no
  # model turn at all. a job can wake only the default agent's main session,
  # so the gate sends the system event itself: both agents check in from the
  # session their conversation lives in
  # sends a system event into a session and wakes it now. a job can wake
  # only the default agent's main session, so dev's session-bound turns go
  # through this instead
  wakeSession = pkgs.writeShellApplication {
    name = "openclaw-wake-session";
    text = ''
      if [ "$#" -ne 2 ]; then
        echo "usage: openclaw-wake-session <session key> <text>" >&2
        exit 2
      fi
      export OPENCLAW_CONFIG_PATH="${config.programs.openclaw.stateDir}/openclaw.json"
      export OPENCLAW_STATE_DIR="${config.programs.openclaw.stateDir}"
      export OPENCLAW_NIX_MODE=1
      ${lib.getExe config.programs.openclaw.package} system event --session-key "$1" --mode now --text "$2" </dev/null
    '';
  };
  wakeSessionArgv =
    sessionKey: text:
    lib.escapeShellArg (
      builtins.toJSON [
        (lib.getExe wakeSession)
        sessionKey
        text
      ]
    );
  checkinGate = pkgs.writeShellApplication {
    name = "openclaw-checkin-gate";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.jq
    ];
    text = ''
      if [ "$#" -ne 3 ]; then
        echo "usage: openclaw-checkin-gate <workspace> <session key> <prompt>" >&2
        exit 2
      fi
      pause="$1/state/checkin-pause"
      if [ -f "$pause" ]; then
        until=$(head -n 1 -- "$pause")
        if [ "$until" = off ] || { [[ $until =~ ^[0-9]+$ ]] && [ "$(date +%s)" -lt "$until" ]; }; then
          echo "paused until $(sed -n 2p "$pause")"
          exit 0
        fi
        # the pause is over (or unreadable); the hour runs as usual
        rm -f -- "$pause"
      fi
      exec ${lib.getExe wakeSession} "$2" "$3"
    '';
  };
  checkinGateArgv =
    workspace: sessionKey:
    lib.escapeShellArg (
      builtins.toJSON [
        (lib.getExe checkinGate)
        workspace
        sessionKey
        heartbeatPrompt
      ]
    );
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
          # a minute after the new threads open, close the older daily ones
          if ! $DRY_RUN_CMD openclaw automations add \
            --name close-daily-threads \
            --display-name "Close daily threads" \
            --declaration-key workspace:close-daily-threads \
            --agent main \
            --cron "1 0 * * *" --tz Asia/Tokyo --exact \
            --no-deliver \
            --timeout-seconds 300 \
            --command-argv ${closeThreadsArgv}; then
            echo "failed to declare the close-daily-threads automation" >&2
          fi
          # the hourly check-in: `checkin-gate` wakes main's session on the hour
          # unless mizuki has paused the check-ins (dev-checkin-gate below does
          # the same for dev). 7 and 19 belong to `trends`, the 0:00 one comes
          # from the daily-thread skill once the thread is up, and none from 1
          # to 5. `checkin` and `dev-checkin` were the jobs the gates used to
          # run, and `dev-daily-thread` ran dev's 0:00 turn in a fresh session;
          # the sessions are woken directly now, so drop them
          for job in checkin dev-checkin dev-daily-thread; do
            for id in $(${lib.getExe config.programs.openclaw.package} cron list --all --json </dev/null 2>/dev/null \
              | ${lib.getExe pkgs.jq} -r --arg name "$job" '(.jobs // .)[] | select(.name == $name) | .id'); do
              if ! $DRY_RUN_CMD openclaw cron rm "$id"; then
                echo "failed to remove the $job automation" >&2
              fi
            done
          done
          if ! $DRY_RUN_CMD openclaw automations add \
            --name checkin-gate \
            --display-name "Check-in gate" \
            --declaration-key workspace:checkin-gate \
            --agent main \
            --cron "0 6,8-18,20-23 * * *" --tz Asia/Tokyo --exact \
            --no-deliver \
            --timeout-seconds 60 \
            --command-argv ${checkinGateArgv config.programs.openclaw.workspaceDir "agent:main:main"}; then
            echo "failed to declare the checkin-gate automation" >&2
          fi
          # main's feeds reached mizuki only through the check-ins, so they went
          # quiet with them; like dev-trends, an isolated turn posts them to
          # today's thread at 7 and 19 whether or not the check-ins are paused
          mainChannel="${secretPath "OPENCLAW_DISCORD_CHANNEL_ID"}"
          if [ ! -s "$mainChannel" ]; then
            echo "missing $mainChannel; skipped declaring the trends automation" >&2
          elif ! $DRY_RUN_CMD openclaw automations add \
            --name trends \
            --display-name "Trends" \
            --declaration-key workspace:trends \
            --agent main \
            --cron "0 7,19 * * *" --tz Asia/Tokyo --exact \
            --session isolated \
            --no-deliver --channel discord \
            --to "channel:$(${pkgs.coreutils}/bin/cat "$mainChannel")" \
            --message "Use the onee-trends skill."; then
            echo "failed to declare the trends automation" >&2
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
          # the dev jobs post with the message tool into today's thread, so
          # nothing is delivered from the final reply. `--to` stays because
          # it is what gives the run its current channel; an empty id would
          # leave the run with no channel to post in. the half-hour lead on
          # dev-trends leaves dev-feeds time to refresh the file it reads
          if [ ! -s "$devChannel" ]; then
            echo "missing $devChannel; skipped declaring the dev jobs" >&2
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
            # like main's daily-thread, dev's 0:00 turn runs in the session its
            # conversation lives in, woken directly
            if ! $DRY_RUN_CMD openclaw automations add \
              --name dev-daily-thread-wake \
              --display-name "Dev daily thread" \
              --declaration-key workspace-dev:daily-thread-wake \
              --agent dev \
              --cron "0 0 * * *" --tz Asia/Tokyo --exact \
              --no-deliver \
              --timeout-seconds 60 \
              --command-argv ${wakeSessionArgv "agent:dev:main" "Use the daily-thread skill."}; then
              echo "failed to declare the dev-daily-thread-wake automation" >&2
            fi
            # dev's hourly check-in, woken in dev's own session by the gate.
            # 7 and 19 belong to dev-trends, 0 is the daily-thread skill's, and
            # none from 1 to 5
            if ! $DRY_RUN_CMD openclaw automations add \
              --name dev-checkin-gate \
              --display-name "Dev check-in gate" \
              --declaration-key workspace-dev:checkin-gate \
              --agent dev \
              --cron "0 6,8-18,20-23 * * *" --tz Asia/Tokyo --exact \
              --no-deliver \
              --timeout-seconds 60 \
              --command-argv ${checkinGateArgv devWorkspaceDir "agent:dev:main"}; then
              echo "failed to declare the dev-checkin-gate automation" >&2
            fi
            # the updater opens the flake.lock pr around 5:00 and darwin takes
            # up to two hours, so by 7:00 the run has settled either way
            if ! $DRY_RUN_CMD openclaw automations add \
              --name dev-triage-update-pr \
              --display-name "Dev triage update PR" \
              --declaration-key workspace-dev:triage-update-pr \
              --agent dev \
              --cron "0 7 * * *" --tz Asia/Tokyo --exact \
              --session isolated \
              --no-deliver --channel discord \
              --to "channel:$(${pkgs.coreutils}/bin/cat "$devChannel")" \
              --message "Use the triage-update-pr skill."; then
              echo "failed to declare the dev-triage-update-pr automation" >&2
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
      package = openclawPackage;
      # the mac app ships as a bundle of ~80k files, and upstream places it
      # through `home.file` with `recursive = true`, so every rebuild relinked
      # all of them one at a time — 99% of this generation's links and most of
      # `make home`'s wall clock. nothing here uses the gui; the gateway runs
      # under launchd, which this does not touch
      installApp = false;
      # sessions, sqlite and logs; the generated config sits here too
      stateDir = "${config.xdg.stateHome}/openclaw";
      # keeps the persona files out of this public repo; `bootstrapFiles` stays
      # unset because it would rewrite them on every activation. activation
      # mkdirs this, so put the repository here before the first switch
      workspaceDir = "${config.home.homeDirectory}/ghq/github.com/${username}/openclaw/workspace";
      # the generated wrapper cats a value that names a file, unless the key
      # ends in _FILE; openclaw itself would take the path as the secret
      environment = {
        OPENCODE_API_KEY = secretPath "OPENCODE_API_KEY";
        OPENCODE_PREMIUM_API_KEY = secretPath "OPENCODE_PREMIUM_API_KEY";
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
        # the agents ask grok about x; it signs in from here, and my grok hooks
        # skip when this is set instead of editing the dotfiles repository
        GROK_HOME = "${config.xdg.configHome}/grok";
        OPENCLAW_FEEDS = "1";
        # the common hooks need python 3.11 or later, and openclaw puts
        # /usr/bin first in PATH. a directory, because the wrapper would cat a
        # file path into the value
        COMMON_HOOK_PYTHON_DIR = "${pkgs.python3}/bin";
      };
      # the subscription route delegates to the claude cli. gpg lets the dev
      # agent sign its commits as me: branch protection rejects unsigned ones.
      # openclaw-feeds is there for an agent to refresh its feeds by hand. gh
      # is for the dev agent's PR and CI checks: job turns get only this path
      runtimePackages = [
        openclawFeeds
        openclawClaude
        pkgs.gh
        pkgs.gnupg
        # the graphify skill calls its cli
        pkgs.graphify
        pkgs.grok-build
        # yomiyasu's linter
        pkgs.python3
        # go-limits: opencode go usage before heavy work (the turns do not see ~/.local/bin)
        (pkgs.writeShellScriptBin "go-limits" ''
          exec ${pkgs.python3}/bin/python3 "$HOME/.agents/go-limits/go_limits.py" "$@"
        '')
      ];
      config = {
        agents = {
          defaults = {
            # the check-ins go out through the message tool into the day's
            # thread, so nothing from the turn itself is delivered: a preamble
            # the model writes before its tools would otherwise land in the
            # channel as is
            # no interval of its own: its minute is a hash of the device and
            # agent ids, so the `checkin` job wakes main's on the hour instead,
            # from 6 to 23 (a cron wake skips `activeHours`); dev's check-in is
            # an isolated `dev-checkin` job
            heartbeat = {
              every = "0m";
              target = "none";
            };
            model = {
              primary = devModel;
            };
            modelPolicy = goOnly;
            # children are leaves, like opencode's subagents; a run has no
            # time limit by default
            subagents = {
              maxSpawnDepth = 1;
              maxConcurrent = 2;
              maxChildrenPerAgent = 3;
              runTimeoutSeconds = 900;
            };
          };
          # once any entry carries a heartbeat block, only the entries that
          # carry one run heartbeats, so main needs its own as well. the
          # helpers carry none and no binding, so neither cron nor discord
          # reaches them
          entries = {
            main = {
              default = true;
              workspace = config.programs.openclaw.workspaceDir;
              # a string model is strict; only the object form takes
              # fallbacks, which skip modelPolicy
              model = {
                primary = mainModel;
                fallbacks = [ mainFallback ];
              };
              # go plus this one grok, so `/model` cannot reach other xai rows
              modelPolicy = {
                allow = goOnly.allow ++ [ mainModel ];
              };
              # the xai login also turns these on, and they call api.x.ai,
              # the separately billed console, rather than the supergrok proxy.
              # web_search stays: tools.web.search pins it to parallel-free
              tools = {
                deny = [
                  "x_search"
                  "code_execution"
                ];
              };
              heartbeat = {
                prompt = heartbeatPrompt;
              };
              # requireAgentId keeps it from spawning copies of itself
              subagents = {
                allowAgents = helperIds "main";
                requireAgentId = true;
              };
            };
            dev = {
              workspace = devWorkspaceDir;
              model = devModel;
              modelPolicy = goOnly;
              heartbeat = {
                prompt = heartbeatPrompt;
              };
              subagents = {
                allowAgents = helperIds "dev";
                requireAgentId = true;
              };
            };
          }
          // helpers "main"
          // helpers "dev";
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
            # unset means openai embeddings, which this gateway has no key for:
            # every sync aborted. keyword search needs nothing, and trigram
            # lets it match japanese, which has no spaces to split on
            provider = "none";
            store = {
              fts = {
                tokenizer = "trigram";
              };
            };
          };
        };
        models = {
          providers = {
            # the bundled opencode-go provider (OPENCODE_API_KEY) has no haiku
            # in its catalog, so the row is declared here. haiku speaks
            # anthropic messages, so the row carries its own api and url
            # rather than the provider's, which the bundled openai-compatible
            # models keep. the url is the bundled one: go rejects a request
            # without x-opencode-session, which openclaw sends only there
            opencode-go = {
              models = [
                {
                  id = "claude-haiku-5-5";
                  name = "Claude Haiku 5.5";
                  api = "anthropic-messages";
                  baseUrl = "https://opencode.ai/zen/go";
                  # 2026.9.5 predates haiku 5.5 and asks for budget thinking,
                  # which it rejects; 2026.10.4 knows its adaptive thinking
                  reasoning = false;
                  input = [
                    "text"
                    "image"
                  ];
                  contextWindow = 1000000;
                  # past 100K tokens the price is five times higher, so the
                  # sessions compact before that
                  contextTokens = 100000;
                  maxTokens = 128000;
                  cost = {
                    input = 0.1;
                    output = 0.5;
                    cacheRead = 0.01;
                    cacheWrite = 0.125;
                  };
                }
                # main's fallback, the row openclaw projects from
                # models.opencode.ai: go serves grok on the responses api.
                # openclaw sends no x-opencode-session to this url, and go
                # answered those requests without it. on that same route the
                # catalog's compat wins over this one, so it repeats the
                # catalog's for when the catalog is offline
                {
                  id = "grok-4.7";
                  name = "Grok 4.7";
                  api = "openai-responses";
                  baseUrl = "https://opencode.ai/inference/go/openai/v1";
                  reasoning = true;
                  input = [
                    "text"
                    "image"
                  ];
                  contextWindow = 500000;
                  # past 200K tokens the price doubles, so the sessions compact
                  # before that
                  contextTokens = 200000;
                  maxTokens = 500000;
                  compat = {
                    supportsUsageInStreaming = true;
                    maxTokensField = "max_tokens";
                    supportsTools = true;
                    # grok cannot turn reasoning off
                    supportsReasoningEffort = true;
                    supportedReasoningEfforts = [
                      "low"
                      "medium"
                      "high"
                      "xhigh"
                    ];
                  };
                  cost = {
                    input = 2;
                    output = 6;
                    cacheRead = 0.5;
                    cacheWrite = 0;
                  };
                }
              ];
            };
            # what `openclaw models auth login --provider xai --method oauth`
            # would write here if this file were not nix-managed: the
            # supergrok route rather than the console api (api.x.ai). the
            # sign-in sits in main's own auth store; openclaw does not read
            # the grok cli's. the bundled catalog stops at 4.6
            xai = {
              baseUrl = "https://cli-chat-proxy.grok.com/v1";
              api = "openai-responses";
              auth = "oauth";
              models = [
                {
                  id = "grok-4.7";
                  name = "Grok 4.7";
                  reasoning = true;
                  input = [
                    "text"
                    "image"
                  ];
                  # the window the grok cli's catalog lists for this route
                  contextWindow = 256000;
                  maxTokens = 64000;
                  # list prices, the same as go's row; the turns draw on the
                  # weekly allowance the feeds share
                  cost = {
                    input = 2;
                    output = 6;
                    cacheRead = 0.5;
                    cacheWrite = 0;
                  };
                }
              ];
            };
            # console pay-as-you-go on the service-account key, the same route
            # as opencode's premium provider; only the paid helpers may run it
            opencode-premium = {
              api = "anthropic-messages";
              baseUrl = "https://opencode.ai/inference/anthropic";
              apiKey = {
                source = "env";
                provider = "default";
                id = "OPENCODE_PREMIUM_API_KEY";
              };
              # openclaw adds this header only for its bundled opencode urls
              headers = {
                x-opencode-session = "openclaw-premium";
              };
              models = [
                {
                  id = "claude-opus-5-5";
                  name = "Claude Opus 5.5";
                  reasoning = true;
                  input = [
                    "text"
                    "image"
                  ];
                  # the console rejects a request without max_tokens or above
                  # the model's 128k
                  contextWindow = 1000000;
                  maxTokens = 128000;
                  # strict tools need additionalProperties = false on every
                  # object, which not all of openclaw's schemas carry, and the
                  # console rejects the request then; the bundled go rows turn
                  # it off too
                  compat = {
                    supportsStrictMode = false;
                  };
                  cost = {
                    input = 4;
                    output = 20;
                  };
                }
                {
                  id = "claude-fable-5-1";
                  name = "Claude Fable 5.1";
                  reasoning = true;
                  input = [
                    "text"
                    "image"
                  ];
                  contextWindow = 1000000;
                  maxTokens = 128000;
                  compat = {
                    supportsStrictMode = false;
                  };
                  cost = {
                    input = 10;
                    output = 50;
                  };
                }
              ];
            };
          };
        };
        plugins = {
          # Use the complete source directory: per-file Home Manager symlinks
          # escape the plugin root and fail OpenClaw's path-safety validation.
          load.paths = [
            "${../../../../../configs/agents/hooks/bridges/openclaw}"
            "${../../../../../configs/agents/hooks/bridges/openclaw-paid-guard}"
            # the external parallel plugin, for the key-free web search.
            # `programs.openclaw.runtimePlugins` refuses to sit beside the raw
            # paths above, so its package goes in here directly
            "${pkgs.openclawRuntimePlugins.parallel}"
          ];
          # bundled but off until named here
          entries = {
            "common-hooks" = {
              enabled = true;
              hooks = {
                allowConversationAccess = true;
              };
            };
            "paid-guard" = {
              enabled = true;
            };
            # carries parallel-free, which needs no key; no apiKey here, so
            # its paid `parallel` provider stays unusable
            "parallel" = {
              enabled = true;
            };
            # the zen provider would bill the personal key without an
            # approval; go and the service account keep their own providers
            "opencode" = {
              enabled = false;
            };
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
        # a custom stateDir excludes home skill roots. use the shared source
        # directly: home-manager's per-file symlinks escape the skill root.
        skills.load.extraDirs = [
          "${../../../../../configs/agents/skills}"
          "${inputs.yomiyasu}/skills"
        ];
        tools = {
          # the two agents keep separate workspaces and memories; neither
          # should be able to drive the other
          agentToAgent = {
            enabled = false;
          };
          # parallel's free search mcp, no key and no bill. a key-free
          # provider never wins auto-detection, so it has to be named, and a
          # named one gets no fallback: a failed search fails rather than
          # moving on. the pin also keeps the xai login (or a key added
          # later) from routing searches to a billed provider such as grok
          web = {
            search = {
              enabled = true;
              provider = "parallel-free";
            };
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
            # brings paid-guard's approvals to discord as buttons, in the
            # channel the request came from rather than a dm; the approvers
            # are commands.ownerAllowFrom
            execApprovals = {
              enabled = true;
              target = "channel";
            };
            # with streaming off, text the model writes between tool calls ends
            # up in the reply. progress mode files it as the headline of a
            # temporary status message, deleted once the reply lands. no
            # narration: its filler costs extra model calls. no label: the
            # default is an english "Working" while the turn runs
            streaming = {
              mode = "progress";
              progress = {
                label = false;
                narration = false;
              };
            };
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
