################## WIP ##################################
# Recreate tmux-sessionizer in Powershell using Wezterm.
# Obviously still requires fzf
# Somewhat more limited than it's inspiration, just due to differences in the way that Wezterm and Tmux work.
# It's good, but it's not _quite_ a replacement.

function Get-WeztermTabs {
    $TABS = & wezterm cli list | ForEach-Object {
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

$WEZTERMDIRS="$env:USERPROFILE\.weztermsessionizer"

if ($args.Length -eq 1){
    $SELECTED=$args[0]
    Write-Host "first if statement"
}
else{
    $SELECTED=((Get-ChildItem -Path $(Get-Content -Path "$WEZTERMDIRS") -Directory -Depth 1).FullName | fzf )
}

if (!$SELECTED){
    Write-Host 'Nothing selected. Exit.'
    exit 0
}

$SELECTED_NAME=(Get-Item $SELECTED).BaseName
$WEZTERM_RUNNING=Get-Process -ProcessName wezterm-gui

if($env:WEZTERM_PANE){

    $TABS = Get-WeztermTabs

    if($TABS -match "$SELECTED_NAME"){
        $PANE = $TABS | Where-Object { $_.Cwd -like "*$SELECTED_NAME*" }
        $PANEID = $($PANE.PaneId)
        & wezterm cli activate-pane --pane-id $PANEID
    }
    else{
        $WEZTERM_TAB_ID = & wezterm cli spawn --cwd "$SELECTED"
        & wezterm cli set-tab-title "$SELECTED_NAME" --pane-id $WEZTERM_TAB_ID
    }
}
elseif((!$env:WEZTERM_PANE) -and ($WEZTERM_RUNNING)){
    $TABS = Get-WeztermTabs
    
    if($TABS -match "$SELECTED_NAME"){
        $PANE = $TABS | Where-Object { $_.Cwd -like "*$SELECTED_NAME*" }
        $PANEID = $($PANE.PaneId)
        & wezterm cli activate-pane --pane-id $PANEID
    }
    else{
        $WEZTERM_TAB_ID = & wezterm cli spawn --domain-name local
        #-- wezterm cli set-tab-title $SELECTED_NAME
    }
}
else{
    & wezterm start --cwd "$SELECTED" --domain local
}
