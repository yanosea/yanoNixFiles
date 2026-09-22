# initialize variables
IS_WINDOWS := 0
IS_DARWIN := 0
IS_MAC := 0
IS_MACBOOK := 0
IS_NIXOS := 0
IS_NIXOS_WSL := 0
# check if windows
ifeq ($(OS),Windows_NT)
	IS_WINDOWS := 1
	SHELL := pwsh.exe
else
	SHELL := /usr/bin/env bash
	# detect other platforms
	UNAME_S := $(shell uname -s)
	ifeq ($(UNAME_S),Darwin)
		IS_DARWIN := 1
		# detect if macbook (portable) or mac (desktop)
		IS_MACBOOK := $(shell [ "$$(sysctl -n hw.model | grep -i "MacBook")" != "" ] && echo 1 || echo 0)
		ifeq ($(IS_MACBOOK),0)
			IS_MAC := 1
		endif
	else
		# check if nixos or wsl
		# first check if it's wsl
		IS_WSL := $(shell [ -f /proc/sys/fs/binfmt_misc/WSLInterop ] || grep -q "microsoft\|WSL" /proc/version 2>/dev/null && echo 1 || echo 0)
		# then check if it's nixos (directory exists)
		IS_NIXOS_CHECK := $(shell [ -d /etc/nixos ] && echo 1 || echo 0)
		# if it's both WSL and nixos, then it's nixos on wsl
		ifeq ($(IS_WSL)$(IS_NIXOS_CHECK),11)
			IS_NIXOS_WSL := 1
		# if it's just nixos, but not wsl
		else ifeq ($(IS_NIXOS_CHECK),1)
			IS_NIXOS := 1
		endif
	endif
endif
# define colors
# magenta and yellow are what nix and homebrew print warnings in, so neither marks progress here
# (comments stay on their own line: a trailing one would leave a space inside the value)
ifeq ($(IS_WINDOWS),1)
	COLOR_TITLE := -ForegroundColor Blue
	COLOR_STEP := -ForegroundColor Cyan
	COLOR_HEADER := -ForegroundColor Yellow
	COLOR_CMD := -ForegroundColor Cyan
	COLOR_DONE := -ForegroundColor Green
	COLOR_ERROR := -ForegroundColor Red
else
	COLOR_RESET := $(shell tput sgr0)
	# bold blue
	COLOR_TITLE := $(shell tput bold)$(shell tput setaf 4)
	# cyan
	COLOR_STEP := $(shell tput setaf 6)
	# yellow
	COLOR_HEADER := $(shell tput setaf 3)
	# cyan
	COLOR_CMD := $(shell tput setaf 6)
	# green
	COLOR_DONE := $(shell tput setaf 2)
	# red
	COLOR_ERROR := $(shell tput setaf 1)
endif
# shows help message defaultly
.DEFAULT_GOAL := help

# do not show directory name in command output
MAKEFLAGS += --no-print-directory

# not show command all
.SILENT:

# ignore errors all
.IGNORE:

#
# unified targets
#
.PHONY: update system home experiment format gc gc.system gc.user

# update whole system (settings, packages)
update:
ifeq ($(IS_NIXOS),1)
	@[ $(MAKELEVEL) -ne 0 ] || echo ""
	@echo "$(COLOR_TITLE)update nixos...$(COLOR_RESET)"
	@echo ""
	make system
	make home
	make gc
	@echo "$(COLOR_DONE)update done!$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_HEADER)hint: run 'reload' or 'exec zsh' to apply shell changes$(COLOR_RESET)"
	@echo ""
else ifeq ($(IS_NIXOS_WSL),1)
	@[ $(MAKELEVEL) -ne 0 ] || echo ""
	@echo "$(COLOR_TITLE)update nixos wsl...$(COLOR_RESET)"
	@echo ""
	make system
	make home
	make gc
	@echo "$(COLOR_DONE)update done!$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_HEADER)hint: run 'reload' or 'exec zsh' to apply shell changes$(COLOR_RESET)"
	@echo ""
else ifeq ($(IS_MAC),1)
	@[ $(MAKELEVEL) -ne 0 ] || echo ""
	@echo "$(COLOR_TITLE)update mac...$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_TITLE)upgrade nix...$(COLOR_RESET)"
	@echo ""
	sudo determinate-nixd upgrade
	@echo ""
	@echo "$(COLOR_DONE)upgrade nix done!$(COLOR_RESET)"
	@echo ""
	make system
	make home
	make gc
	@echo "$(COLOR_DONE)update done!$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_HEADER)hint: run 'reload' or 'exec zsh' to apply shell changes$(COLOR_RESET)"
	@echo ""
