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
ifeq ($(IS_WINDOWS),1)
	COLOR_TITLE := -ForegroundColor Magenta
	COLOR_HEADER := -ForegroundColor Yellow
	COLOR_CMD := -ForegroundColor Cyan
	COLOR_DONE := -ForegroundColor Green
	COLOR_ERROR := -ForegroundColor Red
else
	COLOR_RESET  := $(shell tput sgr0)
	COLOR_TITLE  := $(shell tput setaf 5) # magenta
	COLOR_HEADER := $(shell tput setaf 3) # yellow
	COLOR_CMD    := $(shell tput setaf 6) # cyan
	COLOR_DONE   := $(shell tput setaf 2) # green
	COLOR_ERROR  := $(shell tput setaf 1) # red
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
.PHONY: update system home agents format gc gc.system gc.user

# update whole system (settings, packages)
update:
ifeq ($(IS_NIXOS),1)
	@echo "$(COLOR_TITLE)update nixos...$(COLOR_RESET)"
	@echo ""
	make system
	@echo ""
	make home
	@echo ""
	@echo "$(COLOR_DONE)update done!$(COLOR_RESET)"
else ifeq ($(IS_NIXOS_WSL),1)
	@echo "$(COLOR_TITLE)update nixos wsl...$(COLOR_RESET)"
	@echo ""
	make system
	@echo ""
	make home
	@echo ""
	@echo "$(COLOR_DONE)update done!$(COLOR_RESET)"
else ifeq ($(IS_MAC),1)
	@echo "$(COLOR_TITLE)update mac...$(COLOR_RESET)"
	@echo ""
	make system
	@echo ""
	make home
	@echo ""
	make agents
	@echo ""
	@echo "$(COLOR_DONE)update done!$(COLOR_RESET)"
else ifeq ($(IS_MACBOOK),1)
	@echo "$(COLOR_TITLE)update macbook...$(COLOR_RESET)"
	@echo ""
	make system
	@echo ""
	make home
	@echo ""
	make agents
	@echo ""
	@echo "$(COLOR_DONE)update done!$(COLOR_RESET)"
else ifeq ($(IS_WINDOWS),1)
	@Write-Host "update windows..." $(COLOR_TITLE)
	@Write-Host ""
	winget upgrade --silent --all
	@Write-Host ""
	@Write-Host "update scoop..." $(COLOR_HEADER)
	@Write-Host ""
	scoop update
	@Write-Host ""
	@Write-Host "install new packages..." $(COLOR_HEADER)
	@Write-Host ""
	winget import "$$HOME\ghq\github.com\yanosea\yanoNixFiles\ops\package-managers\winget\packages.json"
	@Write-Host ""
	@Write-Host "update winget package list..." $(COLOR_TITLE)
	@Write-Host ""
	winget export -o "$$HOME\ghq\github.com\yanosea\yanoNixFiles\ops\package-managers\winget\packages.json"
	Get-Content -Path "$$HOME\ghq\github.com\yanosea\yanoNixFiles\ops\package-managers\winget\packages.json" | jq '.Sources[].Packages |= sort_by(.PackageIdentifier | ascii_downcase)' | Set-Content -Path "$$HOME\ghq\github.com\yanosea\yanoNixFiles\ops\package-managers\winget\packages.json"
	@Write-Host ""
	@Write-Host "update done!" $(COLOR_DONE)
else
	@echo "$(COLOR_ERROR)unsupported platform...$(COLOR_RESET)"
endif

# apply system configuration
system:
ifeq ($(IS_NIXOS),1)
	@echo "$(COLOR_TITLE)apply system configuration...$(COLOR_RESET)"
	@echo ""
	sudo nixos-rebuild switch --flake .#yanoNixOs
	@echo ""
	@echo "$(COLOR_DONE)apply system configuration done!$(COLOR_RESET)"
else ifeq ($(IS_NIXOS_WSL),1)
	@echo "$(COLOR_TITLE)apply system configuration...$(COLOR_RESET)"
	@echo ""
	sudo nixos-rebuild switch --flake .#yanoNixOsWsl
	@echo ""
	@echo "$(COLOR_DONE)apply system configuration done!$(COLOR_RESET)"
else ifeq ($(IS_MAC),1)
	@echo "$(COLOR_TITLE)apply system configuration...$(COLOR_RESET)"
	@echo ""
	sudo darwin-rebuild switch --flake .#yanoMac
	@echo ""
	@echo "$(COLOR_DONE)apply system configuration done!$(COLOR_RESET)"
