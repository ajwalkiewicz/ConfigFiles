Set-PSReadLineOption -EditMode Windows
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'

oh-my-posh init pwsh | Invoke-Expression

function ls {
    Get-ChildItem @PSBoundParameters | Format-Table -AutoSize
}

function la {
    Get-ChildItem @PSBoundParameters -Attribute Hidden,Normal,Directory | Format-Table -AutoSize
}