else ifeq ($(IS_MACBOOK),1)
	@[ $(MAKELEVEL) -ne 0 ] || echo ""
	@echo "$(COLOR_TITLE)update macbook...$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_TITLE)upgrade nix...$(COLOR_RESET)"
	@echo ""
	sudo determinate-nixd upgrade
	@echo ""
	@echo "$(COLOR_DONE)upgrade nix done!$(COLOR_RESET)"
	@echo ""
	make system
	make home
	make gc
	@echo "$(COLOR_DONE)update done!$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_HEADER)hint: run 'reload' or 'exec zsh' to apply shell changes$(COLOR_RESET)"
	@echo ""
else ifeq ($(IS_WINDOWS),1)
	@if ($(MAKELEVEL) -eq 0) { Write-Host "" }
	@Write-Host "update windows..." $(COLOR_TITLE)
	@Write-Host ""
	winget upgrade --silent --all
	@Write-Host ""
	@Write-Host "update scoop..." $(COLOR_STEP)
	@Write-Host ""
	scoop update
	@Write-Host ""
	@Write-Host "update scoop done!" $(COLOR_DONE)
	@Write-Host ""
	@Write-Host "install new packages..." $(COLOR_STEP)
	@Write-Host ""
	winget import "$$HOME\ghq\github.com\yanosea\yanoNixFiles\ops\package-managers\winget\packages.json"
	@Write-Host ""
	@Write-Host "install new packages done!" $(COLOR_DONE)
	@Write-Host ""
	@Write-Host "update winget package list..." $(COLOR_STEP)
	@Write-Host ""
	winget export -o "$$HOME\ghq\github.com\yanosea\yanoNixFiles\ops\package-managers\winget\packages.json"
	Get-Content -Path "$$HOME\ghq\github.com\yanosea\yanoNixFiles\ops\package-managers\winget\packages.json" | jq '.Sources[].Packages |= sort_by(.PackageIdentifier | ascii_downcase)' | Set-Content -Path "$$HOME\ghq\github.com\yanosea\yanoNixFiles\ops\package-managers\winget\packages.json"
	@Write-Host ""
	@Write-Host "update winget package list done!" $(COLOR_DONE)
	@Write-Host ""
	@Write-Host "update done!" $(COLOR_DONE)
	@Write-Host ""
else
	@[ $(MAKELEVEL) -ne 0 ] || echo ""
	@echo "$(COLOR_ERROR)unsupported platform...$(COLOR_RESET)"
	@echo ""
endif

# apply system configuration
system:
ifeq ($(IS_NIXOS),1)
	@[ $(MAKELEVEL) -ne 0 ] || echo ""
	@echo "$(COLOR_TITLE)apply system configuration...$(COLOR_RESET)"
	@echo ""
	sudo nixos-rebuild switch --flake .#yanoNixOs
	@echo ""
	@echo "$(COLOR_DONE)apply system configuration done!$(COLOR_RESET)"
	@echo ""
else ifeq ($(IS_NIXOS_WSL),1)
	@[ $(MAKELEVEL) -ne 0 ] || echo ""
	@echo "$(COLOR_TITLE)apply system configuration...$(COLOR_RESET)"
	@echo ""
	sudo nixos-rebuild switch --flake .#yanoNixOsWsl
	@echo ""
	@echo "$(COLOR_DONE)apply system configuration done!$(COLOR_RESET)"
	@echo ""
else ifeq ($(IS_MAC),1)
	@[ $(MAKELEVEL) -ne 0 ] || echo ""
	@echo "$(COLOR_TITLE)apply system configuration...$(COLOR_RESET)"
	@echo ""
	sudo darwin-rebuild switch --flake .#yanoMac
	@echo ""
	@echo "$(COLOR_DONE)apply system configuration done!$(COLOR_RESET)"
	@echo ""
else ifeq ($(IS_MACBOOK),1)
	@[ $(MAKELEVEL) -ne 0 ] || echo ""
	@echo "$(COLOR_TITLE)apply system configuration...$(COLOR_RESET)"
	@echo ""
	sudo darwin-rebuild switch --flake .#yanoMacBook
	@echo ""
	@echo "$(COLOR_DONE)apply system configuration done!$(COLOR_RESET)"
	@echo ""
else
	@[ $(MAKELEVEL) -ne 0 ] || echo ""
	@echo "$(COLOR_ERROR)unsupported platform...$(COLOR_RESET)"
	@echo ""
endif

# apply home configuration
home:
ifeq ($(IS_NIXOS),1)
	@[ $(MAKELEVEL) -ne 0 ] || echo ""
	@echo "$(COLOR_TITLE)apply home configuration...$(COLOR_RESET)"
	@echo ""
	rm -fr $$HOME/.config/claude/CLAUDE.md
	rm -fr $$HOME/.config/fcitx5/config
	rm -fr $$HOME/.config/fcitx5/profile
	nix run .#homeConfigurations."yanosea@yanoNixOs".activationPackage
	@echo ""
	@echo "$(COLOR_DONE)apply home configuration done!$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_HEADER)hint: run 'reload' or 'exec zsh' to apply shell changes$(COLOR_RESET)"
	@echo ""