else ifeq ($(IS_MACBOOK),1)
	@echo "$(COLOR_TITLE)apply system configuration...$(COLOR_RESET)"
	@echo ""
	sudo darwin-rebuild switch --flake .#yanoMacBook
	@echo ""
	@echo "$(COLOR_DONE)apply system configuration done!$(COLOR_RESET)"
else ifeq ($(IS_WINDOWS),1)
	@Write-Host "system configuration is not supported on windows..." $(COLOR_ERROR)
else
	@echo "$(COLOR_ERROR)unsupported platform...$(COLOR_RESET)"
endif

# apply home configuration
home:
ifeq ($(IS_NIXOS),1)
	@echo "$(COLOR_TITLE)apply home configuration...$(COLOR_RESET)"
	@echo ""
	rm -fr $$HOME/.config/claude/CLAUDE.md
	rm -fr $$HOME/.config/fcitx5/config
	nix run .#homeConfigurations."yanosea@yanoNixOs".activationPackage
	@echo "$(COLOR_DONE)apply home configuration done!$(COLOR_RESET)"
else ifeq ($(IS_NIXOS_WSL),1)
	@echo "$(COLOR_TITLE)apply home configuration...$(COLOR_RESET)"
	@echo ""
	rm -fr $$HOME/.config/claude/CLAUDE.md
	nix run .#homeConfigurations."yanosea@yanoNixOsWsl".activationPackage
	@echo "$(COLOR_DONE)apply home configuration done!$(COLOR_RESET)"
else ifeq ($(IS_MAC),1)
	@echo "$(COLOR_TITLE)apply home configuration...$(COLOR_RESET)"
	@echo ""
	rm $$HOME/.config/AquaSKK/DictionarySet.plist
	rm $$HOME/.config/AquaSKK/BlacklistApps.plist
	rm -fr $$HOME/.config/claude/CLAUDE.md
	rm -fr $$HOME/.config/karabiner/karabiner.json
	nix run .#homeConfigurations."yanosea@yanoMac".activationPackage
	@echo "$(COLOR_DONE)apply home configuration done!$(COLOR_RESET)"
else ifeq ($(IS_MACBOOK),1)
	@echo "$(COLOR_TITLE)apply home configuration...$(COLOR_RESET)"
	@echo ""
	rm $$HOME/.config/AquaSKK/DictionarySet.plist
	rm $$HOME/.config/AquaSKK/BlacklistApps.plist
	rm -fr $$HOME/.config/claude/CLAUDE.md
	rm -fr $$HOME/.config/karabiner/karabiner.json
	nix run .#homeConfigurations."yanosea@yanoMacBook".activationPackage
	@echo "$(COLOR_DONE)apply home configuration done!$(COLOR_RESET)"
else ifeq ($(IS_WINDOWS),1)
	@Write-Host "home configuration is not supported on windows..." $(COLOR_ERROR)
else
	@echo "$(COLOR_ERROR)unsupported platform...$(COLOR_RESET)"
endif

# reload agents (darwin only)
agents:
ifeq ($(IS_DARWIN),1)
	@echo "$(COLOR_TITLE)reload darwin agents...$(COLOR_RESET)"
	@echo ""
	launchctl unload $$HOME/Library/LaunchAgents/org.nix-community.home.borders.plist
	launchctl load $$HOME/Library/LaunchAgents/org.nix-community.home.borders.plist
	launchctl unload $$HOME/Library/LaunchAgents/org.nix-community.home.sketchybar.plist
	launchctl load $$HOME/Library/LaunchAgents/org.nix-community.home.sketchybar.plist
	launchctl unload $$HOME/Library/LaunchAgents/org.nix-community.home.skhd.plist
	launchctl load $$HOME/Library/LaunchAgents/org.nix-community.home.skhd.plist
	launchctl unload $$HOME/Library/LaunchAgents/org.nix-community.home.yabai.plist
	launchctl load $$HOME/Library/LaunchAgents/org.nix-community.home.yabai.plist
	@echo "$(COLOR_DONE)reload done!$(COLOR_RESET)"
else
	@echo "$(COLOR_ERROR)this target is only for darwin...$(COLOR_RESET)"
endif

# nix format files (alias for nix.format)
format:
ifeq ($(IS_WINDOWS),0)
	@echo "$(COLOR_TITLE)format files...$(COLOR_RESET)"
	@echo ""
	nix fmt
	@echo ""
	@echo "$(COLOR_DONE)format done!$(COLOR_RESET)"
