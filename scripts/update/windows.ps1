# yanosea windows env update packages script
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
$exportPath = "$HOME\ghq\github.com\yanosea\yanoNixFiles\pkglist\winget\pkglist.json"
winget export -o $exportPath
# sort the exported packages
$sortedPackages = Get-Content -Path $exportPath | jq '.Sources[].Packages |= sort_by(.PackageIdentifier | ascii_downcase)'
$sortedPackages | Set-Content -Path $exportPath
# done!
Write-Host "`ndone!" -ForegroundColor Green
