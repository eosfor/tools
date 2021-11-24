# export all VM prices into a list
$list = @()
$r = Invoke-RestMethod -Method GET -Uri "https://prices.azure.com/api/retail/prices?`$filter=serviceName eq 'Virtual Machines' and priceType eq 'Consumption' and armRegionName eq 'eastus2'"
if ($r) { 
    $r.Items | % { $list += $_ } 
    while ($r.NextPageLink) { $r = Invoke-RestMethod -Method GET -Uri  $r.NextPageLink; $r.Items | % { $list += $_ } }

}

# make a hash table for simplified search
$listHash = @{}
$list | % {
    if ($listHash[$_.armSkuName]) {
        $listHash[$_.armSkuName].Add($_)
    }
    else {
        $l = [System.Collections.Generic.List[PSCustomObject]]::new()
        $l.Add($_)
        $listHash[$_.armSkuName] = $l
    }
}

# import raw VM data and convert strings to ints
$sourceVMs = Import-Csv C:\temp\vmdata.csv
$sourceVMs  | % { $_.cpu = [int]$_.cpu; $_.ram = [int]$_.ram; $_.datadisk = [int]$_.datadisk }

# import SKU info from azure sub
$sku = Get-AzComputeResourceSku -Location eastus2
$tbl1 = $sku | ? { $_.ResourceType -eq "virtualMachines" } | ? { $_.name -notlike "*Promo*" } | % {
    $current = $_
    $k = $listHash[$current.name] 

    if ( $k ) {
        $ret = @{}
        $ret.Name = $current.Name
        $ret.Tier = $current.Tier
        $ret.Size = $current.Size
        foreach ($p in $current.Capabilities) {
            $ret[$p.name] = $p.Value
        }
    
        $v = $k | ? { ($_.type -eq "Consumption") -and ($_.skuName -notlike "*Low Priority*") -and ($_.skuName -notlike "*Spot*") -and ($_.productName -like "*Windows*") -and ($_.retailPrice -ne 0) }
        if ($v.count -eq 1) {
            $ret.retailPrice = $v.retailPrice * 10000
        }
        else {
            $ret.retailPrice = 0
        }

        $ret["cpuToRamRatio"] = [math]::Ceiling($ret.MemoryGB / $ret.vCPUs)

        [pscustomobject]$ret
    }
}

# mark sourceVMs with cpuToRamRatio of the target
function FindClosestRatio {
    param($current, $buckets)

    $currentRatio = -1;
    $min = $currentRatio;
    if ($current.cpu -lt $current.ram) {
        $currentRatio = [math]::Ceiling($current.ram / $current.cpu)
        foreach ($el in $buckets) {
            if ($currentRatio -le $el) {
                $min = $el
            }
        }
    
    }

    $min
}


$buckets = $tbl1.cpuToRamRatio | select -Unique | sort -Descending
$sourceVMs | % { $current = $_; Add-Member -Force -InputObject $current -MemberType NoteProperty -Name cpuToRamRatio -Value (FindClosestRatio -current $current -buckets $buckets ) }

# generate data points for the minizinc model

"existingVMs = [ $(($sourceVMs | ? cpuToRamRatio -gt -1).vmid -join ", " ) ];"
"vmCPU = [ $(($sourceVMs | ? cpuToRamRatio -gt -1).cpu -join ", " ) ];"
"vmRAM = [ $(($sourceVMs | ? cpuToRamRatio -gt -1).ram -join ", " ) ];"
"vmDisk = [ $(($sourceVMs | ? cpuToRamRatio -gt -1).datadisk -join ", " ) ];"
"vmCpuToRamRatio = [ $(($sourceVMs | ? cpuToRamRatio -gt -1).cpuToRamRatio -join ", " ) ];"


$tblFiltered = $tbl1 | ? ACUs -ne $null

"vmSizes = [$($tblFiltered.Name -replace "-", "_" -join ", ")];`n"
"vmSizeCPU = [$($tblFiltered.vCPUs -join ", ")];`n"
"vmSizeRAM = [$($tblFiltered.MemoryGB -join ", ")];`n"
"vmSizePrice = [$($tblFiltered.retailPrice -join ", ")];`n"
"vmSizeACU = [$($tblFiltered.ACUs -join ", ")];`n"
"vmSizeCpuToRamRatio = [$($tblFiltered.cpuToRamRatio -join ", ")];`n"