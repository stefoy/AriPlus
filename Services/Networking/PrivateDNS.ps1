param($SCPath, $Sub, $Resources, $Task ,$File, $SmaResources, $TableStyle, $Metrics)
If ($Task -eq 'Processing') {

    $PrivateDNS = $Resources | Where-Object { $_.TYPE -eq 'microsoft.network/privatednszones' }
    $VNETLinks =  $Resources | Where-Object { $_.TYPE -eq 'microsoft.network/privatednszones/virtualnetworklinks' }

    if($PrivateDNS)
        {
            $tmp = @()

            foreach ($1 in $PrivateDNS) {
                $ResUCount = 1
                $sub1 = $SUB | Where-Object { $_.Id -eq $1.subscriptionId }
                $data = $1.PROPERTIES

                $vnlks = ($VNETLinks | Where-Object {$_.id -like ($1.id + '*')})
                $vnlks = if (!$vnlks) {[pscustomobject]@{id = 'none'}} else {$vnlks | Select-Object @{Name="id";Expression={$_.properties.virtualNetwork.id.split("/")[8]}}}

                foreach ($2 in $vnlks) {

                    $obj = @{
                        'ID'                              = $1.id;
                        'Subscription'                    = $sub1.Name;
                        'Resource Group'                  = $1.RESOURCEGROUP;
                        'Name'                            = $1.NAME;
                        'Location'                        = $1.LOCATION;
                        'Number of Records'               = $data.numberOfRecordSets;
                        'Virtual Network Links'           = $data.numberOfVirtualNetworkLinks;
                        'Network Links with Registration' = $data.numberOfVirtualNetworkLinksWithRegistration;
                        'Virtual Network'                 = $2.id
                    }
         
                    $tmp += $obj
                    if ($ResUCount -eq 1) { $ResUCount = 0 } 
                }               
            }
            $tmp
        }
}
Else {
    if ($SmaResources.PrivateDNS) {

        $TableName = ('PrivDNSTable_'+($SmaResources.PrivateDNS.id | Select-Object -Unique).count)
        $Style = New-ExcelStyle -HorizontalAlignment Center -AutoSize -NumberFormat 0

        $condtxt = @()

        $Exc = New-Object System.Collections.Generic.List[System.Object]
        $Exc.Add('Subscription')
        $Exc.Add('Resource Group')
        $Exc.Add('Name')
        $Exc.Add('Location')
        $Exc.Add('Number of Records')
        $Exc.Add('Virtual Network Links')
        $Exc.Add('Virtual Network')
        $Exc.Add('Network Links with Registration')

        $ExcelVar = $SmaResources.PrivateDNS

        $ExcelVar | 
        ForEach-Object { [PSCustomObject]$_ } | Select-Object -Unique $Exc | 
        Export-Excel -Path $File -WorksheetName 'Private DNS' -AutoSize -MaxAutoSizeRows 100 -TableName $TableName -ConditionalText $condtxt -TableStyle $tableStyle -Style $Style
    
    }   
}