else ifeq ($(IS_NIXOS_WSL),1)
	@[ $(MAKELEVEL) -ne 0 ] || echo ""
	@echo "$(COLOR_TITLE)apply home configuration...$(COLOR_RESET)"
	@echo ""
	rm -fr $$HOME/.config/claude/CLAUDE.md
	nix run .#homeConfigurations."yanosea@yanoNixOsWsl".activationPackage
	@echo ""
	@echo "$(COLOR_DONE)apply home configuration done!$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_HEADER)hint: run 'reload' or 'exec zsh' to apply shell changes$(COLOR_RESET)"
	@echo ""
else ifeq ($(IS_MAC),1)
	@[ $(MAKELEVEL) -ne 0 ] || echo ""
	@echo "$(COLOR_TITLE)apply home configuration...$(COLOR_RESET)"
	@echo ""
	rm $$HOME/.config/AquaSKK/DictionarySet.plist
	rm $$HOME/.config/AquaSKK/BlacklistApps.plist
	rm -fr $$HOME/.config/claude/CLAUDE.md
	nix run .#homeConfigurations."yanosea@yanoMac".activationPackage
	@echo ""
	@echo "$(COLOR_DONE)apply home configuration done!$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_HEADER)hint: run 'reload' or 'exec zsh' to apply shell changes$(COLOR_RESET)"
	@echo ""
else ifeq ($(IS_MACBOOK),1)
	@[ $(MAKELEVEL) -ne 0 ] || echo ""
	@echo "$(COLOR_TITLE)apply home configuration...$(COLOR_RESET)"
	@echo ""
	rm $$HOME/.config/AquaSKK/DictionarySet.plist
	rm $$HOME/.config/AquaSKK/BlacklistApps.plist
	rm -fr $$HOME/.config/claude/CLAUDE.md
	nix run .#homeConfigurations."yanosea@yanoMacBook".activationPackage
	@echo ""
	@echo "$(COLOR_DONE)apply home configuration done!$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_HEADER)hint: run 'reload' or 'exec zsh' to apply shell changes$(COLOR_RESET)"
	@echo ""
else
	@[ $(MAKELEVEL) -ne 0 ] || echo ""
	@echo "$(COLOR_ERROR)unsupported platform...$(COLOR_RESET)"
	@echo ""
endif

# experimental update (time-consuming sync operations are disabled)
experiment:
ifeq ($(IS_NIXOS),1)
	@[ $(MAKELEVEL) -ne 0 ] || echo ""
	@echo "$(COLOR_TITLE)update nixos experimentally...$(COLOR_RESET)"
	@echo ""
	make system
	@echo "$(COLOR_TITLE)apply home configuration experimentally...$(COLOR_RESET)"
	@echo ""
	rm -fr $$HOME/.config/claude/CLAUDE.md
	rm -fr $$HOME/.config/fcitx5/config
	rm -fr $$HOME/.config/fcitx5/profile
	EXPERIMENTAL_MODE=1 nix run --impure .#homeConfigurations."yanosea@yanoNixOs".activationPackage
	@echo ""
	@echo "$(COLOR_DONE)apply home configuration experimentally done!$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_DONE)experimental update done!$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_HEADER)hint: run 'reload' or 'exec zsh' to apply shell changes$(COLOR_RESET)"
	@echo ""
else ifeq ($(IS_NIXOS_WSL),1)
	@[ $(MAKELEVEL) -ne 0 ] || echo ""
	@echo "$(COLOR_TITLE)update nixos wsl experimentally...$(COLOR_RESET)"
	@echo ""
	make system
	@echo "$(COLOR_TITLE)apply home configuration experimentally...$(COLOR_RESET)"
	@echo ""
	rm -fr $$HOME/.config/claude/CLAUDE.md
	EXPERIMENTAL_MODE=1 nix run --impure .#homeConfigurations."yanosea@yanoNixOsWsl".activationPackage
	@echo ""
	@echo "$(COLOR_DONE)apply home configuration experimentally done!$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_DONE)experimental update done!$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_HEADER)hint: run 'reload' or 'exec zsh' to apply shell changes$(COLOR_RESET)"
	@echo ""
else ifeq ($(IS_MAC),1)
	@[ $(MAKELEVEL) -ne 0 ] || echo ""
	@echo "$(COLOR_TITLE)update mac experimentally...$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_TITLE)upgrade nix...$(COLOR_RESET)"
	@echo ""
	sudo determinate-nixd upgrade
	@echo ""
	@echo "$(COLOR_DONE)upgrade nix done!$(COLOR_RESET)"
	@echo ""
	make system
	@echo "$(COLOR_TITLE)apply home configuration experimentally...$(COLOR_RESET)"
	@echo ""
	rm $$HOME/.config/AquaSKK/DictionarySet.plist
	rm $$HOME/.config/AquaSKK/BlacklistApps.plist
	rm -fr $$HOME/.config/claude/CLAUDE.md
	EXPERIMENTAL_MODE=1 nix run --impure .#homeConfigurations."yanosea@yanoMac".activationPackage
	@echo ""
	@echo "$(COLOR_DONE)apply home configuration experimentally done!$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_DONE)experimental update done!$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_HEADER)hint: run 'reload' or 'exec zsh' to apply shell changes$(COLOR_RESET)"
	@echo ""
