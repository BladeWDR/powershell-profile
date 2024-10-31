# Set environment variables
$NVIM = "$env:LOCALAPPDATA\nvim"
#Set keybinds.
Set-PSReadLineKeyHandler -Key ctrl+p -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key ctrl+n -Function HistorySearchForward
Set-PSReadLineKeyHandler -Key ctrl+u -Function RevertLine
Set-PSReadLineKeyHandler -Key ctrl+d -ScriptBlock {
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert('exit')
    [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
}

# only set this keybind if fzf is actually installed.
# avoid unnecessarily overriding the existing binding of ctrl-r unless we have something to replace it with.
if (Get-Command fzf -ErrorAction SilentlyContinue) {
    Set-PSReadLineKeyHandler -Key ctrl+r -ScriptBlock {
        $result = $(Find-History-Fzf)
        if ($result) {
            [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert($result)
        }
    }
}

function Find-History-Fzf {
    # Get PowerShell history from the history file
    $history = Get-Content $((Get-PSReadLineOption).HistorySavePath)
    # Remove duplicate entries and empty lines
    $uniqueHistory = $history | Where-Object { $_ -ne '' } | Select-Object -Unique
    # Call fzf for fuzzy searching
    $selected = $uniqueHistory | Out-String | fzf --height 40% --border --layout=reverse --info=inline --bind="ctrl-r:toggle-sort"
    if (-not $selected) {
        Write-Host "No selection made or fzf exited."
        break
    }
    # Return the selected command (trimmed)
    return $selected.Trim()
}

function Install-Font() {

    Start-Process "choco install nerd-fonts-CascadiaCode" -Verb runAs

}

function Install-Apps{
    Start-Process -FilePath "powershell" -ArgumentList "$PSScriptRoot\Install.ps1" -Verb RunAs
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

$documentsPath = [Environment]::GetFolderPath("MyDocuments")

$repoPaths = @{
    'PowershellProfile' = "$documentsPath\WindowsPowerShell"
    'neovim' = "$env:LOCALAPPDATA\nvim"
}

function Invoke-PS7-Fix {
    $scriptBlock = {
        $documentsPath = [Environment]::GetFolderPath("MyDocuments")
        $ps7ProfilePath = "$documentsPath\Powershell\Microsoft.PowerShell_profile.ps1"
        if ((Test-Path -Path $profile) -and (-Not (Test-Path -Path $ps7ProfilePath))) {
            write-output 'first if'
            New-Item -Path $ps7ProfilePath -ItemType SymbolicLink -Value $profile
            Read-host 'test'
        }
        elseif (-Not ((Get-ItemProperty -Path $ps7ProfilePath).PSIsContainer)) {
            write-output 'second if'
            Remove-Item -Path $ps7ProfilePath
            New-Item -Path $ps7ProfilePath -ItemType SymbolicLink -Value $profile
            Read-host 'test'
        }
        else {
            Write-Output 'The symbolic link already exists!'
            Read-host 'test'
        }
        Read-host 'test'
    }
    $scriptBlockString = $scriptBlock.ToString()
    Start-Process -FilePath "$psHome\powershell.exe" -ArgumentList "-Command & $scriptBlockString" -Verb RunAs -Wait
}

# function Fix-PS7 {
#     $ps7ProfilePath = "$documentsPath\Powershell\Microsoft.PowerShell_profile.ps1"
#     if ((Test-Path -Path $profile) -and (-Not (Test-Path -Path $ps7ProfilePath))) {
#     New-Item -Path $ps7ProfilePath -ItemType SymbolicLink -Value $PROFILE -Verb Runas
#     }
#     elseif(-Not ((Get-ItemProperty -Path $ps7ProfilePath).LinkType)){
#         Remove-Item -Path $ps7ProfilePath
#         New-Item -Path $ps7ProfilePath -ItemType SymbolicLink -Value $PROFILE -Verb Runas
#     }
#     else{
#         Write-host 'The symbolic link already exists!'
#     }
# }

function Update-GitRepos{


    if($repoPaths.Count -eq 0 -or $null -eq $repoPaths.Count){
        Write-Host "No repos specified. Not checking for updates."; RETURN
    }

    if (-Not (Test-Path -Path $documentsPath\lastupdate)){
        $lastCheck = $null
    }
    else{
        $lastCheck = Get-Content -path "$documentsPath\lastupdate"
    }
    $currentTime = Get-Date

        if (($lastCheck -eq $null) -or ($currentTime -ge ([DateTime]::Parse($lastCheck).AddHours(12)))) {

            Write-Output 'Running daily update check...'
            Start-Sleep 1
            #Clear-Host

            foreach ($path in $repoPaths.Keys){
                $pathString = $repoPaths[$path]
                    if(!(Test-Path -PathType Container -Path $pathString)){
                        Write-Host "The path for $pathString does not exist. Skipping."  
                    }
                    else{
                        & git -C $pathString fetch *> $null
                            $gitStatus = & git -C $pathString status -sb
                            if($gitStatus -like "*behind*"){
                                Write-Host "Your $path repository is behind. Do a git pull to update."
                            }
                    }
            }
        }
        $currentTime.ToString('yyyy-MM-ddTHH:mm:ss') | Set-Content -Path "$documentsPath\lastupdate"
}

# Network Utilities
function Get-PubIP { (Invoke-WebRequest http://ifconfig.me/ip).Content }

# System Utilities
function uptime {
    if ($PSVersionTable.PSVersion.Major -eq 5) {
        Get-WmiObject win32_operatingsystem | Select-Object @{Name='LastBootUpTime'; Expression={$_.ConverttoDateTime($_.lastbootuptime)}} | Format-Table -HideTableHeaders
    } else {
        net statistics workstation | Select-String "since" | ForEach-Object { $_.ToString().Replace('Statistics since ', '') }
    }
}

function reload-profile {
    & $profile
}

# Quick File Creation
function touch { 
    param($name) 
    if(!(Test-Path -PathType Leaf -Path $name)){
        New-Item -ItemType "file" -Path . -Name $name 
    }
    else{
        [datetime]$date = (Get-Date)
        Get-ChildItem -Path $name | ForEach-Object { $_.LastWriteTime = $date }
    }
}

# Enhanced Listing
function la { Get-ChildItem -Path . -Force | Format-Table -AutoSize }
function ll { Get-ChildItem -Path . -Force -Hidden | Format-Table -AutoSize }

# Networking Utilities
function flushdns { Clear-DnsClientCache }

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

# Enhanced PowerShell Experience
Set-PSReadLineOption -Colors @{
    Command = 'Yellow'
    Parameter = 'Green'
    String = 'DarkCyan'
}

$connectionStatus = Test-Connection -ComputerName "github.com" -Count 1 -Quiet

if($connectionStatus){
    Update-GitRepos
}
else{
    Write-Host 'Connection could not be made to github.com'
}

$ENV:STARSHIP_CONFIG = "$HOME\Documents\WindowsPowershell\starship.toml"
$STARSHIP_PATH = "C:\Program Files\starship\bin"
$ZOXIDE_PATH = "C:\ProgramData\chocolatey\bin\zoxide.exe"

if (Test-Path -Path "$STARSHIP_PATH"){
    Invoke-Expression (&starship init powershell)
}

else{
    Write-Host "Starship does not appear to be installed."
    Write-Host "Not attempting to load something that doesn't exist."
}

if (Test-Path -Path "$ZOXIDE_PATH"){
    Invoke-Expression (& { (zoxide init powershell --cmd cd | Out-String) })
}
