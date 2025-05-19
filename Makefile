# check if windows
ifeq ($(OS),Windows_NT)
  IS_WINDOWS := 1
else
  IS_WINDOWS := 0
endif

# define colors
ifeq ($(IS_WINDOWS),0)
	COLOR_RESET  := $(shell tput sgr0)
	COLOR_TITLE  := $(shell tput setaf 5)$(shell tput bold) # magenta, bold
	COLOR_HEADER := $(shell tput setaf 3)$(shell tput bold) # yellow, bold
	COLOR_CMD    := $(shell tput setaf 6)$(shell tput bold) # cyan, bold
	COLOR_DONE   := $(shell tput setaf 2)$(shell tput bold) # green, bold
endif

# shows help message defaultly
.DEFAULT_GOAL := help

#
# nixos
#
.PHONY: nix.init nix.install nix.update nix.apply.system nix.apply.home

# initialize nixos
nix.init:
	@echo "$(COLOR_TITLE)initialize nixos...$(COLOR_RESET)"
	@echo "$(COLOR_HEADER)initialize system...$(COLOR_RESET)"
	make nix.apply.system
	@echo "$(COLOR_HEADER)initialize home...$(COLOR_RESET)"
	make nix.apply.home
	@echo "$(COLOR_HEADER)load zsh configuration...$(COLOR_RESET)"
	source $$HOME/.config/zsh/.zshenv && source $$HOME/.config/zsh/.zshrc
	@echo "$(COLOR_HEADER)make necessary directories...$(COLOR_RESET)"
	mkdir -p $$HOME/.local/bin
	mkdir -p $$XDG_DATA_HOME/skk
	mkdir -p $$XDG_STATE_HOME/skk
	mkdir -p $$XDG_STATE_HOME/zsh
	mkdir -p $$XDG_CONFIG_HOME/wakatime
	@echo "$(COLOR_HEADER)initialize rclone...$(COLOR_RESET)"
	sudo mkdir -p /mnt/google_drive/yanosea
	sudo rclone config
	@echo "$(COLOR_HEADER)make necessary symbolic links...$(COLOR_RESET)"
	sudo ln -s /root/.config/rclone/rclone.conf /.rclone.conf
	ln -s $$HOME/ghq/github.com/yanosea/yanoNixFiles/scripts/utils/nixos/clipboard-history $$HOME/.local/bin/clipboard-history
	ln -s $$HOME/ghq/github.com/yanosea/yanoNixFiles/scripts/utils/nixos/ime $$HOME/.local/bin/ime
	ln -s $$HOME/ghq/github.com/yanosea/yanoNixFiles/scripts/utils/common/installGitEmojiPrefixTemplate $$HOME/.local/bin/installGitEmojiPrefixTemplate
	ln -s /mnt/google_drive/yanosea $$HOME/google_drive
	ln -s $$HOME/google_drive/credentials $$XDG_DATA_HOME/credentials
	ln -s $$XDG_DATA_HOME/credentials/github-copilot/apps.json $$XDG_CONFIG_HOME/github-copilot/apps.json
	ln -s $$XDG_DATA_HOME/credentials/wakatime/.wakatime.cfg $$XDG_CONFIG_HOME/wakatime/.wakatime.cfg
	ln -s $$XDG_CONFIG_HOME/vim $$HOME/.vim
	@echo "$(COLOR_HEADER)clone ghq repos...$(COLOR_RESET)"
	xargs -I arg ghq get arg <$$HOME/ghq/github.com/yanosea/yanoNixFiles/pkglist/ghq/pkglist.txt
	@echo "$(COLOR_HEADER)install go packages...$(COLOR_RESET)"
	xargs -I arg go install arg <$$HOME/ghq/github.com/yanosea/yanoNixFiles/pkglist/go/pkglist.txt
	@echo "$(COLOR_HEADER)install skk jisyos...$(COLOR_RESET)"
	jisyo d
	@echo "$(COLOR_HEADER)install vimplug...$(COLOR_RESET)"
	curl -fLo $$HOME/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
	@echo "$(COLOR_DONE)initialize done!$(COLOR_RESET)"