else ifeq ($(IS_MACBOOK),1)
	@[ $(MAKELEVEL) -ne 0 ] || echo ""
	@echo "$(COLOR_TITLE)update macbook experimentally...$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_TITLE)upgrade nix...$(COLOR_RESET)"
	@echo ""
	sudo determinate-nixd upgrade
	@echo ""
	@echo "$(COLOR_DONE)upgrade nix done!$(COLOR_RESET)"
	@echo ""
	make system
	@echo "$(COLOR_TITLE)apply home configuration experimentally...$(COLOR_RESET)"
	@echo ""
	rm $$HOME/.config/AquaSKK/DictionarySet.plist
	rm $$HOME/.config/AquaSKK/BlacklistApps.plist
	rm -fr $$HOME/.config/claude/CLAUDE.md
	EXPERIMENTAL_MODE=1 nix run --impure .#homeConfigurations."yanosea@yanoMacBook".activationPackage
	@echo ""
	@echo "$(COLOR_DONE)apply home configuration experimentally done!$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_DONE)experimental update done!$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_HEADER)hint: run 'reload' or 'exec zsh' to apply shell changes$(COLOR_RESET)"
	@echo ""
else
	@[ $(MAKELEVEL) -ne 0 ] || echo ""
	@echo "$(COLOR_ERROR)unsupported platform...$(COLOR_RESET)"
	@echo ""
endif

# nix format files (alias for nix.format)
format:
ifeq ($(IS_WINDOWS),0)
	@[ $(MAKELEVEL) -ne 0 ] || echo ""
	@echo "$(COLOR_TITLE)format files...$(COLOR_RESET)"
	@echo ""
	nix fmt
	@echo ""
	@echo "$(COLOR_DONE)format done!$(COLOR_RESET)"
	@echo ""
else
	@[ $(MAKELEVEL) -ne 0 ] || echo ""
	@echo "$(COLOR_ERROR)this target is only for non-windows...$(COLOR_RESET)"
	@echo ""
endif

# nix garbage collection (alias for nix.gc.system)
gc: gc.system

# nix garbage collection (system & user)
gc.system:
ifeq ($(IS_WINDOWS),0)
	@[ $(MAKELEVEL) -ne 0 ] || echo ""
	@echo "$(COLOR_TITLE)garbage collection (system & user)...$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_STEP)cleaning up system-wide packages...$(COLOR_RESET)"
	@echo ""
	sudo nix-collect-garbage --delete-old
	sudo -i nix profile wipe-history
	sudo -i nix store gc
	@echo ""
	@echo "$(COLOR_DONE)cleaning up system-wide packages done!$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_STEP)cleaning up user packages...$(COLOR_RESET)"
	@echo ""
	nix-collect-garbage --delete-old
	nix profile wipe-history
	nix store gc
	@echo ""
	@echo "$(COLOR_DONE)cleaning up user packages done!$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_DONE)garbage collection (system & user) done!$(COLOR_RESET)"
	@echo ""
else
	@[ $(MAKELEVEL) -ne 0 ] || echo ""
	@echo "$(COLOR_ERROR)this target is only for non-windows...$(COLOR_RESET)"
	@echo ""
endif

# nix garbage collection (user only)
gc.user:
ifeq ($(IS_WINDOWS),0)
	@[ $(MAKELEVEL) -ne 0 ] || echo ""
	@echo "$(COLOR_TITLE)garbage collection (user)...$(COLOR_RESET)"
	@echo ""
	nix profile wipe-history
	nix store gc
	@echo ""
	@echo "$(COLOR_DONE)garbage collection (user) done!$(COLOR_RESET)"
	@echo ""
else
	@[ $(MAKELEVEL) -ne 0 ] || echo ""
	@echo "$(COLOR_ERROR)this target is only for non-windows...$(COLOR_RESET)"
	@echo ""
endif

#
# universal targets
#
.PHONY: all test clean help

# all runs help
all: help

