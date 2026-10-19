# configs (dotfiles)
{
  aiModels,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  hookPython = pkgs.python3.withPackages (pythonPackages: [ pythonPackages.tomlkit ]);
  # regular config files (excluding directories with custom deployment below)
  contents = builtins.readDir ./.;
  filteredContents = lib.filterAttrs (
    name: _:
    name != "default.nix"
    && name != "agents"
    && name != "antigravity"
    && name != "copilot"
    && name != "kiro"
    && name != "codex"
    && name != "grok"
    && name != "zsh"
  ) contents;
  mkEntry = name: type: {
    inherit name;
    value = {
      source = ./. + "/${name}";
      recursive = type == "directory";
    };
  };
  configFiles = lib.mapAttrs' mkEntry filteredContents;
  quickshellOverride = {
    "quickshell" = configFiles."quickshell" // {
      force = true;
    };
  };
  # settings.json is generated below rather than copied, so keep it out of the
  # recursive link: home-manager resolves an overlap between a recursively
  # linked directory and a single file by silently dropping the single file
  claudeOverride = {
    "claude" = configFiles."claude" // {
      source = lib.fileset.toSource {
        root = ./claude;
        fileset = lib.fileset.difference ./claude ./claude/settings.json;
      };
    };
  };
  # opencode skips a plugin directory whose files are symlinks, so console-budget
  # leaves the recursive link and is linked whole in opencodeConfigEntries
  opencodeOverride = {
    "opencode" = configFiles."opencode" // {
      source = lib.fileset.toSource {
        root = ./opencode;
        fileset = lib.fileset.difference ./opencode ./opencode/plugins/console-budget;
      };
    };
  };
  # hypr config files with custom onChange hook for hyprland.conf
  hyprConfigEntries = {
    "hypr/hyprland.conf" = {
      source = ./hypr/hyprland.conf;
      onChange = ''
        XDG_RUNTIME_DIR=''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}
        if [[ -d "/tmp/hypr" || -d "$XDG_RUNTIME_DIR/hypr" ]]; then
          # Check if hyprctl actually returns valid JSON before piping to jq
          INSTANCES=$(hyprctl instances -j 2>/dev/null || echo "[]")
          # Only proceed if we have valid JSON array
          if echo "$INSTANCES" | jq empty 2>/dev/null; then
            for i in $(echo "$INSTANCES" | jq ".[].instance" -r 2>/dev/null); do
              hyprctl -i "$i" reload config-only 2>/dev/null || true
            done
          fi
        fi
      '';
    };
    "hypr/hypridle.conf".source = ./hypr/hypridle.conf;
    "hypr/hyprpaper.conf".source = ./hypr/hyprpaper.conf;
  };
  # plugins.conf and plugin-marketplaces.conf, enabled at user scope: a
  # plugin enabled per directory is missing from the first session in every
  # new one, while claude fetches what user settings enable on its own
  claudeConfLines =
    file:
    lib.filter (line: builtins.match "[[:space:]]*(#.*)?" line == null) (
      lib.splitString "\n" (builtins.readFile file)
    );
  claudeMarketplaceRows = map (line: lib.filter (word: word != "") (lib.splitString " " line)) (
    claudeConfLines ./claude/plugin-marketplaces.conf
  );
  claudeMarketplaceOf =
    plugin:
    let
      row = lib.findFirst (row: builtins.head row == plugin) null claudeMarketplaceRows;
    in
    if row == null then "claude-plugins-official" else builtins.elemAt row 1;
  claudeDeclaredPlugins = lib.concatMap (
    line:
    let
      match = builtins.match "[[]x[]] +([^ ]+).*" line;
    in
    lib.optional (match != null) (builtins.head match)
  ) (claudeConfLines ./claude/plugins.conf);
  claudePluginSettings = {
    enabledPlugins = builtins.listToAttrs (
      map (plugin: {
        name = "${plugin}@${claudeMarketplaceOf plugin}";
        value = true;
      }) claudeDeclaredPlugins
    );
    extraKnownMarketplaces = builtins.listToAttrs (
      map (row: {
        name = builtins.elemAt row 1;
        value.source = {
          source = "github";
          repo = builtins.elemAt row 2;
        };
      }) claudeMarketplaceRows
    );
  };
  # graphify ships one SKILL.md per cli, each with its own references/; the
  # `.graphify_version` stamp is left out on purpose, since graphify rewrites
  # stamped copies in place after an upgrade and a store path cannot take that
  graphifySkill =
    variant: skillFile:
    pkgs.runCommand "graphify-skill-${variant}" { } ''
      package=$(find ${pkgs.graphify}/lib -type d -path '*/site-packages/graphify' | head -n 1)
      mkdir -p $out
      cp "$package/${skillFile}" $out/SKILL.md
      cp -r "$package/skills/${variant}/references" $out/references
    '';
  # skills from other repositories that ship no plugin for these clis
  imozuruSkill = "${inputs.imozuru}/skills/imozuru";
  reaSkill = "${inputs.rea}/.agents/skills/reverse-engineer-anything";
  # claude user memory (the rest of configs/claude is deployed by the generic loop)
  claudeConfigEntries = {
    "claude/CLAUDE.md".source = ./agents/global-rules.md;
    "claude/commands/handover.md".source = ./agents/skills/handover/SKILL.md;
    "claude/commands/sg.md".source = ./agents/skills/sg/SKILL.md;
    "claude/commands/sj.md".source = ./agents/skills/sj/SKILL.md;
    "claude/skills/agent-loop" = {
      source = ./agents/skills/agent-loop;
      recursive = true;
    };
    "claude/skills/triage-update-pr" = {
      source = ./agents/skills/triage-update-pr;
      recursive = true;
    };
    "claude/skills/graphify".source = graphifySkill "claude" "skill.md";
    "claude/skills/imozuru".source = imozuruSkill;
    "claude/skills/reverse-engineer-anything".source = reaSkill;
    # the model ids come from lib/ai-models.nix so one tier list drives the
    # `opusplan` slots, the subagent pin and openclaw's primary. `opus` is the
    # plan-mode slot and `sonnet` the execution one, whatever they resolve to
    "claude/settings.json".source = (pkgs.formats.json { }).generate "claude-settings.json" (
      lib.recursiveUpdate (builtins.fromJSON (builtins.readFile ./claude/settings.json)) {
        inherit (claudePluginSettings) enabledPlugins extraKnownMarketplaces;
        env = {
          ANTHROPIC_DEFAULT_OPUS_MODEL = aiModels.plan;
          ANTHROPIC_DEFAULT_SONNET_MODEL = aiModels.run;
          CLAUDE_CODE_SUBAGENT_MODEL = aiModels.run;
        };
      }
    );
  };
  # the skill that lets claude search its own history through claude-history
  claudeHistorySkill = lib.optionalAttrs (pkgs ? claude-history) {
    "claude/skills/claude-history".source =
      "${pkgs.claude-history}/share/claude-history/skills/claude-history";
  };
  # codex config files (config.toml is deployed by an activation copy instead,
  # since codex writes hook-trust and project-trust state back into it)
  codexConfigEntries = {
    "codex/AGENTS.md".source = ./agents/global-rules.md;
    "codex/plugins.conf".source = ./codex/plugins.conf;
    "codex/hooks" = {
      source = ./codex/hooks;
      recursive = true;
    };
    "codex/themes" = {
      source = ./codex/themes;
      recursive = true;
    };
  };
  # grok config files (config.toml is deployed by an activation copy instead)
  # grok reads AGENTS.md from GROK_HOME (INSTRUCTION_FILENAMES)
  grokConfigEntries = {
    "grok/AGENTS.md".source = ./agents/global-rules.md;
    "grok/plugins.conf".source = ./grok/plugins.conf;
    "grok/hooks" = {
      source = ./grok/hooks;
      recursive = true;
    };
  };
  # opencode user rules (the rest of configs/opencode is deployed by the generic loop,
  # since opencode never rewrites its config)
  opencodeConfigEntries = {
    "opencode/AGENTS.md".source = ./agents/global-rules.md;
    "opencode/plugins/common-hooks.ts".source = ./agents/hooks/bridges/opencode.ts;
    "opencode/plugins/console-budget".source = ./opencode/plugins/console-budget;
  };
  # config.local.toml goes first so its top-level keys precede every table,
  # which keeps unpublishable settings out of this repository
  copyWritableConfig = dir: src: ''
    configDir="''${XDG_CONFIG_HOME:-$HOME/.config}/${dir}"
    $DRY_RUN_CMD mkdir -p "$configDir"
    if [ -z "''${DRY_RUN_CMD:-}" ] && [ -z "''${DRY_RUN:-}" ]; then
      ${hookPython}/bin/python3 ${./agents/hooks/wiring.py} merge-toml \
        --base ${src} --destination "$configDir/config.toml" \
        --local "$configDir/config.local.toml"
    fi
  '';
  # zsh config subdirectories (excluding .zshrc/.zshenv which are managed by programs.zsh)
  zshContents = builtins.readDir ./zsh;
  zshConfigEntries = lib.mapAttrs' (name: type: {
    name = "zsh/${name}";
    value = {
      source = ./zsh + "/${name}";
      recursive = type == "directory";
    };
  }) zshContents;
  # Codex discovers directory symlinks, but skips symlinked SKILL.md files.
  sharedSkillEntries =
    lib.mapAttrs'
      (name: _: {
        name = ".agents/skills/${name}";
        value = {
          source = ./agents/skills + "/${name}";
          recursive = false;
        };
      })
      (
        lib.filterAttrs (
          name: type:
          type == "directory"
          && name != "yomiyasu"
          && builtins.pathExists (./agents/skills + "/${name}/SKILL.md")
        ) (builtins.readDir ./agents/skills)
      );
