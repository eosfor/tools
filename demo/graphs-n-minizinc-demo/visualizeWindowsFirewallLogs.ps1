Import-Module PSQuickGraph

$f = gc "C:\temp\pfirewall.log.old"
$regex = '^(?<datetime>\d{4,4}-\d{2,2}-\d{2,2}\s\d{2}:\d{2}:\d{2})\s(?<action>\w+)\s(?<protocol>\w+)\s(?<srcip>\b(?:\d{1,3}\.){3}\d{1,3}\b)\s(?<dstip>\b(?:\d{1,3}\.){3}\d{1,3}\b)\s(?<srcport>\d{1,5})\s(?<dstport>\d{1,5})\s(?<size>\d+|-)\s(?<tcpflags>\d+|-)\s(?<tcpsyn>\d+|-)\s(?<tcpack>\d+|-)\s(?<tcpwin>\d+|-)\s(?<icmptype>\d+|-)\s(?<icmpcode>\d+|-)\s(?<info>\d+|-)\s(?<path>.+)$'
 

$log =
$f | % {
    $_ -match $regex | Out-Null
    if ($Matches) {
        [PSCustomObject]@{
            action   = $Matches.action
            srcip    = [ipaddress]$Matches.srcip
            dstport  = $Matches.dstport
            tcpflags = $Matches.tcpflags
            dstip    = [ipaddress]$Matches.dstip
            info     = $Matches.info
            size     = $Matches.size
            protocol = $Matches.protocol
            tcpack   = $Matches.tcpac
            srcport  = $Matches.srcport
            tcpsyn   = $Matches.tcpsyn
            datetime = [datetime]$Matches.datetime
            icmptype = $Matches.icmptype
            tcpwin   = $Matches.tcpwin
            icmpcode = $Matches.icmpcode
            path     = $Matches.path
        }
    }
}

$g = new-graph -Type BidirectionalGraph
 
$log | ? { $_.srcip -and $_.dstip } | % {
    Add-Edge -From $_.srcip -To $_.dstip -Graph $g | out-null
}

Show-GraphLayout -Graph $g