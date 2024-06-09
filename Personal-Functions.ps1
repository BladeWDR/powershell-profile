function Install-Apps {
if (!
    #current role
    (New-Object Security.Principal.WindowsPrincipal(
        [Security.Principal.WindowsIdentity]::GetCurrent()
    #is admin?
    )).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )
) {
    #elevate script and exit current non-elevated runtime
    Start-Process `
        -FilePath 'powershell' `
        -ArgumentList (
            #flatten to single array
            '-File', $MyInvocation.MyCommand.Source, $args `
            | ForEach-Object{ $_ }
        ) `
        -Verb RunAs
    #exit
}

# The list of apps to be installed by Chocolatey.
$apps = @("lazygit", "starship")

# Test to see if choco is installed.
if (-Not $(Get-Command choco)){
    Write-Host "Choco does not appear to be installed."
    $choice = Read-Host "Would you like to install it? (Y/N)"
    if($choice -eq "Y"){
        Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    }
}

choco install $apps
Pause
}

Install-Apps