in
{
  # home directory files
  home = {
    activation = {
      # Preserve the old per-file layout before checking whole-directory links.
      migrateSharedAgentSkills = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
        if [ -n "''${oldGenPath:-}" ]; then
          oldSkillFiles=$(${pkgs.coreutils}/bin/readlink -e "$oldGenPath/home-files")
          skillBackupRoot="$HOME/.agents/skill-migration-backups/''${newGenPath##*/}"
          declare -a skillMigrationSources=() skillMigrationBackups=()
          for skillName in ${
            lib.escapeShellArgs (
              map (name: lib.removePrefix ".agents/skills/" name) (builtins.attrNames sharedSkillEntries)
            )
          }; do
            skillDirectory="$HOME/.agents/skills/$skillName"
            if [ -d "$skillDirectory" ] && [ ! -L "$skillDirectory" ] && [ -L "$skillDirectory/SKILL.md" ]; then
              skillLink=$(${pkgs.coreutils}/bin/readlink "$skillDirectory/SKILL.md")
              if [ "$skillLink" = "$oldSkillFiles/.agents/skills/$skillName/SKILL.md" ]; then
                skillBackup="$skillBackupRoot/$skillName"
                if [ -e "$skillBackup" ] || [ -L "$skillBackup" ]; then
                  errorEcho "Cannot migrate shared skill: backup already exists at $skillBackup"
                  exit 1
                fi
                skillMigrationSources+=("$skillDirectory")
                skillMigrationBackups+=("$skillBackup")
              fi
            fi
          done
          # Every destination has passed preflight before any directory moves.
          if [ "''${#skillMigrationSources[@]}" -gt 0 ]; then
            run ${pkgs.coreutils}/bin/mkdir -p "$skillBackupRoot"
            for skillIndex in "''${!skillMigrationSources[@]}"; do
              run ${pkgs.coreutils}/bin/mv -T --no-clobber \
                "''${skillMigrationSources[$skillIndex]}" "''${skillMigrationBackups[$skillIndex]}"
            done
          fi
        fi
      '';
      # Seed a writable user policy once. Subsequent user choices, including
      # an invalid policy reported by the hook runtime, are never overwritten.
      seedCommonAgentPolicy = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        policy="''${XDG_CONFIG_HOME:-$HOME/.config}/agents/hooks-policy.json"
        if [ -z "''${DRY_RUN_CMD:-}" ] && [ -z "''${DRY_RUN:-}" ] && [ ! -e "$policy" ] && [ ! -L "$policy" ]; then
          mkdir -p "$(dirname "$policy")"
          ${pkgs.coreutils}/bin/install -m 600 ${./agents/hooks-policy.json} "$policy"
        fi
      '';
      # The named Antigravity definition and Copilot user hook file are merged,
      # retaining deliberate disabling and unrelated hooks. Kiro 2.x profiles
      # receive hooks without changing the selected agent or tool permissions.
      wireCommonAgentHooks = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        if [ -z "''${DRY_RUN_CMD:-}" ] && [ -z "''${DRY_RUN:-}" ]; then
          ${pkgs.python3}/bin/python3 ${./agents/hooks/wiring.py} global \
            --templates ${
              lib.fileset.toSource {
                root = ./.;
                fileset = lib.fileset.unions [
                  ./antigravity/hooks.json
                  ./copilot/hooks/common-agents.json
                  ./kiro/common-hooks.json
                ];
              }
            }
        fi
      '';
      # copied rather than symlinked: codex appends [hooks.state] and
      # [projects.*] to config.toml and cannot write to a store path
      copyCodexConfig = lib.hm.dag.entryAfter [ "linkGeneration" ] (
        copyWritableConfig "codex" ./codex/config.toml
      );
      # copied rather than symlinked: grok writes back to config.toml
      # merged rather than replaced: agy keeps trustedWorkspaces in the same file
      mergeAntigravitySettings = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        settings="$HOME/.gemini/antigravity-cli/settings.json"
        $DRY_RUN_CMD mkdir -p "$(dirname "$settings")"
        if [ -f "$settings" ]; then
          $DRY_RUN_CMD ${pkgs.jq}/bin/jq -s '.[0] * .[1]' "$settings" ${./antigravity/settings.json} >"$settings.tmp"
          $DRY_RUN_CMD mv "$settings.tmp" "$settings"
        else
          $DRY_RUN_CMD cat ${./antigravity/settings.json} >"$settings"
        fi
      '';
      copyGrokConfig = lib.hm.dag.entryAfter [ "linkGeneration" ] (
        copyWritableConfig "grok" ./grok/config.toml
        + ''
          $DRY_RUN_CMD cat ${./grok/pager.toml} >"$configDir/pager.toml"
        ''
      );
    };
    file = {
      # codex skills live outside XDG, in the cross-tool ~/.agents/skills
      ".agents" = {
        source = lib.fileset.toSource {
          root = ./agents;
          fileset =
            lib.fileset.difference (lib.fileset.fileFilter (file: !(lib.hasSuffix ".pyc" file.name)) ./agents)
              (
                lib.fileset.unions [
                  ./agents/global-rules.md
                  ./agents/hooks/tests
                  ./agents/skills
                ]
              );
        };
        recursive = true;
      };
      # yomiyasu comes from its flake input; codex and opencode read it here
      ".agents/skills/yomiyasu".source = "${inputs.yomiyasu}/skills/yomiyasu";
      ".agents/skills/graphify".source = graphifySkill "agents" "skill-agents.md";
      ".agents/skills/imozuru".source = imozuruSkill;
      ".agents/skills/reverse-engineer-anything".source = reaSkill;
      # antigravity ignores XDG (settings.json and mcp_config.json are agy-managed)
      ".gemini/config/AGENTS.md".source = ./agents/global-rules.md;
      # kiro always includes AGENTS.md from its global steering directory
      ".kiro/steering/AGENTS.md".source = ./agents/global-rules.md;
      # copilot cli reads its user instructions from ~/.copilot
      ".copilot/copilot-instructions.md".source = ./agents/global-rules.md;
      ".gemini/config/skills" = {
        source = ./agents/skills;
        recursive = true;
      };
      # graphify installs claude's variant for antigravity too
      ".gemini/config/skills/graphify".source = graphifySkill "claude" "skill.md";
      ".gemini/config/skills/imozuru".source = imozuruSkill;
      ".gemini/config/skills/reverse-engineer-anything".source = reaSkill;
      # kiro loads every skill under ~/.kiro/skills; rea stays out, since its
      # skill drives the rea mcp server and kiro's mcp config is not managed here
      ".kiro/skills/graphify".source = graphifySkill "kiro" "skill-kiro.md";
      ".kiro/skills/imozuru".source = imozuruSkill;
      ".gemini/config/scripts" = {
        source = ./antigravity/scripts;
        recursive = true;
      };
      ".gemini/config/plugins.conf".source = ./antigravity/plugins.conf;
      ".local/bin/agent-loop" = {
        executable = true;
        text = ''
          #!${pkgs.runtimeShell}
          exec ${pkgs.python3}/bin/python3 "$HOME/.agents/hooks/agent_loop.py" "$@"
        '';
      };
      ".local/bin/niri-app-toggle" = {
        executable = true;
        text = ''
          #!/usr/bin/env bash
          APP_ID="$1"
          shift
          WINDOWS=$(niri msg -j windows 2>/dev/null)
          UNFOCUSED_ID=$(printf '%s' "$WINDOWS" | jq -r --arg a "$APP_ID" \
            'first(.[] | select(.app_id == $a and .is_focused == false) | .id) // empty')
          if [ -n "$UNFOCUSED_ID" ]; then
            niri msg action focus-window --id "$UNFOCUSED_ID"
          elif ! printf '%s' "$WINDOWS" | jq -e --arg a "$APP_ID" 'any(.[]; .app_id == $a)' >/dev/null 2>&1; then
            exec "$@"
          fi
        '';
      };
    }
    // sharedSkillEntries;
  };
  # xdg
  xdg = {
    configFile =
      configFiles
      // quickshellOverride
      // claudeOverride
      // opencodeOverride
      // claudeConfigEntries
      // claudeHistorySkill
      // codexConfigEntries
      // grokConfigEntries
      // opencodeConfigEntries
      // hyprConfigEntries
      // zshConfigEntries;
  };
}