# install shortage packages on nixos and apply configurations
nix.install:
	@echo "$(COLOR_TITLE)install shortage packages...$(COLOR_RESET)"
	@echo "$(COLOR_HEADER)clone ghq shortage repos...$(COLOR_RESET)"
	xargs -I arg ghq get arg <$$HOME/ghq/github.com/yanosea/yanoNixFiles/pkglist/ghq/pkglist.txt
	@echo "$(COLOR_HEADER)install go shortage packages...$(COLOR_RESET)"
	xargs -I arg go install arg <$$HOME/ghq/github.com/yanosea/yanoNixFiles/pkglist/go/pkglist.txt
	@echo "$(COLOR_HEADER)apply system configuration...$(COLOR_RESET)"
	make nix.apply.system
	@echo "$(COLOR_HEADER)apply home configuration...$(COLOR_RESET)"
	make nix.apply.home
	@echo "$(COLOR_DONE)install shortage packages done!$(COLOR_RESET)"

# update nixos packages and apply configurations
nix.update:
	@echo "$(COLOR_TITLE)update nixos...$(COLOR_RESET)"
	@echo "$(COLOR_HEADER)sync ghq repos...$(COLOR_RESET)"
	ghq list | ghq get --update
	@echo "$(COLOR_HEADER)update go packages...$(COLOR_RESET)"
	gup update
	@echo "$(COLOR_HEADER)update zsh plugins...$(COLOR_RESET)"
	sheldon lock --update
	@echo "$(COLOR_HEADER)update nix...$(COLOR_RESET)"
	nix-env -u
	@echo "$(COLOR_HEADER)install new packages...$(COLOR_RESET)"
	make nix.install
	@echo "$(COLOR_DONE)update done!$(COLOR_RESET)"

# apply system configuration
nix.apply.system:
	@echo "$(COLOR_TITLE)apply system configuration...$(COLOR_RESET)"
	sudo nixos-rebuild switch --flake .#yanoNixOs
	@echo "$(COLOR_HEADER)apply system configuration done!$(COLOR_RESET)"

# apply home configuration
nix.apply.home:
	@echo "$(COLOR_TITLE)apply home configuration...$(COLOR_RESET)"
	home-manager switch --flake .#yanosea@yanoNixOs
	@echo "$(COLOR_DONE)apply home configuration done!$(COLOR_RESET)"

#
# nixos wsl
#
.PHONY: wsl.init wsl.install wsl.update wsl.apply.system wsl.apply.home

# initialize nixos wsl
wsl.init:
	@echo "$(COLOR_TITLE)initialize nixos wsl...$(COLOR_RESET)"
	@echo "$(COLOR_HEADER)initialize system...$(COLOR_RESET)"
	make wsl.apply.system
	make wsl.apply.home
	source $$HOME/.config/zsh/.zshenv && source $$HOME/.config/zsh/.zshrc
	mkdir -p $$XDG_DATA_HOME/skk
	mkdir -p $$XDG_STATE_HOME/skk
	mkdir -p $$XDG_STATE_HOME/zsh
	mkdir -p $$XDG_CONFIG_HOME/wakatime
	@echo "$(COLOR_HEADER)make necessary symbolic links...$(COLOR_RESET)"
	ln -s $$HOME/ghq/github.com/yanosea/yanoNixFiles/scripts/utils/common/installGitEmojiPrefixTemplate $$HOME/.local/bin/installGitEmojiPrefixTemplate
	ln -s $$HOME/.config/vim $$HOME/.vim
	@echo "$(COLOR_HEADER)clone ghq repos...$(COLOR_RESET)"
	xargs -I arg ghq get arg <$$HOME/ghq/github.com/yanosea/yanoNixFiles/pkglist/ghq/pkglist.txt
	@echo "$(COLOR_HEADER)install go packages...$(COLOR_RESET)"
	xargs -I arg go install arg <$$HOME/ghq/github.com/yanosea/yanoNixFiles/pkglist/go/pkglist.txt
	@echo "$(COLOR_HEADER)install skk jisyos...$(COLOR_RESET)"
	jisyo d
	@echo "$(COLOR_HEADER)install vimplug...$(COLOR_RESET)"
	curl -fLo $$HOME/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
	@echo "$(COLOR_HEADER)You have to create google drive symbolic link like below...$(COLOR_RESET)"
	@echo "$(COLOR_CMD)ln -s GOOGLE_DRIVE_PATH $$HOME/google_drive$(COLOR_RESET)"
	@echo "$(COLOR_HEADER)You have to create credentials symbolic link like below...$(COLOR_RESET)"
	@echo "$(COLOR_CMD)ln -s $$HOME/google_drive/credentials $$XDG_DATA_HOME/credentials$(COLOR_RESET)"
	@echo "$(COLOR_CMD)ln -s $$XDG_DATA_HOME/credentials/github-copilot/apps.json $$XDG_CONFIG_HOME/github-copilot/apps.json$(COLOR_RESET)"
	@echo "$(COLOR_CMD)ln -s $$XDG_DATA_HOME/credentials/wakatime/.wakatime.cfg $$XDG_CONFIG_HOME/wakatime/.wakatime.cfg$(COLOR_RESET)"
	@echo "$(COLOR_HEADER)You have to create windows home symbolic link like below...$(COLOR_RESET)"
	@echo "$(COLOR_CMD)ln -s WINDOWS_HOME_PATH $$HOME/windows_home/$(COLOR_RESET)"
	@echo "$(COLOR_HEADER)You have to create win32yank symbolic link like below...$(COLOR_RESET)"
	@echo "$(COLOR_CMD)ln -s WINDOWS_WIN32YANK_PATH $$HOME/.local/bin/win32yank.exe$(COLOR_RESET)"
	@echo "$(COLOR_DONE)initialize done!$(COLOR_RESET)"