else
	@echo "$(COLOR_ERROR)this target is only for non-windows...$(COLOR_RESET)"
endif

# nix garbage collection (alias for nix.gc.system)
gc: gc.system

# nix garbage collection (system & user)
gc.system:
ifeq ($(IS_WINDOWS),0)
	@echo "$(COLOR_TITLE)garbage collection (system & user)...$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_HEADER)cleaning up system-wide packages...$(COLOR_RESET)"
	sudo nix-collect-garbage --delete-old
	sudo -i nix profile wipe-history
	sudo -i nix store gc
	@echo ""
	@echo "$(COLOR_HEADER)cleaning up user packages...$(COLOR_RESET)"
	nix-collect-garbage --delete-old
	nix profile wipe-history
	nix store gc
	@echo ""
	@echo "$(COLOR_DONE)garbage collection (system & user) done!$(COLOR_RESET)"
else
	@echo "$(COLOR_ERROR)this target is only for non-windows...$(COLOR_RESET)"
endif

# nix garbage collection (user only)
gc.user:
ifeq ($(IS_WINDOWS),0)
	@echo "$(COLOR_TITLE)garbage collection (user)...$(COLOR_RESET)"
	@echo ""
	nix profile wipe-history
	nix store gc
	@echo ""
	@echo "$(COLOR_DONE)garbage collection (user) done!$(COLOR_RESET)"
else
	@echo "$(COLOR_ERROR)this target is only for non-windows...$(COLOR_RESET)"
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
	@echo "$(COLOR_TITLE)test nixos configuration...$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_HEADER)check flake configuration...$(COLOR_RESET)"
	nix flake check
	@echo ""
	@echo "$(COLOR_HEADER)validate system configuration syntax and dependencies...$(COLOR_RESET)"
	nix eval .#nixosConfigurations.yanoNixOs.config.system.build.toplevel.drvPath --show-trace
	@echo ""
	@echo "$(COLOR_HEADER)validate home configuration syntax and dependencies...$(COLOR_RESET)"
	nix eval .#homeConfigurations."yanosea@yanoNixOs".activationPackage.drvPath --show-trace
	@echo ""
	@echo "$(COLOR_HEADER)check system build dependencies without actual building...$(COLOR_RESET)"
	nix build .#nixosConfigurations.yanoNixOs.config.system.build.toplevel --dry-run --show-trace
	@echo ""
	@echo "$(COLOR_HEADER)check home build dependencies without actual building...$(COLOR_RESET)"
	nix build .#homeConfigurations."yanosea@yanoNixOs".activationPackage --dry-run --show-trace
	@echo ""
	@echo "$(COLOR_DONE)test done!$(COLOR_RESET)"
else ifeq ($(IS_NIXOS_WSL),1)
	@echo "$(COLOR_TITLE)test nixos wsl configuration...$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_HEADER)check flake configuration...$(COLOR_RESET)"
	nix flake check
	@echo ""
	@echo "$(COLOR_HEADER)validate system configuration syntax and dependencies...$(COLOR_RESET)"
	nix eval .#nixosConfigurations.yanoNixOsWsl.config.system.build.toplevel.drvPath --show-trace
	@echo ""
	@echo "$(COLOR_HEADER)validate home configuration syntax and dependencies...$(COLOR_RESET)"
	nix eval .#homeConfigurations."yanosea@yanoNixOsWsl".activationPackage.drvPath --show-trace
	@echo ""
	@echo "$(COLOR_HEADER)check system build dependencies without actual building...$(COLOR_RESET)"
	nix build .#nixosConfigurations.yanoNixOsWsl.config.system.build.toplevel --dry-run --show-trace
	@echo ""
	@echo "$(COLOR_HEADER)check home build dependencies without actual building...$(COLOR_RESET)"
	nix build .#homeConfigurations."yanosea@yanoNixOsWsl".activationPackage --dry-run --show-trace
	@echo ""
	@echo "$(COLOR_DONE)test done!$(COLOR_RESET)"
