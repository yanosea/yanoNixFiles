# modules
## completion
Import-Module -Name PSReadLine
Set-PSReadLineOption -PredictionSource History
Import-Module -Name CompletionPredictor
## fzf
Import-Module PSFzf
Enable-PsFzfAliases
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
## zoxide
Import-Module ZLocation
## notfound
Import-Module -Name Microsoft.WinGet.CommandNotFound
# keymap
Set-PSReadLineKeyHandler -Key "Ctrl+d" -Function DeleteChar
Set-PSReadLineKeyHandler -Key "Ctrl+w" -Function BackwardKillWord
Set-PSReadLineKeyHandler -Key "Ctrl+u" -Function BackwardDeleteLine
Set-PSReadLineKeyHandler -Key "Ctrl+k" -Function ForwardDeleteLine
Set-PSReadLineKeyHandler -Key "Ctrl+a" -Function BeginningOfLine
Set-PSReadLineKeyHandler -Key "Ctrl+e" -Function EndOfLine
Set-PSReadLineKeyHandler -Key "Ctrl+f" -Function ForwardChar
Set-PSReadLineKeyHandler -Key "Ctrl+b" -Function BackwardChar
Set-PSReadLineKeyHandler -Key "Alt+f" -Function NextWord
Set-PSReadLineKeyHandler -Key "Alt+b" -Function BackwardWord
Set-PSReadLineKeyHandler -Key "Ctrl+p" -Function PreviousHistory
Set-PSReadLineKeyHandler -Key "Ctrl+n" -Function NextHistory
# alias
Set-Alias cat bat
Set-Alias dot "$HOME\.local\bin\dot.ps1"
Set-Alias grep rg
Remove-Alias -Name ls -Force -ErrorAction SilentlyContinue
function ls { eza --icons $args }
Set-Alias lg lazygit
Set-Alias yz yazi
# starship
$ENV:STARSHIP_CONFIG = "$HOME\.config\starship\starship.toml"
Invoke-Expression (&starship init powershell)