# test configuration (dry-run)
test:
ifeq ($(IS_NIXOS),1)
	@[ $(MAKELEVEL) -ne 0 ] || echo ""
	@echo "$(COLOR_TITLE)test nixos configuration...$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_STEP)check flake configuration...$(COLOR_RESET)"
	@echo ""
	nix flake check
	@echo ""
	@echo "$(COLOR_DONE)check flake configuration done!$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_STEP)validate system configuration syntax and dependencies...$(COLOR_RESET)"
	@echo ""
	nix eval .#nixosConfigurations.yanoNixOs.config.system.build.toplevel.drvPath --show-trace
	@echo ""
	@echo "$(COLOR_DONE)validate system configuration done!$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_STEP)validate home configuration syntax and dependencies...$(COLOR_RESET)"
	@echo ""
	nix eval .#homeConfigurations."yanosea@yanoNixOs".activationPackage.drvPath --show-trace
	@echo ""
	@echo "$(COLOR_DONE)validate home configuration done!$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_STEP)check system build dependencies without actual building...$(COLOR_RESET)"
	@echo ""
	nix build .#nixosConfigurations.yanoNixOs.config.system.build.toplevel --dry-run --show-trace
	@echo ""
	@echo "$(COLOR_DONE)check system build dependencies done!$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_STEP)check home build dependencies without actual building...$(COLOR_RESET)"
	@echo ""
	nix build .#homeConfigurations."yanosea@yanoNixOs".activationPackage --dry-run --show-trace
	@echo ""
	@echo "$(COLOR_DONE)check home build dependencies done!$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_DONE)test done!$(COLOR_RESET)"
	@echo ""
else ifeq ($(IS_NIXOS_WSL),1)
	@[ $(MAKELEVEL) -ne 0 ] || echo ""
	@echo "$(COLOR_TITLE)test nixos wsl configuration...$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_STEP)check flake configuration...$(COLOR_RESET)"
	@echo ""
	nix flake check
	@echo ""
	@echo "$(COLOR_DONE)check flake configuration done!$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_STEP)validate system configuration syntax and dependencies...$(COLOR_RESET)"
	@echo ""
	nix eval .#nixosConfigurations.yanoNixOsWsl.config.system.build.toplevel.drvPath --show-trace
	@echo ""
	@echo "$(COLOR_DONE)validate system configuration done!$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_STEP)validate home configuration syntax and dependencies...$(COLOR_RESET)"
	@echo ""
	nix eval .#homeConfigurations."yanosea@yanoNixOsWsl".activationPackage.drvPath --show-trace
	@echo ""
	@echo "$(COLOR_DONE)validate home configuration done!$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_STEP)check system build dependencies without actual building...$(COLOR_RESET)"
	@echo ""
	nix build .#nixosConfigurations.yanoNixOsWsl.config.system.build.toplevel --dry-run --show-trace
	@echo ""
	@echo "$(COLOR_DONE)check system build dependencies done!$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_STEP)check home build dependencies without actual building...$(COLOR_RESET)"
	@echo ""
	nix build .#homeConfigurations."yanosea@yanoNixOsWsl".activationPackage --dry-run --show-trace
	@echo ""
	@echo "$(COLOR_DONE)check home build dependencies done!$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_DONE)test done!$(COLOR_RESET)"
	@echo ""
else ifeq ($(IS_MAC),1)
	@[ $(MAKELEVEL) -ne 0 ] || echo ""
	@echo "$(COLOR_TITLE)test mac configuration...$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_STEP)check flake configuration...$(COLOR_RESET)"
	@echo ""
	nix flake check
	@echo ""
	@echo "$(COLOR_DONE)check flake configuration done!$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_STEP)validate system configuration syntax and dependencies...$(COLOR_RESET)"
	@echo ""
	nix eval .#darwinConfigurations.yanoMac.system.drvPath --show-trace
	@echo ""
	@echo "$(COLOR_DONE)validate system configuration done!$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_STEP)validate home configuration syntax and dependencies...$(COLOR_RESET)"
	@echo ""
	nix eval .#homeConfigurations."yanosea@yanoMac".activationPackage.drvPath --show-trace
	@echo ""
	@echo "$(COLOR_DONE)validate home configuration done!$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_STEP)check system build dependencies without actual building...$(COLOR_RESET)"
	@echo ""
	nix build .#darwinConfigurations.yanoMac.system --dry-run --show-trace
	@echo ""
	@echo "$(COLOR_DONE)check system build dependencies done!$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_STEP)check home build dependencies without actual building...$(COLOR_RESET)"
	@echo ""
	nix build .#homeConfigurations."yanosea@yanoMac".activationPackage --dry-run --show-trace
	@echo ""
	@echo "$(COLOR_DONE)check home build dependencies done!$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_DONE)test done!$(COLOR_RESET)"
	@echo ""
else ifeq ($(IS_MACBOOK),1)
	@[ $(MAKELEVEL) -ne 0 ] || echo ""
	@echo "$(COLOR_TITLE)test macbook configuration...$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_STEP)check flake configuration...$(COLOR_RESET)"
	@echo ""
	nix flake check
	@echo ""
	@echo "$(COLOR_DONE)check flake configuration done!$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_STEP)validate system configuration syntax and dependencies...$(COLOR_RESET)"
	@echo ""
	nix eval .#darwinConfigurations.yanoMacBook.system.drvPath --show-trace
	@echo ""
	@echo "$(COLOR_DONE)validate system configuration done!$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_STEP)validate home configuration syntax and dependencies...$(COLOR_RESET)"
	@echo ""
	nix eval .#homeConfigurations."yanosea@yanoMacBook".activationPackage.drvPath --show-trace
	@echo ""
	@echo "$(COLOR_DONE)validate home configuration done!$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_STEP)check system build dependencies without actual building...$(COLOR_RESET)"
	@echo ""
	nix build .#darwinConfigurations.yanoMacBook.system --dry-run --show-trace
	@echo ""
	@echo "$(COLOR_DONE)check system build dependencies done!$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_STEP)check home build dependencies without actual building...$(COLOR_RESET)"
	@echo ""
	nix build .#homeConfigurations."yanosea@yanoMacBook".activationPackage --dry-run --show-trace
	@echo ""
	@echo "$(COLOR_DONE)check home build dependencies done!$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_DONE)test done!$(COLOR_RESET)"
	@echo ""
