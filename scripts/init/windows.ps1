# yanosea windows initialize script
# install pwsh 7
Write-Host "`ninstall winget!" -ForegroundColor Yellow
winget install Microsoft.PowerShell
# install git
Write-Host "`ninstall git!" -ForegroundColor Yellow
winget install git
# install scoop
Write-Host "`ninstall scoop!" -ForegroundColor Yellow
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
# install ghq via scoop
Write-Host "`ninstall ghq!" -ForegroundColor Yellow
scoop install ghq
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