# install shortage packages on nixos wsl and apply configurations
wsl.install:
	@echo "$(COLOR_TITLE)install shortage packages...$(COLOR_RESET)"
	@echo "$(COLOR_HEADER)clone ghq shortage repos...$(COLOR_RESET)"
	xargs -I arg ghq get arg <$$HOME/ghq/github.com/yanosea/yanoNixFiles/pkglist/ghq/pkglist.txt
	@echo "$(COLOR_HEADER)install go shortage packages...$(COLOR_RESET)"
	xargs -I arg go install arg <$$HOME/ghq/github.com/yanosea/yanoNixFiles/pkglist/go/pkglist.txt
	@echo "$(COLOR_HEADER)apply nix...$(COLOR_RESET)"
	make wsl.apply.system
	@echo "$(COLOR_HEADER)apply home...$(COLOR_RESET)"
	make wsl.apply.home
	@echo "$(COLOR_DONE)install shortage packages done!$(COLOR_RESET)"

# update nixos wsl packages and apply configurations
wsl.update:
	@echo "$(COLOR_TITLE)update nixos wsl...$(COLOR_RESET)"
	@echo "$(COLOR_HEADER)sync ghq repos...$(COLOR_RESET)"
	ghq list | ghq get --update
	@echo "$(COLOR_HEADER)update go packages...$(COLOR_RESET)"
	gup update
	@echo "$(COLOR_HEADER)update zsh plugins...$(COLOR_RESET)"
	sheldon lock --update
	@echo "$(COLOR_HEADER)update nix...$(COLOR_RESET)"
	nix-env -u
	@echo "$(COLOR_HEADER)install new packages...$(COLOR_RESET)"
	make wsl.install
	@echo "$(COLOR_DONE)update done!$(COLOR_RESET)"

# apply system configuration
wsl.apply.system:
	@echo "$(COLOR_TITLE)apply system configuration...$(COLOR_RESET)"
	sudo nixos-rebuild switch --flake .#yanoNixOsWsl
	@echo "$(COLOR_DONE)apply system configuration done!$(COLOR_RESET)"

# apply home configuration
wsl.apply.home:
	@echo "$(COLOR_TITLE)apply home configuration...$(COLOR_RESET)"
	home-manager switch --flake .#yanosea@yanoNixOsWsl
	@echo "$(COLOR_DONE)apply home configuration done!$(COLOR_RESET)"

# darwin
.PHONY: darwin.init darwin.install darwin.update darwin.update.brewpkglist darwin.restart.services darwin.apply.system darwin.apply.home

