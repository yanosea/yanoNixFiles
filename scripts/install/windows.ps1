# yanosea windows env install packages script
& gum confirm "Do you install packages for windows?"
if ($LASTEXITCODE -eq 0) {
    # clone ghq repose
    Write-Host "`nclone ghq repos!" -ForegroundColor Yellow
    $filePath = "$HOME\ghq\github.com\yanosea\yanoNixFiles\pkglist\ghq\pkglist.txt"
    Get-Content -Path $filePath | ForEach-Object {
        & ghq get $_
    }
    # install winget packages
    Write-Host "`ninstall winget packages!" -ForegroundColor Yellow
    winget import "$HOME\ghq\github.com\yanosea\yanoNixFiles\pkglist\winget\pkglist.json"
} else {
    # install cancelled
    Write-Host "`ninstall cancelled..." -ForegroundColor Red
}