else ifeq ($(IS_MAC),1)
	@echo "$(COLOR_TITLE)test mac configuration...$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_HEADER)check flake configuration...$(COLOR_RESET)"
	nix flake check
	@echo ""
	@echo "$(COLOR_HEADER)validate system configuration syntax and dependencies...$(COLOR_RESET)"
	nix eval .#darwinConfigurations.yanoMac.system.drvPath --show-trace
	@echo ""
	@echo "$(COLOR_HEADER)validate home configuration syntax and dependencies...$(COLOR_RESET)"
	nix eval .#homeConfigurations."yanosea@yanoMac".activationPackage.drvPath --show-trace
	@echo ""
	@echo "$(COLOR_HEADER)check system build dependencies without actual building...$(COLOR_RESET)"
	nix build .#darwinConfigurations.yanoMac.system --dry-run --show-trace
	@echo ""
	@echo "$(COLOR_HEADER)check home build dependencies without actual building...$(COLOR_RESET)"
	nix build .#homeConfigurations."yanosea@yanoMac".activationPackage --dry-run --show-trace
	@echo ""
	@echo "$(COLOR_DONE)test done!$(COLOR_RESET)"
else ifeq ($(IS_MACBOOK),1)
	@echo "$(COLOR_TITLE)test macbook configuration...$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_HEADER)check flake configuration...$(COLOR_RESET)"
	nix flake check
	@echo ""
	@echo "$(COLOR_HEADER)validate system configuration syntax and dependencies...$(COLOR_RESET)"
	nix eval .#darwinConfigurations.yanoMacBook.system.drvPath --show-trace
	@echo ""
	@echo "$(COLOR_HEADER)validate home configuration syntax and dependencies...$(COLOR_RESET)"
	nix eval .#homeConfigurations."yanosea@yanoMacBook".activationPackage.drvPath --show-trace
	@echo ""
	@echo "$(COLOR_HEADER)check system build dependencies without actual building...$(COLOR_RESET)"
	nix build .#darwinConfigurations.yanoMacBook.system --dry-run --show-trace
	@echo ""
	@echo "$(COLOR_HEADER)check home build dependencies without actual building...$(COLOR_RESET)"
	nix build .#homeConfigurations."yanosea@yanoMacBook".activationPackage --dry-run --show-trace
	@echo ""
	@echo "$(COLOR_DONE)test done!$(COLOR_RESET)"
else ifeq ($(IS_WINDOWS),1)
	@Write-Host "test is not supported on windows..." $(COLOR_ERROR)
else
	@echo "$(COLOR_ERROR)unsupported platform...$(COLOR_RESET)"
endif

# clean removes result directory
clean:
ifeq ($(IS_WINDOWS),0)
	@echo "$(COLOR_TITLE)clean result directory...$(COLOR_RESET)"
	@echo ""
	rm -fr result
	@echo "$(COLOR_DONE)clean done!$(COLOR_RESET)"
else
	@echo "$(COLOR_ERROR)this target is only for non-windows...$(COLOR_RESET)"
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
# 	@echo "$(COLOR_HEADER)load zsh configuration...$(COLOR_RESET)"
# 	@echo ""
# 	source $$HOME/.config/zsh/.zshenv && source $$HOME/.config/zsh/.zshrc
# 	@echo ""
# 	@echo "$(COLOR_HEADER)make necessary directories...$(COLOR_RESET)"
# 	@echo ""
# 	mkdir -p $$HOME/.local/bin
# 	mkdir -p $$XDG_DATA_HOME/skk
# 	mkdir -p $$XDG_STATE_HOME/skk
# 	mkdir -p $$XDG_STATE_HOME/zsh
# 	mkdir -p $$XDG_CONFIG_HOME/github-copilot
# 	mkdir -p $$XDG_CONFIG_HOME/wakatime
# 	@echo ""
# 	@echo "$(COLOR_HEADER)initialize rclone...$(COLOR_RESET)"
# 	@echo ""
# 	rclone config
# 	@echo ""
# 	@echo "$(COLOR_HEADER)install skk dictionaries...$(COLOR_RESET)"
# 	@echo ""
# 	jisyo d
# 	@echo ""
# 	@echo "$(COLOR_HEADER)install vimplug...$(COLOR_RESET)"
# 	@echo ""
# 	curl -fLo $$HOME/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
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
# 	@echo "$(COLOR_HEADER)load zsh configuration...$(COLOR_RESET)"
# 	@echo ""
# 	source $$HOME/.config/zsh/.zshenv && source $$HOME/.config/zsh/.zshrc
# 	@echo ""
# 	@echo "$(COLOR_HEADER)make necessary directories...$(COLOR_RESET)"
# 	@echo ""
# 	mkdir -p $$HOME/.local/bin
# 	mkdir -p $$XDG_DATA_HOME/skk
# 	mkdir -p $$XDG_STATE_HOME/skk
# 	mkdir -p $$XDG_STATE_HOME/zsh
# 	mkdir -p $$XDG_CONFIG_HOME/github-copilot
# 	mkdir -p $$XDG_CONFIG_HOME/wakatime
# 	@echo ""
# 	@echo "$(COLOR_HEADER)make necessary symbolic links...$(COLOR_RESET)"
# 	@echo ""
# 	ln -s <WINDOWS_WIN32YANK_PATH> $$HOME/.local/bin/win32yank.exe
# 	ln -s <WINDOWS_GOOGLE_DRIVE_PATH> $$HOME/google_drive
# 	ln -s <WINDOWS_HOME_PATH> $$HOME/windows_home
# 	@echo ""
# 	@echo "$(COLOR_HEADER)install skk dictionaries...$(COLOR_RESET)"
# 	@echo ""
# 	jisyo d
# 	@echo ""
# 	@echo "$(COLOR_HEADER)install vimplug...$(COLOR_RESET)"
# 	@echo ""
# 	curl -fLo $$HOME/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
# 	@echo ""
# 	@echo "$(COLOR_DONE)initialize done!$(COLOR_RESET)"
# 	@echo ""
# else
# 	@echo ""
# 	@echo "$(COLOR_ERROR)this target is only for nixos wsl...$(COLOR_RESET)"
# 	@echo ""
# endif