# initialize nix darwin
darwin.init:
	@echo "$(COLOR_TITLE)initialize nix darwin...$(COLOR_RESET)"
	@echo "$(COLOR_HEADER)initialize system...$(COLOR_RESET)"
	make darwin.apply.system
	@echo "$(COLOR_HEADER)initialize home...$(COLOR_RESET)"
	make darwin.apply.home
	@echo "$(COLOR_HEADER)load zsh configuration...$(COLOR_RESET)"
	source $$HOME/.config/zsh/.zshenv && source $$HOME/.config/zsh/.zshrc
	@echo "$(COLOR_HEADER)make necessary directories...$(COLOR_RESET)"
	mkdir -p $$HOME/.local/bin
	mkdir -p $$XDG_DATA_HOME/skk
	mkdir -p $$XDG_STATE_HOME/skk
	mkdir -p $$XDG_STATE_HOME/zsh
	mkdir -p $$XDG_CONFIG_HOME/wakatime
	@echo "$(COLOR_HEADER)make necessary symbolic links...$(COLOR_RESET)"
	ln -s $$HOME/ghq/github.com/yanosea/yanoNixFiles/scripts/utils/common/installGitEmojiPrefixTemplate $$HOME/.local/bin/installGitEmojiPrefixTemplate
	ln -s $$HOME/.config/vim $$HOME/.vim
	@echo "$(COLOR_HEADER)clone ghq repos...$(COLOR_RESET)"
	xargs -I arg ghq get arg <$$HOME/ghq/github.com/yanosea/yanoNixFiles/pkglist/ghq/pkglist.txt
	@echo "$(COLOR_HEADER)install go packages...$(COLOR_RESET)"
	xargs -I arg go install arg <$$HOME/ghq/github.com/yanosea/yanoNixFiles/pkglist/go/pkglist.txt
	@echo "$(COLOR_HEADER)install brew pkgs...$(COLOR_RESET)"
	xargs brew install <$$HOME/ghq/github.com/yanosea/yanoNixFiles/pkglist/brew/pkglist.txt
	@echo "$(COLOR_HEADER)install skk dictionary...$(COLOR_RESET)"
	jisyo d
	@echo "$(COLOR_HEADER)install vimplug...$(COLOR_RESET)"
	ln -s $$XDG_CONFIG_HOME/vim $$HOME/.vim
	curl -fLo $$HOME/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
	@echo "$(COLOR_HEADER)init sketchybar...$(COLOR_RESET)"
	cd ~/.config/sketchybar/helpers
	make
	cd $$HOME/ghq/github.com/yanosea/yanoNixFiles
	curl -L https://github.com/kvndrsslr/sketchybar-app-font/releases/download/v1.0.4/sketchybar-app-font.ttf -o $HOME/Library/Fonts/sketchybar-app-font.ttf
	(git clone https://github.com/FelixKratz/SbarLua.git /tmp/SbarLua && cd /tmp/SbarLua/ && make install && rm -rf /tmp/SbarLua/)
	@echo "$(COLOR_HEADER)init services...$(COLOR_RESET)"
	brew services start sketchybar
	brew services start borders
	skhd --start-service
	yabai --start-service
	@echo "$(COLOR_HEADER)You have to create google drive symbolic link like below...$(COLOR_RESET)"
	@echo "$(COLOR_CMD)ln -s GOOGLE_DRIVE_PATH $$HOME/google_drive$(COLOR_RESET)"
	@echo "$(COLOR_HEADER)You have to create credentials symbolic link like below...$(COLOR_RESET)"
	@echo "$(COLOR_CMD)ln -s $$HOME/google_drive/credentials $$XDG_DATA_HOME/credentials$(COLOR_RESET)"
	@echo "$(COLOR_CMD)ln -s $$XDG_DATA_HOME/credentials/github-copilot/apps.json $$XDG_CONFIG_HOME/github-copilot/apps.json$(COLOR_RESET)"
	@echo "$(COLOR_CMD)ln -s $$XDG_DATA_HOME/credentials/wakatime/.wakatime.cfg $$XDG_CONFIG_HOME/wakatime/.wakatime.cfg$(COLOR_RESET)"
	# done
	@echo "$(COLOR_DONE)initialize done!$(COLOR_RESET)"

# install shortage packages on darwin and apply configurations
darwin.install:
	@echo "$(COLOR_TITLE)install shortage packages...$(COLOR_RESET)"
	@echo "$(COLOR_HEADER)clone ghq shortage repos...$(COLOR_RESET)"
	xargs -I arg ghq get arg <$$HOME/ghq/github.com/yanosea/yanoNixFiles/pkglist/ghq/pkglist.txt
	@echo "$(COLOR_HEADER)install go shortage packages...$(COLOR_RESET)"
	xargs -I arg go install arg <$$HOME/ghq/github.com/yanosea/yanoNixFiles/pkglist/go/pkglist.txt
	@echo "$(COLOR_HEADER)install brew shortage packages...$(COLOR_RESET)"
	xargs -I arg brew install arg <$$HOME/ghq/github.com/yanosea/yanoNixFiles/pkglist/brew/pkglist.txt
	@echo "$(COLOR_HEADER)apply system configuration...$(COLOR_RESET)"
	make darwin.apply.system
	@echo "$(COLOR_HEADER)apply home configuration...$(COLOR_RESET)"
	make darwin.apply.home
	@echo "$(COLOR_DONE)install shortage packages done!$(COLOR_RESET)"

# update darwin packages and apply configurations
darwin.update:
	@echo "$(COLOR_TITLE)update darwin...$(COLOR_RESET)"
	@echo "$(COLOR_HEADER)sync ghq repos...$(COLOR_RESET)"
	ghq list | ghq get --update
	@echo "$(COLOR_HEADER)update go packages...$(COLOR_RESET)"
	gup update
	@echo "$(COLOR_HEADER)update zsh plugins...$(COLOR_RESET)"
	sheldon lock --update
	@echo "$(COLOR_HEADER)update brew packages...$(COLOR_RESET)"
	brew update
	brew upgrade
	brew cleanup
	brew doctor
	make darwin.install
	@echo "$(COLOR_DONE)update done!$(COLOR_RESET)"

# update brew package list
darwin.update.brewpkglist:
	@echo "$(COLOR_TITLE)update brew package list...$(COLOR_RESET)"
	brew leaves >pkglist/brew/pkglist.txt && brew list --cask >>pkglist/brew/pkglist.txt
	@echo "$(COLOR_DONE)update brew package list done!$(COLOR_RESET)"

# restart services
darwin.restart.services:
	@echo "$(COLOR_TITLE)restart services...$(COLOR_RESET)"
	yabai --restart-service
	skhd --restart-service
	brew services restart borders
	brew services restart sketchybar
	@echo "$(COLOR_DONE)restart services done!$(COLOR_RESET)"

# apply system configuration
darwin.apply.system:
	@echo "$(COLOR_TITLE)apply system configuration...$(COLOR_RESET)"
	sudo rm -r ~/.nix-defexpr && sudo nix-channel --update
	sudo darwin-rebuild switch --flake .#yanoMac
	@echo "$(COLOR_DONE)apply system configuration done!$(COLOR_RESET)"

# apply home configuration
darwin.apply.home:
	@echo "$(COLOR_TITLE)apply home configuration...$(COLOR_RESET)"
	rm -fr ~/.config/karabiner/karabiner.json
	export NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1
	home-manager switch --flake .#yanosea@yanoMac --extra-experimental-features "nix-command flakes" --impure
	@echo "$(COLOR_HEADER)apply home configuration done!$(COLOR_RESET)"

#
# windows
#
.PHONY: windows.init windows.install windows.update

# initialize windows
windows.init:
ifeq ($(IS_WINDOWS),1)
	@pwsh -Command "& { \
		Write-Host 'initialize windows...' -ForegroundColor Magenta; \
		Write-Host 'install winget...' -ForegroundColor Yellow; \
		winget install Microsoft.PowerShell; \
		Write-Host 'install git...' -ForegroundColor Yellow; \
		winget install git; \
		Write-Host 'install scoop...' -ForegroundColor Yellow; \
		Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser; \
		Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression; \
		Write-Host 'install ghq via scoop...!' -ForegroundColor Yellow; \
		scoop install ghq; \
		Write-Host 'clone ghq repos...' -ForegroundColor Yellow; \
		$$filePath = \"$$HOME\ghq\github.com\yanosea\yanoNixFiles\pkglist\ghq\pkglist.txt\"; \
		Get-Content -Path $$filePath | ForEach-Object { & ghq get $$_ }; \
		Write-Host 'install winget packages...' -ForegroundColor Yellow; \
		winget import \"$$HOME\ghq\github.com\yanosea\yanoNixFiles\pkglist\winget\pkglist.json\"; \
		Write-Host 'initializing done!' -ForegroundColor Green; \
	}"
else
	@echo "$(COLOR_TITLE)not on Windows, skipping windows.init...$(COLOR_RESET)"
endif

# install shortage packages on windows and apply configurations
windows.install:
ifeq ($(IS_WINDOWS),1)
	@pwsh -Command "& { \
		Write-Host 'install shortage packages...' -ForegroundColor Yellow; \
		Write-Host 'clone ghq shortage repos...' -ForegroundColor Yellow; \
		$$filePath = \"$$HOME\ghq\github.com\yanosea\yanoNixFiles\pkglist\ghq\pkglist.txt\"; \
		Get-Content -Path $$filePath | ForEach-Object { ghq get $$_ }; \
		Write-Host 'install winget shortage packages...' -ForegroundColor Yellow; \
		winget import \"$$HOME\ghq\github.com\yanosea\yanoNixFiles\pkglist\winget\pkglist.json\"; \
		Write-Host 'installing done!' -ForegroundColor Green; \
	}"
else
	@echo "$(COLOR_TITLE)not on Windows, skipping windows.install...$(COLOR_RESET)"
endif

# update windows
windows.update:
ifeq ($(IS_WINDOWS),1)
	@pwsh -Command "& { \
		Write-Host 'update windows...' -ForegroundColor Magenta; \
		Write-Host 'sync ghq repos...' -ForegroundColor Yellow; \
		ghq list | ForEach-Object { ghq get --update $$_ }; \
		Write-Host 'update winget packages...' -ForegroundColor Yellow; \
		winget upgrade --silent --all; \
		Write-Host 'update scoop...' -ForegroundColor Yellow; \
		scoop update; \
		Write-Host 'clone ghq repos...' -ForegroundColor Yellow; \
		$$filePath = \"$$HOME\ghq\github.com\yanosea\yanoNixFiles\pkglist\ghq\pkglist.txt\"; \
		Get-Content -Path $$filePath | ForEach-Object { ghq get $$_ }; \
		Write-Host 'install winget packages...' -ForegroundColor Yellow; \
		winget import \"$$HOME\ghq\github.com\yanosea\yanoNixFiles\pkglist\winget\pkglist.json\"; \
		Write-Host 'export winget packages...' -ForegroundColor Yellow; \
		$$exportPath = \"$$HOME\ghq\github.com\yanosea\yanoNixFiles\pkglist\winget\pkglist.json\"; \
		winget export -o $$exportPath; \
		$$jsonContent = Get-Content -Path $$exportPath -Raw; \
		$$sortedContent = & jq '.Sources[].Packages |= sort_by(.PackageIdentifier | ascii_downcase)' -InputObject $$jsonContent; \
		Set-Content -Path $$exportPath -Value $$sortedContent; \
		Write-Host 'update done!' -ForegroundColor Green; \
	}"
else
	@echo "$(COLOR_TITLE)not on Windows, skipping windows.update...$(COLOR_RESET)"
endif

#
# misc
#
.PHONY: misc.check misc.clean misc.format misc.gc misc.update

# check flake
misc.check:
	@echo "$(COLOR_TITLE)check flake...$(COLOR_RESET)"
	nix flake check --extra-experimental-features "nix-command flakes"
	@echo "$(COLOR_DONE)check done!$(COLOR_RESET)"

# clean result directory
misc.clean:
	@echo "$(COLOR_TITLE)clean result directory...$(COLOR_RESET)"
	rm -rf result
	@echo "$(COLOR_DONE)clean done!$(COLOR_RESET)"

# format files
misc.format:
	@echo "$(COLOR_TITLE)format files...$(COLOR_RESET)"
	treefmt
	@echo "$(COLOR_DONE)format done!$(COLOR_RESET)"

# garbage collection
misc.gc:
	@echo "$(COLOR_TITLE)garbage collection...$(COLOR_RESET)"
	sudo nix profile wipe-history --extra-experimental-features "nix-command flakes" --profile /nix/var/nix/profiles/system --older-than 7d
	sudo nix store gc --debug --extra-experimental-features "nix-command flakes"
	@echo "$(COLOR_DONE)garbage collection done!$(COLOR_RESET)"

# update flake.lock
misc.update:
	@echo "$(COLOR_TITLE)update flake.lock...$(COLOR_RESET)"
	nix flake update nixpkgs --extra-experimental-features "nix-command flakes"
	@echo "$(COLOR_DONE)update done!$(COLOR_RESET)"

# help
.PHONY: help
help:
	@echo "$(COLOR_TITLE)available targets:$(COLOR_RESET)"
	@echo "$(COLOR_HEADER)  [for NixOS]$(COLOR_RESET)"
	@echo "    $(COLOR_CMD)nix.init$(COLOR_RESET)                   - initialize yanoNixOs config"
	@echo "    $(COLOR_CMD)nix.install$(COLOR_RESET)                - install all yanoNixOs packages"
	@echo "    $(COLOR_CMD)nix.update$(COLOR_RESET)                 - update whole yanoNixOs (settings, packages)"
	@echo "    $(COLOR_CMD)nix.apply.system$(COLOR_RESET)           - apply yanoNixOs system configuration"
	@echo "    $(COLOR_CMD)nix.apply.home$(COLOR_RESET)             - apply yanoNixOs home configuration"
	@echo ""
	@echo "$(COLOR_HEADER)  [for NixOS WSL]$(COLOR_RESET)"
	@echo "    $(COLOR_CMD)wsl.init$(COLOR_RESET)                   - initialize yanoNixOsWsl configuration"
	@echo "    $(COLOR_CMD)wsl.install$(COLOR_RESET)                - install yanoNixOsWsl packages"
	@echo "    $(COLOR_CMD)wsl.update$(COLOR_RESET)                 - update whole yanoNixOsWsl (settings, packages)"
	@echo "    $(COLOR_CMD)wsl.apply.system$(COLOR_RESET)           - apply yanoNixOsWsl system configuration"
	@echo "    $(COLOR_CMD)wsl.apply.home$(COLOR_RESET)             - apply yanoNixOsWsl home configuration"
	@echo ""
	@echo "$(COLOR_HEADER)  [for macOS]$(COLOR_RESET)"
	@echo "    $(COLOR_CMD)darwin.init$(COLOR_RESET)                - initialize yanoMac configuration"
	@echo "    $(COLOR_CMD)darwin.install$(COLOR_RESET)             - install yanoMac packages"
	@echo "    $(COLOR_CMD)darwin.update$(COLOR_RESET)              - update whole yanoMac (settings, packages)"
	@echo "    $(COLOR_CMD)darwin.update.brewpkglist$(COLOR_RESET)  - Update yanoMac Brew package list"
	@echo "    $(COLOR_CMD)darwin.restart.services$(COLOR_RESET)    - Restart yanoMac services"
	@echo "    $(COLOR_CMD)darwin.apply.system$(COLOR_RESET)        - apply yanoMac system configuration"
	@echo "    $(COLOR_CMD)darwin.apply.home$(COLOR_RESET)          - apply yanoMac home configuration"
	@echo ""
	@echo "$(COLOR_HEADER)  [for Windows]$(COLOR_RESET)"
	@echo "    $(COLOR_CMD)windows.init$(COLOR_RESET)               - initialize yanoWindows configuration"
	@echo "    $(COLOR_CMD)windows.install$(COLOR_RESET)            - install yanoWindows packages"
	@echo "    $(COLOR_CMD)windows.update$(COLOR_RESET)             - update whole yanoWindows (settings, packages)"
	@echo ""
	@echo "$(COLOR_HEADER)  [miscellaneous]$(COLOR_RESET)"
	@echo "    $(COLOR_CMD)misc.check$(COLOR_RESET)                 - check configuration"
	@echo "    $(COLOR_CMD)misc.clean$(COLOR_RESET)                 - remove result directory"
	@echo "    $(COLOR_CMD)misc.format$(COLOR_RESET)                - run Nix formatter"
	@echo "    $(COLOR_CMD)misc.gc$(COLOR_RESET)                    - run Nix garbage collection"
	@echo "    $(COLOR_CMD)misc.update$(COLOR_RESET)                - update flake.lock file"
