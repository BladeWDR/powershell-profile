################## WIP ##################################
# Recreate tmux-sessionizer in Powershell using Wezterm.
# Obviously still requires fzf
# Somewhat more limited than it's inspiration, just due to differences in the way that Wezterm and Tmux work.
# It's good, but it's not _quite_ a replacement.

# Returns a PSCustomObject with Wezterm tab information.
function Get-WeztermTabs {
    $count = 0
    while($null -eq $commandoutput){
        $commandoutput = & wezterm cli list
        $count++
        if($count -gt 3){
            Write-Error "Unable to retrieve tab list."
            exit 1
        }
    }
    $TABS = $commandoutput | ForEach-Object {
    if ($_ -match '^\s*(\d+)\s+(\d+)\s+(\d+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(.*)$') {
        [pscustomobject]@{
            WindowId = $matches[1]
            TabId = $matches[2]
            PaneId = $matches[3]
            Workspace = $matches[4]
            Size = $matches[5]
            Title = $matches[6]
            Cwd = $matches[7]
        }
    }
} | Select-Object -Skip 1

    return $TABS
}

# Function that contains the logic to either activate an already created pane, or create a new one.
function New-WeztermPane {
    param(
        [string]$Selected,
        [string]$Name,
        [PSCustomObject]$Tabs
    )
    if($Tabs -like "*$Name*"){
        Write-Host "a tab exists with that name $Name"
        $PANE = $Tabs | Where-Object { $_.Cwd -like "*$Name*" }
        $PANEID = $($PANE.PaneId)
        & wezterm cli activate-pane --pane-id "$PANEID"
    }
    elseif($Tabs){
        Write-Host "no tab exists called $Name"
        $WEZTERM_TAB_ID = & wezterm cli spawn --cwd "$Selected"
        & wezterm cli set-tab-title "$Name" --pane-id $WEZTERM_TAB_ID
        & wezterm cli activate-pane --pane-id $WEZTERM_TAB_ID
    }
    else{
        Write-Host 'no tabs exist'
        Start-Process wezterm -ArgumentList "start", "--new-tab", "--cwd", "$Selected" -NoNewWindow
        Start-Sleep -Milliseconds 100
        & wezterm cli set-tab-title "$Name" --tab-id 0
    }
}

$WEZTERMDIRS="$env:USERPROFILE\.weztermsessionizer"

if ($args.Length -eq 1){
    $SELECTED=$args[0]
}
else{
    $SELECTED=((Get-ChildItem -Path $(Get-Content -Path "$WEZTERMDIRS") -Directory -Depth 1).FullName | fzf )
}

if (!$SELECTED){
    Write-Host 'Nothing selected. Exit.'
    exit 0
}

$SELECTED_NAME=(Get-Item $SELECTED).BaseName
$WEZTERM_RUNNING=Get-Process -ProcessName wezterm-gui -ErrorAction SilentlyContinue
#$WEZTERM_MUX_RUNNING=Get-Process -ProcessName wezterm-mux-server -ErrorAction SilentlyContinue

# Start the muxing server if it's not already running.
#if(!$WEZTERM_MUX_RUNNING){
#    & wezterm-mux-server.exe --daemonize
#}

if($env:WEZTERM_PANE){
    Write-Host 'if'

    $TABS = Get-WeztermTabs
    New-WeztermPane -Selected "$SELECTED" -Name "$SELECTED_NAME" -Tabs $TABS

}

# Note that for this to work from a normal Windows Terminal or PowerShell window, the wezterm-mux-server needs to be running in the background
# You can set this in your wezterm configuration to allow this:
# config.unix_domains = {
#     {
#         name = 'unix',
#     }
# }
# 
# config.default_gui_startup_args = { 'connect', 'unix' }

elseif($WEZTERM_RUNNING){
    $TABS = Get-WeztermTabs

    write-host 'else if'

    New-WeztermPane -Selected "$SELECTED" -Name "$SELECTED_NAME" -Tabs $TABS

}

else{
    write-host 'else'
    New-WeztermPane -Selected "$SELECTED" -Name "$SELECTED_NAME" -Tabs $TABS
}
