# configs (dotfiles)
{
  agentPackages,
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
  # settings.json and the plugin lists are generated below rather than copied,
  # so keep them out of the recursive link: home-manager resolves an overlap
  # between a recursively linked directory and a single file by silently
  # dropping the single file
  claudeOverride = {
    "claude" = configFiles."claude" // {
      source = lib.fileset.toSource {
        root = ./claude;
        fileset = lib.fileset.difference ./claude (
          lib.fileset.unions [
            ./claude/plugin-marketplaces.conf
            ./claude/plugins.conf
            ./claude/settings.json
          ]
        );
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
  # a per-cli plugin catalog with the packages of configs/agents/plugins.conf
  # it gets appended as `[x]` lines, ids padded to width so the comments line
  # up. a catalog line for one of them is dropped, so the shared list decides
  withSharedPlugins =
    file: width: ids:
    let
      shared =
        line:
        let
          match = builtins.match "[[][ x][]] +([^ ]+).*" line;
        in
        match != null && lib.elem (builtins.head match) ids;
      pad = id: id + lib.concatStrings (lib.genList (_: " ") (lib.max 1 (width - lib.stringLength id)));
    in
    lib.concatStringsSep "\n" (
      lib.filter (line: !shared line) (lib.splitString "\n" (builtins.readFile file))
    )
    + lib.optionalString (ids != [ ]) (
      "\n# shared with the other clis, declared in configs/agents/plugins.conf\n"
      + lib.concatMapStrings (id: "[x] ${pad id}# shared\n") ids
    );
  # the shared packages claude installs, as plugin-marketplaces.conf rows
  claudeMarketplacesConf =
    builtins.readFile ./claude/plugin-marketplaces.conf
    + "\n# shared with the other clis, declared in configs/agents/plugins.conf\n"
    + lib.concatMapStrings (package: "${package.name} ${package.marketplace} ${package.repository}\n") (
      agentPackages.for "claude"
    );
  claudePluginsConf = withSharedPlugins ./claude/plugins.conf 41 (
    map (package: package.name) (agentPackages.for "claude")
  );
  # plugins.conf and plugin-marketplaces.conf, enabled at user scope: a
  # plugin enabled per directory is missing from the first session in every
  # new one, while claude fetches what user settings enable on its own
  claudeConfLines =
    text:
    lib.filter (line: builtins.match "[[:space:]]*(#.*)?" line == null) (lib.splitString "\n" text);
  claudeMarketplaceRows = map (line: lib.filter (word: word != "") (lib.splitString " " line)) (
    claudeConfLines claudeMarketplacesConf
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
  ) (claudeConfLines claudePluginsConf);
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
  # every skill folder under src except skip, linked whole as prefix/<name>
  skillFolderEntries =
    prefix: src: skip:
    lib.mapAttrs'
      (name: _: {
        name = "${prefix}/${name}";
        value.source = "${src}/${name}";
      })
      (lib.filterAttrs (name: type: type == "directory" && !lib.elem name skip) (builtins.readDir src));
  # superpowers ships test-driven-development under the same name, and the
  # clis that load these as bare skills have no plugin namespace to tell
  # the two apart
  agentSkillEntries =
    prefix: skillFolderEntries prefix "${inputs.agent-skills}/skills" [ "test-driven-development" ];
  # `<input>/<path>` of configs/agents/plugins.conf, inside that flake input
  inputPath =
    spec:
    let
      match = builtins.match "([^/]+)/(.*)" spec;
    in
    "${inputs.${builtins.head match}}/${builtins.elemAt match 1}";
  # the bare skills of configs/agents/plugins.conf (skill=) a cli gets, linked
  # under prefix by their folder name (graphify's by the package, in the
  # variant of the cli)
  graphifyVariants = {
    claude = graphifySkill "claude" "skill.md";
    agents = graphifySkill "agents" "skill-agents.md";
    # graphify installs claude's variant for antigravity too
    antigravity = graphifySkill "claude" "skill.md";
    kiro = graphifySkill "kiro" "skill-kiro.md";
  };
  bareSkillEntries =
    cli: prefix:
    builtins.listToAttrs (
      map (
        package:
        let
          spec = agentPackages.valueFor "skill" package;
        in
        {
          name = "${prefix}/${if lib.hasPrefix "pkg:" spec then package.name else baseNameOf spec}";
          value.source =
            if spec == "pkg:graphify" then
              graphifyVariants.${cli}
            else if lib.hasPrefix "pkg:" spec then
              throw "configs/agents/plugins.conf: no skill builder for ${spec}"
            else
              inputPath spec;
        }
      ) (agentPackages.skillsFor cli)
    );
  # claude user memory (the rest of configs/claude is deployed by the generic loop)
  claudeConfigEntries = {
    "claude/CLAUDE.md".source = ./agents/global-rules.md;
    "claude/plugins.conf".text = claudePluginsConf;
    "claude/plugin-marketplaces.conf".text = claudeMarketplacesConf;
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
    "codex/plugins.conf".text = withSharedPlugins ./codex/plugins.conf 65 codexSharedPlugins;
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
    # packages with no opencode plugin to pin: the skill alone, kept out of
    # ~/.agents/skills since codex installs the same packages as plugins
    "opencode/skills/caveman".source = "${inputs.caveman}/skills/caveman";
    "opencode/skills/taste-skill".source = "${inputs.taste-skill}/skills/taste-skill";
  }
  // agentSkillEntries "opencode/skills";
  # the shared plugins codex installs, `<plugin>@<marketplace>`
  codexSharedPlugins = map (
    package:
    let
      id = agentPackages.valueFor "codex" package;
    in
    if id == null then agentPackages.claudeId package else id
  ) (agentPackages.for "codex");
  # config.toml with a marketplace table for each of them, but the built-in one
  codexConfig = pkgs.writeText "codex-config.toml" (
    builtins.readFile ./codex/config.toml
    + lib.concatStrings (
      lib.unique (
        lib.zipListsWith (
          id: package:
          let
            marketplace = lib.last (lib.splitString "@" id);
          in
          lib.optionalString (marketplace != "openai-curated-remote") ''

            [marketplaces.${marketplace}]
            source_type = "git"
            source = "https://github.com/${package.repository}.git"
          ''
        ) codexSharedPlugins (agentPackages.for "codex")
      )
    )
  );
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
  # kiro installs no plugins, so it gets the packages' skill folders and,
  # for ponytail, the steering file its install guide gives kiro
  kiroSkillEntries =
    agentSkillEntries ".kiro/skills"
    // skillFolderEntries ".kiro/skills" "${inputs.superpowers}/skills" [ ]
    // {
      ".kiro/skills/caveman".source = "${inputs.caveman}/skills/caveman";
      ".kiro/skills/taste-skill".source = "${inputs.taste-skill}/skills/taste-skill";
      ".kiro/steering/ponytail.md".source = "${inputs.ponytail}/.kiro/steering/ponytail.md";
    };
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
        copyWritableConfig "codex" codexConfig
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
                  ./agents/plugins.conf
                  ./agents/skills
                ]
              );
        };
        recursive = true;
      };
      # yomiyasu comes from its flake input; codex and opencode read it here
      ".agents/skills/yomiyasu".source = "${inputs.yomiyasu}/skills/yomiyasu";
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
    // sharedSkillEntries
    // kiroSkillEntries
    // bareSkillEntries "agents" ".agents/skills"
    // bareSkillEntries "antigravity" ".gemini/config/skills"
    // bareSkillEntries "kiro" ".kiro/skills";
  };
  # xdg
  xdg = {
    configFile =
      configFiles
      // quickshellOverride
      // claudeOverride
      // opencodeOverride
      // claudeConfigEntries
      // bareSkillEntries "claude" "claude/skills"
      // claudeHistorySkill
      // codexConfigEntries
      // grokConfigEntries
      // opencodeConfigEntries
      // hyprConfigEntries
      // zshConfigEntries;
  };
}