else ifeq ($(IS_WINDOWS),1)
	@if ($(MAKELEVEL) -eq 0) { Write-Host "" }
	@Write-Host "test is not supported on windows..." $(COLOR_ERROR)
	@Write-Host ""
else
	@[ $(MAKELEVEL) -ne 0 ] || echo ""
	@echo "$(COLOR_ERROR)unsupported platform...$(COLOR_RESET)"
	@echo ""
endif

# clean removes result directory
clean:
ifeq ($(IS_WINDOWS),0)
	@[ $(MAKELEVEL) -ne 0 ] || echo ""
	@echo "$(COLOR_TITLE)clean result directory...$(COLOR_RESET)"
	@echo ""
	rm -fr result
	@echo "$(COLOR_DONE)clean done!$(COLOR_RESET)"
	@echo ""
else
	@[ $(MAKELEVEL) -ne 0 ] || echo ""
	@echo "$(COLOR_ERROR)this target is only for non-windows...$(COLOR_RESET)"
	@echo ""
endif

#
# initializing memos
#

# initialize nixos (these are notes for the initial environment construction)
# nixos.init:
# ifeq ($(IS_NIXOS),1)
# 	@echo ""
# 	@echo "$(COLOR_TITLE)initialize nixos...$(COLOR_RESET)"
# 	@echo ""
# 	make nixos.apply.system
# 	@echo ""
# 	make nixos.apply.home
# 	@echo ""
# 	@echo "$(COLOR_STEP)load zsh configuration...$(COLOR_RESET)"
# 	@echo ""
# 	source $$HOME/.config/zsh/.zshenv && source $$HOME/.config/zsh/.zshrc
# 	@echo ""
# 	@echo "$(COLOR_STEP)make necessary directories...$(COLOR_RESET)"
# 	@echo ""
# 	mkdir -p $$HOME/.local/bin
# 	mkdir -p $$XDG_DATA_HOME/skk
# 	mkdir -p $$XDG_STATE_HOME/skk
# 	mkdir -p $$XDG_STATE_HOME/zsh
# 	mkdir -p $$XDG_CONFIG_HOME/github-copilot
# 	mkdir -p $$XDG_CONFIG_HOME/wakatime
# 	@echo ""
# 	@echo "$(COLOR_STEP)set up google drive sync...$(COLOR_RESET)"
# 	@echo ""
# 	@echo "launch insync, log in with google account, set base folder to \$$HOME/google_drive"
# 	insync
# 	@echo ""
# 	@echo "$(COLOR_STEP)install skk dictionaries...$(COLOR_RESET)"
# 	@echo ""
# 	jisyo d
# 	@echo ""
# 	@echo "$(COLOR_STEP)install vimplug...$(COLOR_RESET)"
# 	@echo ""
# 	curl -fLo $$XDG_CONFIG_HOME/vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
# 	@echo ""
# 	@echo "$(COLOR_DONE)initialize done!$(COLOR_RESET)"
# 	@echo ""
# else
# 	@echo ""
# 	@echo "$(COLOR_ERROR)this target is only for nixos...$(COLOR_RESET)"
# 	@echo ""
# endif

# initialize nixos wsl (these are notes for the initial environment construction)
# nixoswsl.init:
# ifeq ($(IS_NIXOS_WSL),1)
# 	@echo ""
# 	@echo "$(COLOR_TITLE)initialize nixos wsl...$(COLOR_RESET)"
# 	@echo ""
# 	make nixoswsl.apply.system
# 	@echo ""
# 	make nixoswsl.apply.home
# 	@echo ""
# 	@echo "$(COLOR_STEP)load zsh configuration...$(COLOR_RESET)"
# 	@echo ""
# 	source $$HOME/.config/zsh/.zshenv && source $$HOME/.config/zsh/.zshrc
# 	@echo ""
# 	@echo "$(COLOR_STEP)make necessary directories...$(COLOR_RESET)"
# 	@echo ""
# 	mkdir -p $$HOME/.local/bin
# 	mkdir -p $$XDG_DATA_HOME/skk
# 	mkdir -p $$XDG_STATE_HOME/skk
# 	mkdir -p $$XDG_STATE_HOME/zsh
# 	mkdir -p $$XDG_CONFIG_HOME/github-copilot
# 	mkdir -p $$XDG_CONFIG_HOME/wakatime
# 	@echo ""
# 	@echo "$(COLOR_STEP)make necessary symbolic links...$(COLOR_RESET)"
# 	@echo ""
# 	ln -s <WINDOWS_WIN32YANK_PATH> $$HOME/.local/bin/win32yank.exe
# 	ln -s <WINDOWS_GOOGLE_DRIVE_PATH> $$HOME/google_drive
# 	ln -s <WINDOWS_HOME_PATH> $$HOME/windows_home
# 	@echo ""
# 	@echo "$(COLOR_STEP)install skk dictionaries...$(COLOR_RESET)"
# 	@echo ""
# 	jisyo d
# 	@echo ""
# 	@echo "$(COLOR_STEP)install vimplug...$(COLOR_RESET)"
# 	@echo ""
# 	curl -fLo $$XDG_CONFIG_HOME/vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
# 	@echo ""
# 	@echo "$(COLOR_DONE)initialize done!$(COLOR_RESET)"
# 	@echo ""
# else
# 	@echo ""
# 	@echo "$(COLOR_ERROR)this target is only for nixos wsl...$(COLOR_RESET)"
# 	@echo ""
# endif

