function New-TempModelFile {
    [CmdletBinding()]
    param (
        $SourceModelPath = "C:\Work\tools\demo\graphs-n-minizinc-demo\vmCostsCalculation-integer.mzn"
    )
    process {
        $tmpFile = New-TemporaryFile
        $newName = "$($tmpFile.BaseName).mzn"
        $newPath = "$($tmpFile.DirectoryName)\$newName"
        Rename-Item -Path $tmpFile.FullName -NewName $newName

        Get-Content -Path $SourceModelPath -ReadCount 0 | Out-File $newPath -Force
        $newPath
    }    
}


function Invoke-Minizinc {
    [CmdletBinding()]
    param (
        $Solver = "gecode",
        $Modelpath,
        $DataPath,
        $TimeLimit = (10 * 60 * 1000)
    )
       
    end {
        $k = minizinc.exe --solver $Solver  $Modelpath $DataPath --time-limit (10 * 60 * 1000)
        $x = ((($k) -replace "==========","") -join "`n" -split "----------") | ConvertFrom-Json -Depth 10

        $x
    }
}


$tFile = New-TempModelFile
(gc $tFile) -replace "%placeholder%", "solve  minimize totalPrice;" | out-file -FilePath $tFile -Force
$ret = Invoke-Minizinc -Modelpath $tFile -DataPath C:\Work\tools\demo\graphs-n-minizinc-demo\vmData-integer.dzn
$ret

$tFile = New-TempModelFile
(gc $tFile) -replace "%placeholder%", "constraint totalPrice <= $($ret.totalPrice * 10000); solve  maximize totalACU;" | out-file -FilePath $tFile -Force
$ret = Invoke-Minizinc -Modelpath $tFile -DataPath C:\Work\tools\demo\graphs-n-minizinc-demo\vmData-integer.dzn
$ret


$tFile = New-TempModelFile
(gc $tFile) -replace "%placeholder%", "solve  maximize totalACU;" | out-file -FilePath $tFile -Force
$ret = Invoke-Minizinc -Modelpath $tFile -DataPath C:\Work\tools\demo\graphs-n-minizinc-demo\vmData-integer.dzn
$ret

$tFile = New-TempModelFile
(gc $tFile) -replace "%placeholder%", "constraint totalACU >= $($ret.totalACU); solve  minimize totalPrice;" | out-file -FilePath $tFile -Force
$ret = Invoke-Minizinc -Modelpath $tFile -DataPath C:\Work\tools\demo\graphs-n-minizinc-demo\vmData-integer.dzn
$ret
