# apps configuration
inputs:
let
  lib = import ../../lib inputs;
  inherit (lib) supportedSystems;
  pkgs = system: import inputs.nixpkgs { inherit system; };

  # host configurations
  hosts = {
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
    yanoNixOsWsl = {
      system = "x86_64-linux";
      osType = "nixos";
      systemConfig = "yanoNixOsWsl";
      homeConfig = "yanosea@yanoNixOsWsl";
      preHomeCommands = ''
        rm -fr "$HOME/.config/claude/CLAUDE.md"
      '';
    };
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

  # color codes
  colors = {
    reset = "\\033[0m";
    title = "\\033[35m"; # magenta
    header = "\\033[33m"; # yellow
    done = "\\033[32m"; # green
    error = "\\033[31m"; # red
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

  # create host-specific app
  mkHostApp =
    p: hostname: target:
    let
      host = hosts.${hostname};
      repoRoot = ''$(${p.git}/bin/git rev-parse --show-toplevel)'';
      script = p.writeShellScript "${hostname}-${target}" ''
        set -euo pipefail
        cd "${repoRoot}"

        # verify hostname matches
        CURRENT_HOST="$(hostname)"
        if [[ "$CURRENT_HOST" != "${hostname}" ]]; then
          echo -e "${colors.error}error: hostname mismatch${colors.reset}"
          echo -e "  expected: ${hostname}"
          echo -e "  actual:   $CURRENT_HOST"
          echo ""
          echo -e "use ${colors.header}nix run .#$CURRENT_HOST-${target}${colors.reset} or ${colors.header}nix run .#${target}${colors.reset} instead"
          exit 1
        fi

        ${
          if target == "system" then
            ''
              echo -e "${colors.title}apply system configuration...${colors.reset}"
              echo ""
              ${mkSystemCommand host}
              echo ""
              echo -e "${colors.done}apply system configuration done!${colors.reset}"
            ''
          else if target == "home" then
            ''
              echo -e "${colors.title}apply home configuration...${colors.reset}"
              echo ""
              ${mkHomeCommand host false}
              echo -e "${colors.done}apply home configuration done!${colors.reset}"
            ''
          else if target == "update" then
            ''
              echo -e "${colors.title}update ${hostname}...${colors.reset}"
              echo ""
              echo -e "${colors.title}apply system configuration...${colors.reset}"
              echo ""
              ${mkSystemCommand host}
              echo ""
              echo -e "${colors.done}apply system configuration done!${colors.reset}"
              echo ""
              echo -e "${colors.title}apply home configuration...${colors.reset}"
              echo ""
              ${mkHomeCommand host false}
              echo -e "${colors.done}apply home configuration done!${colors.reset}"
              echo ""
              echo -e "${colors.done}update done!${colors.reset}"
            ''
          else if target == "experiment" then
            ''
              echo -e "${colors.title}update ${hostname} experimentally...${colors.reset}"
              echo ""
              echo -e "${colors.title}apply system configuration...${colors.reset}"
              echo ""
              ${mkSystemCommand host}
              echo ""
              echo -e "${colors.done}apply system configuration done!${colors.reset}"
              echo ""
              echo -e "${colors.title}apply home configuration experimentally...${colors.reset}"
              echo ""
              ${mkHomeCommand host true}
              echo -e "${colors.done}apply home configuration experimentally done!${colors.reset}"
              echo ""
              echo -e "${colors.done}experimental update done!${colors.reset}"
            ''
          else if target == "test" then
            ''
              echo -e "${colors.title}test ${hostname} configuration...${colors.reset}"
              echo ""
              echo -e "${colors.header}check flake configuration...${colors.reset}"
              nix flake check
              echo ""
              ${
                if host.osType == "nixos" then
                  ''
                    echo -e "${colors.header}validate system configuration syntax and dependencies...${colors.reset}"
                    nix eval .#nixosConfigurations.${host.systemConfig}.config.system.build.toplevel.drvPath --show-trace
                    echo ""
                    echo -e "${colors.header}validate home configuration syntax and dependencies...${colors.reset}"
                    nix eval .#homeConfigurations."${host.homeConfig}".activationPackage.drvPath --show-trace
                    echo ""
                    echo -e "${colors.header}check system build dependencies without actual building...${colors.reset}"
                    nix build .#nixosConfigurations.${host.systemConfig}.config.system.build.toplevel --dry-run --show-trace
                    echo ""
                    echo -e "${colors.header}check home build dependencies without actual building...${colors.reset}"
                    nix build .#homeConfigurations."${host.homeConfig}".activationPackage --dry-run --show-trace
                  ''
                else
                  ''
                    echo -e "${colors.header}validate system configuration syntax and dependencies...${colors.reset}"
                    nix eval .#darwinConfigurations.${host.systemConfig}.system.drvPath --show-trace
                    echo ""
                    echo -e "${colors.header}validate home configuration syntax and dependencies...${colors.reset}"
                    nix eval .#homeConfigurations."${host.homeConfig}".activationPackage.drvPath --show-trace
                    echo ""
                    echo -e "${colors.header}check system build dependencies without actual building...${colors.reset}"
                    nix build .#darwinConfigurations.${host.systemConfig}.system --dry-run --show-trace
                    echo ""
                    echo -e "${colors.header}check home build dependencies without actual building...${colors.reset}"
                    nix build .#homeConfigurations."${host.homeConfig}".activationPackage --dry-run --show-trace
                  ''
              }
              echo ""
              echo -e "${colors.done}test done!${colors.reset}"
            ''
          else
            ''echo -e "${colors.error}unsupported target: ${target}${colors.reset}"''
        }
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
      repoRoot = ''$(${p.git}/bin/git rev-parse --show-toplevel)'';
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
            echo -e "${colors.error}unsupported hostname: $HOSTNAME${colors.reset}"
            exit 1
            ;;
        esac
      '';
    in
    {
      type = "app";
      program = "${script}";
    };

  # create common utility app (format, gc, clean)
  mkUtilityApp =
    p: target:
    let
      repoRoot = ''$(${p.git}/bin/git rev-parse --show-toplevel)'';
      script = p.writeShellScript "util-${target}" ''
        set -euo pipefail
        cd "${repoRoot}"
        ${
          if target == "format" then
            ''
              echo -e "${colors.title}format files...${colors.reset}"
              echo ""
              nix fmt
              echo ""
              echo -e "${colors.done}format done!${colors.reset}"
            ''
          else if target == "gc" || target == "gc.system" then
            ''
              echo -e "${colors.title}garbage collection (system & user)...${colors.reset}"
              echo ""
              echo -e "${colors.header}cleaning up system-wide packages...${colors.reset}"
              sudo nix-collect-garbage --delete-old
              sudo -i nix profile wipe-history
              sudo -i nix store gc
              echo ""
              echo -e "${colors.header}cleaning up user packages...${colors.reset}"
              nix-collect-garbage --delete-old
              nix profile wipe-history
              nix store gc
              echo ""
              echo -e "${colors.done}garbage collection (system & user) done!${colors.reset}"
            ''
          else if target == "gc.user" then
            ''
              echo -e "${colors.title}garbage collection (user)...${colors.reset}"
              echo ""
              nix profile wipe-history
              nix store gc
              echo ""
              echo -e "${colors.done}garbage collection (user) done!${colors.reset}"
            ''
          else if target == "clean" then
            ''
              echo -e "${colors.title}clean result directory...${colors.reset}"
              echo ""
              rm -fr result
              echo -e "${colors.done}clean done!${colors.reset}"
            ''
          else if target == "help" then
            ''
              CURRENT_HOST="$(hostname)"
              # calculate max width based on longest command (hostname-experiment)
              MAX_CMD="nix run .#$CURRENT_HOST-experiment"
              WIDTH=''${#MAX_CMD}

              print_cmd() {
                local cmd="$1"
                local desc="$2"
                printf "      ${colors.done}%-''${WIDTH}s${colors.reset} - %s\n" "$cmd" "$desc"
              }

              echo -e "${colors.header}detected hostname: $CURRENT_HOST${colors.reset}"
              echo ""
              echo -e "  ${colors.title}available commands:${colors.reset}"
              echo ""
              echo -e "    ${colors.header}[host-specific operations (auto-detect)]${colors.reset}"
              print_cmd "nix run .#update" "update whole system"
              print_cmd "nix run .#system" "apply system configuration"
              print_cmd "nix run .#home" "apply home configuration"
              print_cmd "nix run .#experiment" "experimental update (time-consuming sync operations are disabled)"
              print_cmd "nix run .#test" "test configuration (dry-run)"
              echo ""
              echo -e "    ${colors.header}[host-specific operations (explicit)]${colors.reset}"
              print_cmd "nix run .#$CURRENT_HOST-update" "update whole system"
              print_cmd "nix run .#$CURRENT_HOST-system" "apply system configuration"
              print_cmd "nix run .#$CURRENT_HOST-home" "apply home configuration"
              print_cmd "nix run .#$CURRENT_HOST-experiment" "experimental update (time-consuming sync operations are disabled)"
              print_cmd "nix run .#$CURRENT_HOST-test" "test configuration (dry-run)"
              echo ""
              echo -e "    ${colors.header}[utility operations]${colors.reset}"
              print_cmd "nix run .#format" "format files"
              print_cmd "nix run .#gc" "garbage collection (system & user)"
              print_cmd "nix run .#gc.system" "garbage collection (system & user)"
              print_cmd "nix run .#gc.user" "garbage collection (user only)"
              print_cmd "nix run .#clean" "remove result directory"
              print_cmd "nix run .#help" "show this help message"
            ''
          else
            ''echo -e "${colors.error}unsupported target: ${target}${colors.reset}"''
        }
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
    "format"
    "gc"
    "gc.system"
    "gc.user"
    "clean"
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
