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

# A function to find directories using fzf. Requires fzf to be installed. choco install fzf
$commondirs = @("$env:USERPROFILE\git", "$env:USERPROFILE\Documents", "F:\Syncthing")

function Find-Directories {
    if (!(Test-Path -PathType Leaf -Path "C:\ProgramData\chocolatey\bin\fzf.exe")){
        Write-Host -ForegroundColor Red "fzf is not installed."
        RETURN
    }
    if([string]::isNullOrEmpty($commondirs)){
        Write-Host -ForegroundColor Red "Your list of common directories is empty. Please add directories to the list."
        RETURN
    }
    foreach ($dir in $commondirs){
        if(!(Test-Path -PathType Container -Path $dir)){
            $commondirs = $commondirs | Where-Object { $_ -ne $dir }
            Write-Host -ForegroundColor Red "WARNING: The folder $dir does not exist."
            Write-Host "Press any key to continue..."
            $Host.UI.ReadLine()
        }
    }
    $result = $(Get-ChildItem -Path $commondirs -directory | Select-Object -ExpandProperty FullName | fzf)
    if(![string]::IsNullOrEmpty($result)){
        Set-Location -Path $result
    }
}

# Set UNIX-like aliases for the admin command, so sudo <command> will run the command
# with elevated rights. 
Set-Alias -Name su -Value admin
Set-Alias -Name sudo -Value admin
Set-Alias -Name fd -Value Find-Directories 

#Import the Chocolatey Profile that contains the necessary code to enable
#tab-completions to function for `choco`.
#Be aware that if you are missing these lines from your profile, tab completion
#for `choco` will not function.
#See https://ch0.co/tab-completion for details.
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
    Import-Module "$ChocolateyProfile"
}

