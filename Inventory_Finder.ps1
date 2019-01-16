$cnt = 0
do{
    $cnt++
    $cred = Get-Credential -Message "Please provide valid infoblox credentails for querying the InfoBlox API"
    Set-IBWAPIConfig -host sjs-grid.sjsu.edu  -version 2.7.1 -cred $cred
    try{
        Get-IBObject -type record:host -ErrorAction Continue | Out-Null
        Write-Host "Authentication Succeeded!"
        break;
    } catch {
        Write-Host "Those credentials did not work!"
    }
} while( $cnt -lt 5)

Set-IBWAPIConfig -host sjs-grid.sjsu.edu  -version 2.7.1 -cred $cred

do {
    do {
        $lab = Read-Host -Prompt 'Provide Lab Number(E***)(Must be a valid OU under COE Lab Workstations OU):'
    } while($lab -cnotmatch '^E\d\d\d$')
    
    $ou = Get-ADOrganizationalUnit -Filter 'Name -eq $lab' -SearchBase 'OU=PC,OU=Labs,OU=Workstations,OU=COE,OU=Delegated OUs,DC=SJSUAD,DC=SJSU,DC=EDU'
} while($ou -eq $null -or $ou -eq "")

$computers = Get-ADComputer -Filter * -SearchBase $ou.DistinguishedName
$count = $computers.Count
Format-Table -Property "Name" -InputObject $computers
Write-Host "Found $count computers in AD, proceeding to extract MACs... Do check for missing/extra computers and adjust OU members accordingly"

$count = 0
foreach($computer in $computers){
    $name = $computer.Name.ToLower()
    try{
        
        $pattern = $name + '|' + $name.ToUpper()
        $IBObj = Get-IBObject -type lease -Filters "client_hostname~=$pattern" -ReturnFields 'binding_state,hardware'
        $t = $count
        foreach($row in $IBObj) {
            if($row.binding_state -in 'ACTIVE','RELEASED','STATIC'){
                $mac = $row.hardware
                Write-Host $name','$mac 
                $count++
                break
            }
        }

        if($t -eq $count){
            Write-Host $name',<NotFound>'
        }
        
    } catch {
        Write-Host "InfoBlox API crash"
    }

}

Write-Host "Done ..."
Start-Sleep -Seconds 5