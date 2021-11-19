Import-Module PSQuickGraph

$ids = Get-WinEvent -LogName Microsoft-Windows-Sysmon/Operational | ? { $_.id -eq 3 }
$commObjects = $ids | % {
    New-Object psobject -Property @{ 
        RuleName            = $_.Properties[0].value
        UtcTime             = $_.Properties[1].value
        ProcessGuid         = $_.Properties[2].value
        ProcessId           = $_.Properties[3].value
        Image               = $_.Properties[4].value
        User                = $_.Properties[5].value
        Protocol            = $_.Properties[6].value
        Initiated           = $_.Properties[7].value
        SourceIsIpv6        = $_.Properties[8].value
        SourceIp            = $_.Properties[9].value
        SourceHostname      = $_.Properties[10].value
        SourcePort          = $_.Properties[11].value
        SourcePortName      = $_.Properties[12].value
        DestinationIsIpv6   = $_.Properties[13].value
        DestinationIp       = $_.Properties[14].value
        DestinationHostname = $_.Properties[15].value
        DestinationPort     = $_.Properties[16].value
        DestinationPortName = $_.Properties[17].value
        SourceString        = "$($_.Properties[4].value)`:$($_.Properties[3].value)"
        DestinationString   = "$($_.Properties[14].value)`:$($_.Properties[16].value)"
    }
}

$g = New-Graph -Type BidirectionalGraph
$commObjects | % {
    Add-Edge -From $_.SourceString -To $_.DestinationString -Graph $g | Out-Null
}

Show-GraphLayout -Graph $g