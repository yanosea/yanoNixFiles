#
# abbreviations
#

# file operations
## ccusage
abbrev-alias ccusage="bunx ccusage"
## cat alternative
abbrev-alias cat="$(which bat)"
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
abbrev-alias gbp='git branch --merged | grep -v "\* $(git rev-parse --abbrev-ref HEAD)" | grep -v "^\s*$" | xargs -r git branch -d'
abbrev-alias ghd="gh-dash"
abbrev-alias gsf='git switch $(git branch -l | fzf | tr -d "* ")'
abbrev-alias gitgraph="git log --graph --all --oneline --decorate"
## editors
abbrev-alias nvimdiff="$(which nvim) -d"
abbrev-alias lg="lazygit"

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
## rtty terminal
abbrev-alias rtty='rtty run zellij --font "PlemolJP Console NF"'
## trello
abbrev-alias trello="trello-tui -board yanoBoard"

# utilities
## zmv (bulk rename)
abbrev-alias zmv="noglob zmv -W"