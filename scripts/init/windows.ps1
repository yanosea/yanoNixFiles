# yanosea windows initialize script
# install scoop
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
# clone ghq repose
Write-Host "`nclone ghq repos!" -ForegroundColor Yellow
$filePath = "$HOME\ghq\github.com\yanosea\yanoNixFiles\pkglist\ghq\pkglist.txt"
Get-Content -Path $filePath | ForEach-Object {
    & ghq get $_
}
# install winget packages
Write-Host "`ninstall winget packages!" -ForegroundColor Yellow
winget import "$HOME\ghq\github.com\yanosea\yanoNixFiles\pkglist\winget\pkglist.json"
# done!
Write-Host "`ninitializing done!" -ForegroundColor Green
