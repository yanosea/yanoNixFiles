# apps configuration
inputs:
let
  lib = import ../../lib inputs;
  inherit (lib) supportedSystems;
  pkgs = system: import inputs.nixpkgs { inherit system; };
  # color codes
  colors = {
    reset = "\\033[0m";
    title = "\\033[35m"; # magenta
    header = "\\033[33m"; # yellow
    done = "\\033[32m"; # green
    error = "\\033[31m"; # red
  };
  # echo helpers
  echo = {
    title = msg: ''echo -e "${colors.title}${msg}${colors.reset}"'';
    header = msg: ''echo -e "${colors.header}${msg}${colors.reset}"'';
    done = msg: ''echo -e "${colors.done}${msg}${colors.reset}"'';
    error = msg: ''echo -e "${colors.error}${msg}${colors.reset}"'';
    blank = ''echo ""'';
  };
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
        rm -fr "$HOME/.config/karabiner/karabiner.json"
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
        rm -fr "$HOME/.config/karabiner/karabiner.json"
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
      ${echo.header "validate system configuration syntax and dependencies..."}
      nix eval .#${configType}.${host.systemConfig}${buildPath}.drvPath --show-trace
      ${echo.blank}
      ${echo.header "validate home configuration syntax and dependencies..."}
      nix eval .#homeConfigurations."${host.homeConfig}".activationPackage.drvPath --show-trace
      ${echo.blank}
      ${echo.header "check system build dependencies without actual building..."}
      nix build .#${configType}.${host.systemConfig}${buildPath} --dry-run --show-trace
      ${echo.blank}
      ${echo.header "check home build dependencies without actual building..."}
      nix build .#homeConfigurations."${host.homeConfig}".activationPackage --dry-run --show-trace
    '';
  # helper to create system + home update script
  mkUpdateScript = host: experimental: hostname: ''
    ${echo.title "update ${hostname}${if experimental then " experimentally" else ""}..."}
    ${echo.blank}
    ${
      if host.osType == "darwin" then
        ''
          ${echo.title "upgrade nix..."}
          ${echo.blank}
          sudo determinate-nixd upgrade
          ${echo.blank}
          ${echo.done "upgrade nix done!"}
          ${echo.blank}
        ''
      else
        ""
    }
    ${echo.title "apply system configuration..."}
    ${echo.blank}
    ${mkSystemCommand host}
    ${echo.blank}
    ${echo.done "apply system configuration done!"}
    ${echo.blank}
    ${echo.title "apply home configuration${if experimental then " experimentally" else ""}..."}
    ${echo.blank}
    ${mkHomeCommand host experimental}
    ${echo.done "apply home configuration${if experimental then " experimentally" else ""} done!"}
    ${echo.blank}
    ${
      if experimental then
        ""
      else
        ''
          ${echo.title "garbage collection (system & user)..."}
          ${echo.blank}
          ${echo.header "cleaning up system-wide packages..."}
          sudo nix-collect-garbage --delete-old
          sudo -i nix profile wipe-history
          sudo -i nix store gc
          ${echo.blank}
          ${echo.header "cleaning up user packages..."}
          nix-collect-garbage --delete-old
          nix profile wipe-history
          nix store gc
          ${echo.blank}
          ${echo.done "garbage collection (system & user) done!"}
          ${echo.blank}
        ''
    }
    ${echo.done "${if experimental then "experimental " else ""}update done!"}
    ${echo.blank}
    ${echo.header "hint: run 'reload' or 'exec zsh' to apply shell changes"}
  '';
  # host command generators
  hostCommands = hostname: host: {
    system = ''
      ${echo.title "apply system configuration..."}
      ${echo.blank}
      ${mkSystemCommand host}
      ${echo.blank}
      ${echo.done "apply system configuration done!"}
    '';
    home = ''
      ${echo.title "apply home configuration..."}
      ${echo.blank}
      ${mkHomeCommand host false}
      ${echo.done "apply home configuration done!"}
      ${echo.blank}
      ${echo.header "hint: run 'reload' or 'exec zsh' to apply shell changes"}
    '';
    update = mkUpdateScript host false hostname;
    experiment = mkUpdateScript host true hostname;
    test = ''
      ${echo.title "test ${hostname} configuration..."}
      ${echo.blank}
      ${echo.header "check flake configuration..."}
      nix flake check
      ${echo.blank}
      ${mkTestScript host}
      ${echo.blank}
      ${echo.done "test done!"}
    '';
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
          ${echo.error "error: hostname mismatch"}
          echo -e "  expected: ${hostname}"
          echo -e "  actual:   $CURRENT_HOST"
          ${echo.blank}
          echo -e "use ${colors.header}nix run .#$CURRENT_HOST-${target}${colors.reset} or ${colors.header}nix run .#${target}${colors.reset} instead"
          exit 1
        fi
        # execute target action
        ${commands.${target} or "${echo.error "unsupported target: ${target}"}"}
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
            ${echo.error "unsupported hostname: $HOSTNAME"}
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
  gcSystemScript = ''
    ${echo.title "garbage collection (system & user)..."}
    ${echo.blank}
    ${echo.header "cleaning up system-wide packages..."}
    sudo nix-collect-garbage --delete-old
    sudo -i nix profile wipe-history
    sudo -i nix store gc
    ${echo.blank}
    ${echo.header "cleaning up user packages..."}
    nix-collect-garbage --delete-old
    nix profile wipe-history
    nix store gc
    ${echo.blank}
    ${echo.done "garbage collection (system & user) done!"}
  '';
  # utility command generators
  utilityCommands = {
    format = ''
      ${echo.title "format files..."}
      ${echo.blank}
      nix fmt
      ${echo.blank}
      ${echo.done "format done!"}
    '';
    gc = gcSystemScript;
    "gc.system" = gcSystemScript;
    "gc.user" = ''
      ${echo.title "garbage collection (user)..."}
      ${echo.blank}
      nix profile wipe-history
      nix store gc
      ${echo.blank}
      ${echo.done "garbage collection (user) done!"}
    '';
    clean = ''
      ${echo.title "clean result directory..."}
      ${echo.blank}
      rm -fr result
      ${echo.done "clean done!"}
    '';
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
      ${echo.header "detected hostname: $CURRENT_HOST"}
      ${echo.blank}
      echo -e "  ${colors.title}available commands:${colors.reset}"
      ${echo.blank}
      echo -e "    ${colors.header}[host-specific operations (auto-detect)]${colors.reset}"
      print_cmd "nix run .#update" "update whole system"
      print_cmd "nix run .#system" "apply system configuration"
      print_cmd "nix run .#home" "apply home configuration"
      print_cmd "nix run .#experiment" "experimental update (time-consuming sync operations are disabled)"
      print_cmd "nix run .#test" "test configuration (dry-run)"
      ${echo.blank}
      echo -e "    ${colors.header}[host-specific operations (explicit)]${colors.reset}"
      print_cmd "nix run .#$CURRENT_HOST-update" "update whole system"
      print_cmd "nix run .#$CURRENT_HOST-system" "apply system configuration"
      print_cmd "nix run .#$CURRENT_HOST-home" "apply home configuration"
      print_cmd "nix run .#$CURRENT_HOST-experiment" "experimental update (time-consuming sync operations are disabled)"
      print_cmd "nix run .#$CURRENT_HOST-test" "test configuration (dry-run)"
      ${echo.blank}
      echo -e "    ${colors.header}[utility operations]${colors.reset}"
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
        ${utilityCommands.${target} or "${echo.error "unsupported target: ${target}"}"}
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
