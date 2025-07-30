#
# command aliases
#

# file operations
## ccusage
alias ccusage="bunx ccusage"
## cat alternative
alias cat="$(which bat)"
## ls alternative
alias ls="$(which eza) --icons"
## tree alternative
alias tree="$(which eza) --tree"
## rm alternative (safe delete)
alias rm="$(which trash)"
## real rm
alias rrm="$(which rm)"
# navigation
## cd to dotfiles
alias dot="cd $HOME/ghq/github.com/yanosea/yanoNixFiles"
## z (cd previous directory)
alias zz="z -"
# development tools
## fzf-make
alias fm="fzf-make"
alias fh="fzf-make history"
alias fr="fzf-make repeat"
## git/github
alias gbp='git branch --merged | grep -v "\* $(git rev-parse --abbrev-ref HEAD)" | grep -v "^\s*$" | xargs -r git branch -d'
alias ghd="gh-dash"
alias gsf='git switch $(git branch -l | fzf | tr -d "* ")'
alias gitgraph="git log --graph --all --oneline --decorate"
## editors
alias nvimdiff="$(which nvim) -d"
alias lg="lazygit"
# session management
## zellij
alias zl="zellij"
# system management
## systemctl-tui
alias st="systemctl-tui"
## reboot
alias reboot="sudo systemctl reboot"
## shutdown
alias shutdown="sudo systemctl poweroff"
# applications
## rtty terminal
alias rtty='rtty run zellij --font "PlemolJP Console NF"'
## trello
alias trello="trello-tui -board yanoBoard"
# utilities
## zmv (bulk rename)
alias zmv="noglob zmv -W"
