# apps configuration
inputs:
let
  lib = import ../../lib inputs;
  inherit (lib) supportedSystems;
  pkgs = system: import inputs.nixpkgs { inherit system; };
  # status messages: the palette and the blank-line rule live in lib/messages.nix
  messages = import ../../lib/messages.nix;
  inherit (messages) colors;
  # sudo setup: prompt upfront and keep credential alive during long builds
  # (the blank line only follows an actual password prompt)
  sudoSetup = ''
    if ! sudo -n true 2>/dev/null; then
      sudo -v
      ${messages.blank}
    fi
    while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
    SUDO_KEEPALIVE_PID=$!
    trap 'kill $SUDO_KEEPALIVE_PID 2>/dev/null' EXIT
  '';
  # host configurations
  hosts = {
    # nixos
    yanoNixOs = {
      system = "x86_64-linux";
      osType = "nixos";
      systemConfig = "yanoNixOs";
      homeConfig = "yanosea@yanoNixOs";
      preHomeCommands = ''
        rm -fr "$HOME/.config/claude/CLAUDE.md"
        rm -fr "$HOME/.config/fcitx5/config"
        rm -fr "$HOME/.config/fcitx5/profile"
      '';
    };
    # nixos (wsl)
    yanoNixOsWsl = {
      system = "x86_64-linux";
      osType = "nixos";
      systemConfig = "yanoNixOsWsl";
      homeConfig = "yanosea@yanoNixOsWsl";
      preHomeCommands = ''
        rm -fr "$HOME/.config/claude/CLAUDE.md"
      '';
    };
    # mac
    yanoMac = {
      system = "aarch64-darwin";
      osType = "darwin";
      systemConfig = "yanoMac";
      homeConfig = "yanosea@yanoMac";
      preHomeCommands = ''
        rm -f "$HOME/.config/AquaSKK/DictionarySet.plist"
        rm -f "$HOME/.config/AquaSKK/BlacklistApps.plist"
        rm -fr "$HOME/.config/claude/CLAUDE.md"
      '';
    };
    # mac book
    yanoMacBook = {
      system = "aarch64-darwin";
      osType = "darwin";
      systemConfig = "yanoMacBook";
      homeConfig = "yanosea@yanoMacBook";
      preHomeCommands = ''
        rm -f "$HOME/.config/AquaSKK/DictionarySet.plist"
        rm -f "$HOME/.config/AquaSKK/BlacklistApps.plist"
        rm -fr "$HOME/.config/claude/CLAUDE.md"
      '';
    };
  };
  # helper to create system command
  mkSystemCommand =
    host:
    if host.osType == "nixos" then
      "sudo nixos-rebuild switch --flake .#${host.systemConfig}"
    else
      "sudo darwin-rebuild switch --flake .#${host.systemConfig}";
  # helper to create home command
  mkHomeCommand =
    host: experimental:
    let
      envPrefix = if experimental then "EXPERIMENTAL_MODE=1 " else "";
      impureFlag = if experimental then " --impure" else "";
    in
    ''
      ${host.preHomeCommands}
      ${envPrefix}nix run${impureFlag} .#homeConfigurations."${host.homeConfig}".activationPackage
    '';
  # helper to create test script for a host
  mkTestScript =
    host:
    let
      configType = if host.osType == "nixos" then "nixosConfigurations" else "darwinConfigurations";
      buildPath = if host.osType == "nixos" then ".config.system.build.toplevel" else ".system";
    in
    ''
      ${messages.step {
        start = "validate system configuration syntax and dependencies...";
        done = "validate system configuration done!";
        body = "nix eval .#${configType}.${host.systemConfig}${buildPath}.drvPath --show-trace";
      }}
      ${messages.step {
        start = "validate home configuration syntax and dependencies...";
        done = "validate home configuration done!";
        body = "nix eval .#homeConfigurations.\"${host.homeConfig}\".activationPackage.drvPath --show-trace";
      }}
      ${messages.step {
        start = "check system build dependencies without actual building...";
        done = "check system build dependencies done!";
        body = "nix build .#${configType}.${host.systemConfig}${buildPath} --dry-run --show-trace";
      }}
      ${messages.step {
        start = "check home build dependencies without actual building...";
        done = "check home build dependencies done!";
        body = "nix build .#homeConfigurations.\"${host.homeConfig}\".activationPackage --dry-run --show-trace";
      }}
    '';
  # gc steps for system & user
  gcSteps = ''
    ${messages.step {
      start = "cleaning up system-wide packages...";
      done = "cleaning up system-wide packages done!";
      body = ''
        sudo nix-collect-garbage --delete-old
        sudo -i nix profile wipe-history
        sudo -i nix store gc
      '';
    }}
    ${messages.step {
      start = "cleaning up user packages...";
      done = "cleaning up user packages done!";
      body = ''
        nix-collect-garbage --delete-old
        nix profile wipe-history
        nix store gc
      '';
    }}
  '';
  reloadHint = messages.hint "hint: run 'reload' or 'exec zsh' to apply shell changes";
  # helper to create system + home update script
  mkUpdateScript =
    host: experimental: hostname:
    let
      suffix = if experimental then " experimentally" else "";
    in
    ''
      ${messages.titleGroup {
        start = "update ${hostname}${suffix}...";
        done = "${if experimental then "experimental " else ""}update done!";
        body = ''
          ${sudoSetup}
          ${
            if host.osType == "darwin" then
              messages.title {
                start = "upgrade nix...";
                done = "upgrade nix done!";
                body = "sudo determinate-nixd upgrade";
              }
            else
              ""
          }
          ${messages.title {
            start = "apply system configuration...";
            done = "apply system configuration done!";
            body = mkSystemCommand host;
          }}
          ${messages.title {
            start = "apply home configuration${suffix}...";
            done = "apply home configuration${suffix} done!";
            body = mkHomeCommand host experimental;
          }}
          ${
            if experimental then
              ""
            else
              messages.titleGroup {
                start = "garbage collection (system & user)...";
                done = "garbage collection (system & user) done!";
                body = gcSteps;
              }
          }
        '';
      }}
      ${reloadHint}
    '';
  # host command generators
  hostCommands = hostname: host: {
    system = messages.title {
      start = "apply system configuration...";
      done = "apply system configuration done!";
      body = ''
        ${sudoSetup}
        ${mkSystemCommand host}
      '';
    };
    home = ''
      ${messages.title {
        start = "apply home configuration...";
        done = "apply home configuration done!";
        body = mkHomeCommand host false;
      }}
      ${reloadHint}
    '';
    update = mkUpdateScript host false hostname;
    experiment = mkUpdateScript host true hostname;
    test = messages.titleGroup {
      start = "test ${hostname} configuration...";
      done = "test done!";
      body = ''
        ${messages.step {
          start = "check flake configuration...";
          done = "check flake configuration done!";
          body = "nix flake check";
        }}
        ${mkTestScript host}
      '';
    };
  };
  # create host-specific app
  mkHostApp =
    p: hostname: target:
    let
      host = hosts.${hostname};
      repoRoot = "$(${p.git}/bin/git rev-parse --show-toplevel)";
      commands = hostCommands hostname host;
      script = p.writeShellScript "${hostname}-${target}" ''
        set -euo pipefail
        cd "${repoRoot}"
        # verify hostname matches
        CURRENT_HOST="$(hostname)"
        if [[ "$CURRENT_HOST" != "${hostname}" ]]; then
          ${messages.error "error: hostname mismatch"}
          echo -e "  expected: ${hostname}"
          echo -e "  actual:   $CURRENT_HOST"
          ${messages.blank}
          echo -e "use ${colors.hint}nix run .#$CURRENT_HOST-${target}${colors.reset} or ${colors.hint}nix run .#${target}${colors.reset} instead"
          exit 1
        fi
        # execute target action
        ${messages.blank}
        ${commands.${target} or "${messages.error "unsupported target: ${target}"}"}
      '';
    in
    {
      type = "app";
      program = "${script}";
    };
  # create auto-detect app (detects hostname at runtime)
  mkAutoDetectApp =
    p: target:
    let
      hostNames = builtins.attrNames hosts;
      repoRoot = "$(${p.git}/bin/git rev-parse --show-toplevel)";
      script = p.writeShellScript "auto-${target}" ''
        set -euo pipefail
        cd "${repoRoot}"
        HOSTNAME="$(hostname)"
        case "$HOSTNAME" in
          ${builtins.concatStringsSep "\n      " (
            map (hostname: ''
              ${hostname})
                  nix run .#${hostname}-${target}
                  ;;'') hostNames
          )}
          *)
            ${messages.error "unsupported hostname: $HOSTNAME"}
            exit 1
            ;;
        esac
      '';
    in
    {
      type = "app";
      program = "${script}";
    };
  # gc script for system & user
  gcSystemScript = messages.titleGroup {
    start = "garbage collection (system & user)...";
    done = "garbage collection (system & user) done!";
    body = ''
      ${sudoSetup}
      ${gcSteps}
    '';
  };
  # utility command generators
  utilityCommands = {
    format = messages.title {
      start = "format files...";
      done = "format done!";
      body = "nix fmt";
    };
    gc = gcSystemScript;
    "gc.system" = gcSystemScript;
    "gc.user" = messages.title {
      start = "garbage collection (user)...";
      done = "garbage collection (user) done!";
      body = ''
        nix profile wipe-history
        nix store gc
      '';
    };
    clean = messages.title {
      start = "clean result directory...";
      done = "clean done!";
      body = "rm -fr result";
      quiet = true;
    };
    help = ''
      CURRENT_HOST="$(hostname)"
      # calculate max width based on longest command (hostname-experiment)
      MAX_CMD="nix run .#$CURRENT_HOST-experiment"
      WIDTH=''${#MAX_CMD}
      # helper to print command with description
      print_cmd() {
        local cmd="$1"
        local desc="$2"
        printf "      ${colors.done}%-''${WIDTH}s${colors.reset} - %s\n" "$cmd" "$desc"
      }
      ${messages.hint "detected hostname: $CURRENT_HOST"}
      echo -e "  ${colors.title}available commands:${colors.reset}"
      ${messages.blank}
      echo -e "    ${colors.hint}[host-specific operations (auto-detect)]${colors.reset}"
      print_cmd "nix run .#update" "update whole system"
      print_cmd "nix run .#system" "apply system configuration"
      print_cmd "nix run .#home" "apply home configuration"
      print_cmd "nix run .#experiment" "experimental update (time-consuming sync operations are disabled)"
      print_cmd "nix run .#test" "test configuration (dry-run)"
      ${messages.blank}
      echo -e "    ${colors.hint}[host-specific operations (explicit)]${colors.reset}"
      print_cmd "nix run .#$CURRENT_HOST-update" "update whole system"
      print_cmd "nix run .#$CURRENT_HOST-system" "apply system configuration"
      print_cmd "nix run .#$CURRENT_HOST-home" "apply home configuration"
      print_cmd "nix run .#$CURRENT_HOST-experiment" "experimental update (time-consuming sync operations are disabled)"
      print_cmd "nix run .#$CURRENT_HOST-test" "test configuration (dry-run)"
      ${messages.blank}
      echo -e "    ${colors.hint}[utility operations]${colors.reset}"
      print_cmd "nix run .#format" "format files"
      print_cmd "nix run .#gc" "garbage collection (system & user)"
      print_cmd "nix run .#gc.system" "garbage collection (system & user)"
      print_cmd "nix run .#gc.user" "garbage collection (user only)"
      print_cmd "nix run .#clean" "remove result directory"
      print_cmd "nix run .#help" "show this help message"
    '';
  };
  # create common utility app (format, gc, clean)
  mkUtilityApp =
    p: target:
    let
      repoRoot = "$(${p.git}/bin/git rev-parse --show-toplevel)";
      script = p.writeShellScript "util-${target}" ''
        set -euo pipefail
        cd "${repoRoot}"
        ${messages.blank}
        ${utilityCommands.${target} or "${messages.error "unsupported target: ${target}"}"}
      '';
    in
    {
      type = "app";
      program = "${script}";
    };
  # host-specific targets
  hostTargets = [
    "update"
    "system"
    "home"
    "experiment"
    "test"
  ];
  # utility targets (no host-specific behavior)
  utilityTargets = [
    "clean"
    "format"
    "gc"
    "gc.system"
    "gc.user"
    "help"
  ];
  # create all apps for a system
  mkAppsForSystem =
    system:
    let
      p = pkgs system;
      hostsForSystem = builtins.filter (h: hosts.${h}.system == system) (builtins.attrNames hosts);
      # host-specific apps: <hostname>-<target>
      hostApps = builtins.listToAttrs (
        builtins.concatMap (
          hostname:
          map (target: {
            name = "${hostname}-${target}";
            value = mkHostApp p hostname target;
          }) hostTargets
        ) hostsForSystem
      );
      # auto-detect apps: <target> (detects hostname)
      autoApps = builtins.listToAttrs (
        map (target: {
          name = target;
          value = mkAutoDetectApp p target;
        }) hostTargets
      );
      # utility apps: <target> (no host-specific behavior)
      utilApps = builtins.listToAttrs (
        map (target: {
          name = target;
          value = mkUtilityApp p target;
        }) utilityTargets
      );
    in
    hostApps // autoApps // utilApps;
in
builtins.listToAttrs (
  map (system: {
    name = system;
    value = mkAppsForSystem system;
  }) supportedSystems
)
