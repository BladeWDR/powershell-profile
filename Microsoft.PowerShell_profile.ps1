## Final Line to set prompt
##oh-my-posh init pwsh | Invoke-Expression


#Set keybinds.
Set-PSReadLineKeyHandler -Key ctrl+p -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key ctrl+n -Function HistorySearchForward
Set-PSReadLineKeyHandler -Key ctrl+u -Function RevertLine

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

# Simple function to start a new elevated process. If arguments are supplied then 
# a single command is started with admin rights; if not then a new admin instance
# of PowerShell is started.
function admin {
    if ($args.Count -gt 0) {   
        $argList = "& '" + $args + "'"
        Start-Process "$psHome\powershell.exe" -Verb runAs -ArgumentList $argList
    } else {
        Start-Process "$psHome\powershell.exe" -Verb runAs
    }
}

# Set UNIX-like aliases for the admin command, so sudo <command> will run the command
# with elevated rights. 
Set-Alias -Name su -Value admin
Set-Alias -Name sudo -Value admin

#Import the Chocolatey Profile that contains the necessary code to enable
#tab-completions to function for `choco`.
#Be aware that if you are missing these lines from your profile, tab completion
#for `choco` will not function.
#See https://ch0.co/tab-completion for details.
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
    Import-Module "$ChocolateyProfile"
}