# initialize mac (these are notes for the initial environment construction)
# mac.init:
# ifeq ($(IS_MAC),1)
# 	@echo ""
# 	@echo "$(COLOR_TITLE)initialize mac...$(COLOR_RESET)"
# 	@echo ""
# 	@echo "$(COLOR_STEP)install homebrew...$(COLOR_RESET)"
# 	@echo ""
# 	/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
# 	@echo ""
# 	make mac.apply.system
# 	@echo ""
# 	make mac.apply.home
# 	@echo ""
# 	@echo "$(COLOR_STEP)load zsh configuration...$(COLOR_RESET)"
# 	@echo ""
# 	source $$HOME/.config/zsh/.zshenv && source $$HOME/.config/zsh/.zshrc
# 	@echo ""
# 	@echo "$(COLOR_STEP)make necessary directories...$(COLOR_RESET)"
# 	@echo ""
# 	mkdir -p $$HOME/.local/bin
# 	mkdir -p $$XDG_DATA_HOME/skk
# 	mkdir -p $$XDG_STATE_HOME/skk
# 	mkdir -p $$XDG_STATE_HOME/zsh
# 	mkdir -p $$XDG_CONFIG_HOME/github-copilot
# 	mkdir -p $$XDG_CONFIG_HOME/wakatime
# 	@echo ""
# 	@echo "$(COLOR_STEP)install skk dictionaries...$(COLOR_RESET)"
# 	@echo ""
# 	jisyo d
# 	@echo ""
# 	@echo "$(COLOR_STEP)install vimplug...$(COLOR_RESET)"
# 	@echo ""
# 	curl -fLo $$XDG_CONFIG_HOME/vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
# 	@echo ""
# 	@echo "$(COLOR_DONE)initialize done!$(COLOR_RESET)"
# 	@echo ""
# else
# 	@echo ""
# 	@echo "$(COLOR_ERROR)this target is only for mac...$(COLOR_RESET)"
# 	@echo ""
# endif

# initialize macbook (these are notes for the initial environment construction)
# macbook.init:
# ifeq ($(IS_MACBOOK),1)
# 	@echo ""
# 	@echo "$(COLOR_TITLE)initialize macbook...$(COLOR_RESET)"
# 	@echo ""
# 	@echo "$(COLOR_STEP)install homebrew...$(COLOR_RESET)"
# 	@echo ""
# 	/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
# 	@echo ""
# 	make macbook.apply.system
# 	@echo ""
# 	make macbook.apply.home
# 	@echo ""
# 	@echo "$(COLOR_STEP)load zsh configuration...$(COLOR_RESET)"
# 	@echo ""
# 	source $$HOME/.config/zsh/.zshenv && source $$HOME/.config/zsh/.zshrc
# 	@echo ""
# 	@echo "$(COLOR_STEP)make necessary directories...$(COLOR_RESET)"
# 	@echo ""
# 	mkdir -p $$HOME/.local/bin
# 	mkdir -p $$XDG_DATA_HOME/skk
# 	mkdir -p $$XDG_STATE_HOME/skk
# 	mkdir -p $$XDG_STATE_HOME/zsh
# 	mkdir -p $$XDG_CONFIG_HOME/github-copilot
# 	mkdir -p $$XDG_CONFIG_HOME/wakatime
# 	@echo ""
# 	@echo "$(COLOR_STEP)install skk dictionaries...$(COLOR_RESET)"
# 	@echo ""
# 	jisyo d
# 	@echo ""
# 	@echo "$(COLOR_STEP)install vimplug...$(COLOR_RESET)"
# 	@echo ""
# 	curl -fLo $$XDG_CONFIG_HOME/vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
# 	@echo ""
# 	@echo "$(COLOR_DONE)initialize done!$(COLOR_RESET)"
# 	@echo ""
# else
# 	@echo ""
# 	@echo "$(COLOR_ERROR)this target is only for macbook...$(COLOR_RESET)"
# 	@echo ""
# endif