# initialize mac (these are notes for the initial environment construction)
mac.init:
# ifeq ($(IS_MAC),1)
# 	@echo ""
# 	@echo "$(COLOR_TITLE)initialize mac...$(COLOR_RESET)"
# 	@echo ""
# 	@echo "$(COLOR_HEADER)install homebrew...$(COLOR_RESET)"
# 	@echo ""
# 	/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
# 	@echo ""
# 	make mac.apply.system
# 	@echo ""
# 	make mac.apply.home
# 	@echo ""
# 	@echo "$(COLOR_HEADER)load zsh configuration...$(COLOR_RESET)"
# 	@echo ""
# 	source $$HOME/.config/zsh/.zshenv && source $$HOME/.config/zsh/.zshrc
# 	@echo ""
# 	@echo "$(COLOR_HEADER)make necessary directories...$(COLOR_RESET)"
# 	@echo ""
# 	mkdir -p $$HOME/.local/bin
# 	mkdir -p $$XDG_DATA_HOME/skk
# 	mkdir -p $$XDG_STATE_HOME/skk
# 	mkdir -p $$XDG_STATE_HOME/zsh
# 	mkdir -p $$XDG_CONFIG_HOME/github-copilot
# 	mkdir -p $$XDG_CONFIG_HOME/wakatime
# 	@echo ""
# 	@echo "$(COLOR_HEADER)install skk dictionaries...$(COLOR_RESET)"
# 	@echo ""
# 	jisyo d
# 	@echo ""
# 	@echo "$(COLOR_HEADER)install vimplug...$(COLOR_RESET)"
# 	@echo ""
# 	curl -fLo $$HOME/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
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
# 	@echo "$(COLOR_HEADER)install homebrew...$(COLOR_RESET)"
# 	@echo ""
# 	/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
# 	@echo ""
# 	make macbook.apply.system
# 	@echo ""
# 	make macbook.apply.home
# 	@echo ""
# 	@echo "$(COLOR_HEADER)load zsh configuration...$(COLOR_RESET)"
# 	@echo ""
# 	source $$HOME/.config/zsh/.zshenv && source $$HOME/.config/zsh/.zshrc
# 	@echo ""
# 	@echo "$(COLOR_HEADER)make necessary directories...$(COLOR_RESET)"
# 	@echo ""
# 	mkdir -p $$HOME/.local/bin
# 	mkdir -p $$XDG_DATA_HOME/skk
# 	mkdir -p $$XDG_STATE_HOME/skk
# 	mkdir -p $$XDG_STATE_HOME/zsh
# 	mkdir -p $$XDG_CONFIG_HOME/github-copilot
# 	mkdir -p $$XDG_CONFIG_HOME/wakatime
# 	@echo ""
# 	@echo "$(COLOR_HEADER)install skk dictionaries...$(COLOR_RESET)"
# 	@echo ""
# 	jisyo d
# 	@echo ""
# 	@echo "$(COLOR_HEADER)install vimplug...$(COLOR_RESET)"
# 	@echo ""
# 	curl -fLo $$HOME/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
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
ifeq ($(IS_DARWIN),1)
	@echo "      $(COLOR_CMD)agents$(COLOR_RESET)     - reload darwin agents"
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
