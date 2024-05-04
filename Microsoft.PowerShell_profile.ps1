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
function Find-Directories {
    if ((Test-Path -PathType Leaf -Path "$env:USERPROFILE\.ps-fzf")){
        $commondirs = Get-Content -Path "$env:USERPROFILE\.ps-fzf" | ForEach-Object { $ExecutionContext.InvokeCommand.ExpandString($_) }
    }
    else{
        Write-Host "It seems that the configuration file does not exist. Would you like to create one?"
        $choice = Read-Host "Y/N"
        if(($choice -eq "Y")){
            New-Item "$env:USERPROFILE\.ps-fzf" -Type File
            Set-Content -Path $env:USERPROFILE\.ps-fzf -Value '$env:USERPROFILE\Documents' -Encoding UTF8
        }
        $commondirs = Get-Content -Path "$env:USERPROFILE\.ps-fzf" | ForEach-Object { $ExecutionContext.InvokeCommand.ExpandString($_) }
    }
    if (!(Test-Path -PathType Leaf -Path "C:\ProgramData\chocolatey\bin\fzf.exe")){
        Write-Host -ForegroundColor Red "fzf is not installed."
        RETURN
    }
    if([string]::isNullOrEmpty("$commondirs")){
        Write-Host -ForegroundColor Red "Your list of common directories is empty. Please add directories to the list by editing your commondirs environment variable."
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

$repoPaths = @{
    'PowershellProfile' = "$env:USERPROFILE\Documents\WindowsPowerShell"
    'neovim' = "$env:LOCALAPPDATA\nvim"
}

function Update-GitRepos{
    if($repoPaths.Count -eq 0 -or $null -eq $repoPaths.Count){
        Write-Host "No repos specified. Not checking for updates."; RETURN
    }
    foreach ($path in $repoPaths.Keys){
       $pathString = $repoPaths[$path]
       if(!(Test-Path -PathType Container -Path $pathString)){
          Write-Host "The path for $pathString does not exist. Skipping."  
       }
       else{
           Invoke-Expression -Command "git -C $pathString fetch" *> $null
           $gitStatus = Invoke-Expression -Command "git -C $pathString status -sb"
           if($gitStatus -like "*behind*"){
               Write-Host "Your $path repository is behind. Do a git pull to update."
           }
           elseif($gitStatus -like "*up to date*"){
               Write-Host "Git repo is up to date."
           }
       }
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

Update-GitRepos