# initialize windows (these are notes for the initial environment construction)
# windows.init:
# ifeq ($(IS_WINDOWS),1)
# 	@Write-Host ""
# 	@Write-Host "initialize windows..." $(COLOR_TITLE)
# 	@Write-Host ""
# 	@Write-Host "install pwsh..." $(COLOR_HEADER)
# 	@Write-Host ""
# 	winget install Microsoft.PowerShell
# 	@Write-Host ""
# 	@Write-Host "install git..." $(COLOR_HEADER)
# 	@Write-Host ""
# 	winget install git
# 	@Write-Host ""
# 	@Write-Host "install scoop..." $(COLOR_HEADER)
# 	@Write-Host ""
# 	Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
# 	Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
# 	@Write-Host ""
# 	@Write-Host "install ghq..." $(COLOR_HEADER)
# 	@Write-Host ""
# 	scoop install ghq
# 	@Write-Host ""
# 	@Write-Host "install winget packages..." $(COLOR_HEADER)
# 	@Write-Host ""
# 	winget import "$$HOME\ghq\github.com\yanosea\yanoNixFiles\ops\package-managers\winget\packages.json"
# 	@Write-Host ""
# 	@Write-Host "initialize windows done!" $(COLOR_DONE)
# 	@Write-Host ""
# else
# 	@echo ""
# 	@echo "$(COLOR_ERROR)this target is only for windows...$(COLOR_RESET)"
# 	@echo ""
# endif

# help shows available targets
help:
ifeq ($(IS_WINDOWS),1)
	@if ($(MAKELEVEL) -eq 0) { Write-Host "" }
else
	@[ $(MAKELEVEL) -ne 0 ] || echo ""
endif
ifeq ($(IS_NIXOS),1)
	@echo "$(COLOR_HEADER)detected platform: NixOS$(COLOR_RESET)"
else ifeq ($(IS_NIXOS_WSL),1)
	@echo "$(COLOR_HEADER)detected platform: NixOS WSL$(COLOR_RESET)"
else ifeq ($(IS_MAC),1)
	@echo "$(COLOR_HEADER)detected platform: Mac$(COLOR_RESET)"
else ifeq ($(IS_MACBOOK),1)
	@echo "$(COLOR_HEADER)detected platform: MacBook$(COLOR_RESET)"
else ifeq ($(IS_WINDOWS),1)
	@Write-Host "detected platform: Windows" $(COLOR_HEADER)
else
	@echo "  $(COLOR_HEADER)detected platform: Unknown$(COLOR_RESET)"
endif
ifeq ($(IS_WINDOWS),0)
	@echo ""
	@echo "  $(COLOR_TITLE)available targets:$(COLOR_RESET)"
	@echo ""
	@echo "    $(COLOR_HEADER)[main operations]$(COLOR_RESET)"
	@echo "      $(COLOR_CMD)update$(COLOR_RESET)     - update whole system (settings, packages)"
	@echo "      $(COLOR_CMD)experiment$(COLOR_RESET) - experimental update (time-consuming sync operations are disabled)"
	@echo "      $(COLOR_CMD)system$(COLOR_RESET)     - apply system configuration"
	@echo "      $(COLOR_CMD)home$(COLOR_RESET)       - apply home configuration"
	@echo "      $(COLOR_CMD)format$(COLOR_RESET)     - format files"
	@echo "      $(COLOR_CMD)gc$(COLOR_RESET)         - garbage collection (system & user) [alias for gc.system]"
	@echo "      $(COLOR_CMD)gc.system$(COLOR_RESET)  - garbage collection (system & user)"
	@echo "      $(COLOR_CMD)gc.user$(COLOR_RESET)    - garbage collection (user only)"
else
	@Write-Host ""
	@Write-Host "  available targets:" $(COLOR_TITLE)
	@Write-Host ""
	@Write-Host "    [main operations]" $(COLOR_HEADER)
	@Write-Host "      update  - update whole system (settings, packages)" $(COLOR_CMD)
endif
ifeq ($(IS_WINDOWS),0)
	@echo ""
	@echo "    $(COLOR_HEADER)[universal]$(COLOR_RESET)"
	@echo "      $(COLOR_CMD)all$(COLOR_RESET)        - show this help message [alias for help]"
	@echo "      $(COLOR_CMD)test$(COLOR_RESET)       - test configuration (dry-run)"
	@echo "      $(COLOR_CMD)clean$(COLOR_RESET)      - remove result directory"
	@echo "      $(COLOR_CMD)help$(COLOR_RESET)       - show this help message"
else
	@Write-Host ""
	@Write-Host "    [universal]" $(COLOR_HEADER)
	@Write-Host "      all     - show this help message [alias for help]" $(COLOR_CMD)
	@Write-Host "      help    - show this help message" $(COLOR_CMD)
endif
