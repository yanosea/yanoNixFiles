# yanosea windows env update packages script
& gum confirm "Do you install packages for windows?"
if ($LASTEXITCODE -eq 0) {
    # sync ghq repos
    Write-Host "`nsync ghq repos!" -ForegroundColor Yellow
    ghq list | ghq get --update
    # update winget packages
    Write-Host "`nupdate winget packages!" -ForegroundColor Yellow
    winget upgrade --silent --all
    # update scoop
    Write-Host "`nupdate scoop!" -ForegroundColor Yellow
    scoop update
    # clone ghq repose
    Write-Host "`nclone ghq repos!" -ForegroundColor Yellow
    $filePath = "$HOME\ghq\github.com\yanosea\yanoNixFiles\pkglist\ghq\pkglist.txt"
    Get-Content -Path $filePath | ForEach-Object {
        & ghq get $_
    }
    # install winget packages
    Write-Host "`ninstall winget packages!" -ForegroundColor Yellow
    winget import "$HOME\ghq\github.com\yanosea\yanoNixFiles\pkglist\winget\pkglist.json"
    # export winget packages
    Write-Host "`nexport winget packages!" -ForegroundColor Yellow
    winget export -o "$HOME\ghq\github.com\yanosea\yanoNixFiles\pkglist\winget\pkglist.json"

} else {
    # update cancelled
    Write-Host "`nupdate cancelled..." -ForegroundColor Red
}
