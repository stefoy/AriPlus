param($SCPath, $Sub, $Resources, $Task ,$File, $SmaResources, $TableStyle, $Metrics)
If ($Task -eq 'Processing') {

    $PublicDNS = $Resources | Where-Object { $_.TYPE -eq 'microsoft.network/dnszones' }

    if($PublicDNS)
        {
            $tmp = @()

            foreach ($1 in $PublicDNS) {
                $ResUCount = 1
                $sub1 = $SUB | Where-Object { $_.Id -eq $1.subscriptionId }
                $data = $1.PROPERTIES
                
                $obj = @{
                    'ID'                        = $1.id;
                    'Subscription'              = $sub1.Name;
                    'Resource Group'            = $1.RESOURCEGROUP;
                    'Name'                      = $1.NAME;
                    'Location'                  = $1.LOCATION;
                    'Zone Type'                 = $data.zoneType;
                    'Number of Record Sets'     = $data.numberOfRecordSets;
                    'Max Number of Record Sets' = $data.maxNumberofRecordSets;
                    'Name Servers'              = [string]$data.nameServers;
                    'Resource U'                = $ResUCount;
                }
                $tmp += $obj
                if ($ResUCount -eq 1) { $ResUCount = 0 }              
            }
            $tmp
        }
}
Else {
    if ($SmaResources.PublicDNS) {

        $TableName = ('PubDNSTable_'+($SmaResources.PublicDNS.id | Select-Object -Unique).count)
        $Style = New-ExcelStyle -HorizontalAlignment Center -AutoSize -NumberFormat 0

        $condtxt = @()

        $Exc = New-Object System.Collections.Generic.List[System.Object]
        $Exc.Add('Subscription')
        $Exc.Add('Resource Group')
        $Exc.Add('Name')
        $Exc.Add('Location')
        $Exc.Add('Zone Type')
        $Exc.Add('Number of Record Sets')
        $Exc.Add('Max Number of Record Sets')
        $Exc.Add('Name Servers')

        $ExcelVar = $SmaResources.PublicDNS 

        $ExcelVar | 
        ForEach-Object { [PSCustomObject]$_ } | Select-Object -Unique $Exc | 
        Export-Excel -Path $File -WorksheetName 'Public DNS' -AutoSize -MaxAutoSizeRows 100 -TableName $TableName -TableStyle $tableStyle -ConditionalText $condtxt -Style $Style

    }
}