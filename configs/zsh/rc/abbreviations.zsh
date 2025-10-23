#
# abbreviations
#

# alternatives
## cat alternative
abbrev-alias cat="$(which bat)"
## diff alternative
abbrev-alias diff="$(which delta)"
## ls alternative
abbrev-alias ls="$(which eza) --icons"
## tree alternative
abbrev-alias tree="$(which eza) --tree"
## rm alternative (safe delete)
abbrev-alias rm="$(which trash)"
## real rm
abbrev-alias rrm="$(which rm)"

# navigation
## cd to dotfiles
abbrev-alias dot="cd $HOME/ghq/github.com/yanosea/yanoNixFiles"
## z (cd previous directory)
abbrev-alias zz="z -"

# development tools
## fzf-make
abbrev-alias fm="fzf-make"
abbrev-alias fh="fzf-make history"
abbrev-alias fr="fzf-make repeat"
## git/github
### git branch prune
abbrev-alias gbp='git branch --merged | grep -v "\* $(git rev-parse --abbrev-ref HEAD)" | grep -v "^\s*$" | xargs -r git branch -d'
### git hub dashboard
abbrev-alias ghd="gh-dash"
### git hub copilot
abbrev-alias ghcs="gh-copilot-suggestion"
abbrev-alias ghce="gh-copilot-explain"
### git branch fzf
abbrev-alias gbf='git switch $(git branch -l | fzf | tr -d "* ")'
### git reposirory fzf
abbrev-alias grf='cd $(ghq list -p | fzf)'
### git graph log
abbrev-alias ggl="git log --graph --all --oneline --decorate"
## lazy git
abbrev-alias lg="lazygit"
## editor
abbrev-alias nvimdiff="$(which nvim) -d"

# session management
## zellij
abbrev-alias zl="zellij"

# system management
## systemctl-tui
abbrev-alias st="systemctl-tui"
## reboot
abbrev-alias reboot="sudo systemctl reboot"
## shutdown
abbrev-alias shutdown="sudo systemctl poweroff"

# applications
## ccexp
abbrev-alias ccexp="bunx ccexp@latest"
## ccusage
abbrev-alias ccusage="bunx ccusage@latest"
## rtty terminal
abbrev-alias rtty='rtty run zellij --font "PlemolJP Console NF"'
## trello
abbrev-alias trello="trello-tui -board yanoBoard"

# utilities
## nix-latest
abbrev-alias nixl="nix-latest"
## zmv (bulk rename)
abbrev-alias zmv="noglob zmv -W"
