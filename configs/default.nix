# configs (dotfiles)
{
  agentPackages,
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
  # opencode skips a plugin directory whose files are symlinks, so these leave the
  # recursive link and are linked whole in opencodeConfigEntries
  opencodePluginDirs = [
    "console-budget"
    "paid-guard"
  ];
  opencodeOverride = {
    "opencode" = configFiles."opencode" // {
      source = lib.fileset.toSource {
        root = ./opencode;
        fileset = lib.fileset.difference ./opencode (
          lib.fileset.unions (map (name: ./opencode/plugins + "/${name}") opencodePluginDirs)
        );
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
    withSharedPluginNotes file width (
      map (id: {
        inherit id;
        note = "shared";
      }) ids
    );
  # the same, with a comment of its own per plugin ({ id, note })
  withSharedPluginNotes =
    file: width: entries:
    let
      ids = map (entry: entry.id) entries;
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
    + lib.optionalString (entries != [ ]) (
      "\n# shared with the other clis, declared in configs/agents/plugins.conf\n"
      + lib.concatMapStrings (entry: "[x] ${pad entry.id}# ${entry.note}\n") entries
    );
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
  # the skill folders (skill:, skills:) and kiro steering files (steering:)
  # that a cli without plugins links from configs/agents/plugins.conf; skill
  # folders go under prefix by their folder name
  sharedSkillLinks =
    cli: prefix:
    lib.foldl' (
      links: value:
      let
        match = if value == null then null else builtins.match "([a-z]+):(.*)" value;
        kind = if match == null then null else builtins.head match;
        spec = builtins.elemAt match 1;
        # skills:<input>/<path>!<skip>...
        skills = lib.splitString "!" spec;
      in
      links
      // (
        if kind == "skill" then
          { "${prefix}/${baseNameOf spec}".source = inputPath spec; }
        else if kind == "skills" then
          skillFolderEntries prefix (inputPath (builtins.head skills)) (builtins.tail skills)
        else if kind == "steering" then
          { ".kiro/steering/${baseNameOf spec}".source = inputPath spec; }
        else
          { }
      )
    ) { } (lib.concatMap (agentPackages.valuesFor cli) (agentPackages.for cli));
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
  # grok config files (config.toml is deployed by an activation copy instead)
  # grok reads AGENTS.md from GROK_HOME (INSTRUCTION_FILENAMES)
  grokConfigEntries = {
    "grok/AGENTS.md".source = ./agents/global-rules.md;
    # sync-plugins.sh installs a `# shared from <repository>` plugin from there
    "grok/plugins.conf".text = withSharedPluginNotes ./grok/plugins.conf 41 (
      map
        (package: {
          id = package.name;
          note =
            if agentPackages.valueFor "grok" package == "xai" then
              "shared"
            else
              "shared from ${package.repository}";
        })
        (
          lib.filter (
            package:
            lib.elem (agentPackages.valueFor "grok" package) [
              null
              "xai"
            ]
          ) (agentPackages.for "grok")
        )
    );
    "grok/hooks" = {
      source = ./grok/hooks;
      recursive = true;
    };
  }
  # grok reads skills from GROK_HOME/skills
  // sharedSkillLinks "grok" "grok/skills";
  # opencode user rules (the rest of configs/opencode is deployed by the generic loop,
  # since opencode never rewrites its config)
  opencodeConfigEntries =
    lib.listToAttrs (
      map (name: {
        name = "opencode/plugins/${name}";
        value = {
          source = ./opencode/plugins + "/${name}";
        };
      }) opencodePluginDirs
    )
    // {
      "opencode/AGENTS.md".source = ./agents/global-rules.md;
      "opencode/plugins/common-hooks.ts".source = ./agents/hooks/bridges/opencode.ts;
      # the shared npm plugins (opencode=npm:) and the mcp servers, in a file of
      # their own: opencode reads opencode.json and opencode.jsonc both, joins
      # their plugins and merges their servers by name
      "opencode/opencode.json".source = (pkgs.formats.json { }).generate "opencode.json" {
        "$schema" = "https://opencode.ai/config.json";
        plugins = lib.concatMap (
          package:
          map (lib.removePrefix "npm:") (
            lib.filter (lib.hasPrefix "npm:") (agentPackages.valuesFor "opencode" package)
          )
        ) (agentPackages.for "opencode");
        mcp = {
          servers = mcpServers;
        };
      };
    }
    # packages with no opencode plugin to pin: the skill alone, kept out of
    # ~/.agents/skills since copilot and grok install the same packages as plugins
    // sharedSkillLinks "opencode" "opencode/skills";
  # configs/agents/mcp-servers.conf as opencode servers, read the way
  # configs/antigravity/scripts/sync-mcp-servers.sh reads it: a `#` starts a
  # comment, and a row is `<name> [options] -- <command> [args...]` or
  # `<name> -t http|sse <url>`. options: -e/--env KEY=VALUE, -t/--transport
  mcpServers = lib.listToAttrs (
    map
      (
        line:
        let
          words = lib.filter (word: word != "") (lib.splitString " " line);
          rest = lib.tail words;
          split = lib.lists.findFirstIndex (word: word == "--") null rest;
          flagged = rest != [ ] && lib.hasPrefix "-" (lib.head rest);
          options =
            if split != null then
              lib.take split rest
            else if flagged then
              lib.init rest
            else
              [ ];
          target =
            if split != null then
              lib.drop (split + 1) rest
            else if flagged then
              [ (lib.last rest) ]
            else
              rest;
          fail = throw "configs/agents/mcp-servers.conf: cannot read `${line}`";
          pairs =
            if lib.mod (builtins.length options) 2 != 0 then
              fail
            else
              lib.genList (i: {
                flag = builtins.elemAt options (2 * i);
                value = builtins.elemAt options (2 * i + 1);
              }) (builtins.length options / 2);
          valuesOf = flags: map (pair: pair.value) (lib.filter (pair: lib.elem pair.flag flags) pairs);
          transports = valuesOf [
            "-t"
            "--transport"
          ];
          transport = if transports == [ ] then "stdio" else lib.last transports;
          environment = lib.listToAttrs (
            map
              (
                value:
                let
                  parts = lib.splitString "=" value;
                in
                lib.nameValuePair (lib.head parts) (lib.concatStringsSep "=" (lib.tail parts))
              )
              (valuesOf [
                "-e"
                "--env"
              ])
          );
          unknown = lib.filter (
            pair:
            !lib.elem pair.flag [
              "-e"
              "--env"
              "-t"
              "--transport"
            ]
          ) pairs;
        in
        if words == [ ] || target == [ ] || unknown != [ ] then
          fail
        else if transport == "stdio" then
          lib.nameValuePair (lib.head words) (
            {
              type = "local";
              command = target;
            }
            // lib.optionalAttrs (environment != { }) { inherit environment; }
          )
        else if
          lib.elem transport [
            "http"
            "sse"
          ]
          && environment == { }
          && builtins.length target == 1
        then
          lib.nameValuePair (lib.head words) {
            type = "remote";
            url = lib.head target;
          }
        else
          fail
      )
      (
        lib.filter (line: builtins.match "[[:space:]]*" line == null) (
          map (line: lib.head (lib.splitString "#" line)) (
            lib.splitString "\n" (builtins.readFile ./agents/mcp-servers.conf)
          )
        )
      )
  );
  # the shared plugins copilot installs, with their marketplaces, as the
  # settings.json keys for declarative install
  copilotSettings = pkgs.writeText "copilot-settings.json" (
    builtins.toJSON {
      enabledPlugins = lib.genAttrs (map agentPackages.pluginId (agentPackages.for "copilot")) (_: true);
      extraKnownMarketplaces = lib.listToAttrs (
        map (package: {
          name = package.marketplace;
          value = {
            source = {
              source = "github";
              repo = package.repository;
            };
            autoUpdate = true;
          };
        }) (agentPackages.for "copilot")
      );
    }
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
  # kiro installs no plugins, so it gets the skill folders and steering files
  # of the shared packages
  kiroSkillEntries = sharedSkillLinks "kiro" ".kiro/skills";
  # each skill is one directory symlink, not a tree of per-file links
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
      # the two plugin keys replace their old values, so the shared list
      # decides them; /settings keeps writing its other keys to the same file
      mergeCopilotSettings = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        if [ -z "''${DRY_RUN_CMD:-}" ] && [ -z "''${DRY_RUN:-}" ]; then
          settings="''${COPILOT_HOME:-$HOME/.copilot}/settings.json"
          mkdir -p "$(dirname "$settings")"
          if [ ! -f "$settings" ]; then
            cat ${copilotSettings} >"$settings"
          elif ${pkgs.jq}/bin/jq -s '.[0] + .[1]' "$settings" ${copilotSettings} >"$settings.tmp" 2>/dev/null; then
            mv "$settings.tmp" "$settings"
          else
            rm -f "$settings.tmp"
            echo "warning: $settings is not plain JSON, so the shared plugins were not merged" >&2
          fi
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
      # the cross-tool ~/.agents/skills lives outside XDG
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
      # yomiyasu comes from its flake input; opencode, grok and copilot read it here
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
      ".gemini/config/plugins.conf".text = withSharedPlugins ./antigravity/plugins.conf 41 (
        map (package: package.name) (agentPackages.for "antigravity")
      );
      # where sync-plugins.sh fetches each plugin from
      ".gemini/config/plugin-marketplaces.conf".text =
        builtins.readFile ./antigravity/plugin-marketplaces.conf
        + "\n# shared with the other clis, declared in configs/agents/plugins.conf\n"
        + lib.concatMapStrings (package: "${package.name} ${package.marketplace} ${package.repository}\n") (
          agentPackages.for "antigravity"
        );
      ".local/bin/agent-loop" = {
        executable = true;
        text = ''
          #!${pkgs.runtimeShell}
          exec ${pkgs.python3}/bin/python3 "$HOME/.agents/hooks/agent_loop.py" "$@"
        '';
      };
      # opencode go usage, read by paid-guard's go_quota and the openclaw check-ins
      ".local/bin/go-limits" = {
        executable = true;
        text = ''
          #!${pkgs.runtimeShell}
          exec ${pkgs.python3}/bin/python3 "$HOME/.agents/go-limits/go_limits.py" "$@"
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
      // opencodeOverride
      // grokConfigEntries
      // opencodeConfigEntries
      // hyprConfigEntries
      // zshConfigEntries;
  };
}
