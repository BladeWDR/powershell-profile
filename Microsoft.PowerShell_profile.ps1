## Final Line to set prompt
##oh-my-posh init pwsh | Invoke-Expression

function Install-Font() {

    Start-Process "choco install nerd-fonts-CascadiaCode" -Verb runAs

}

function grep($regex, $dir) {
    if ( $dir ) {
        Get-ChildItem $dir | select-string $regex
        return
    }
    $input | select-string $regex
}

#Import the Chocolatey Profile that contains the necessary code to enable
tab-completions to function for `choco`.
#Be aware that if you are missing these lines from your profile, tab completion
for `choco` will not function.
#See https://ch0.co/tab-completion for details.
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
    Import-Module "$ChocolateyProfile"
}

