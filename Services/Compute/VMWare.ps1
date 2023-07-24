param($SCPath, $Sub, $Resources, $Task ,$File, $SmaResources, $TableStyle, $Metrics)

If ($Task -eq 'Processing') {

    $VMWare = $Resources | Where-Object { $_.TYPE -eq 'Microsoft.AVS/privateClouds' }

    if($VMWare)
        {
            $tmp = @()
            foreach ($1 in $VMWare) {
                $ResUCount = 1
                $sub1 = $SUB | Where-Object { $_.id -eq $1.subscriptionId }
                $data = $1.PROPERTIES
                $ER = $data.circuit.expressRouteID.split('/')[8]
                $externalCloud = $data.externalCloudLinks.count
                $identitySources = $data.identitySources.count

                $obj = @{
                    'ID'                                = $1.id;
                    'Subscription'                      = $sub1.Name;
                    'ResourceGroup'                    = $1.RESOURCEGROUP;
                    'Name'                              = $1.NAME;
                    'Location'                          = $1.LOCATION;
                    'SKU'                               = $data.sku.name;
                    'AvailabilityStrategy'             = $data.availability.strategy;
                    'Zone'                              = $data.availability.zone;
                    'Encryption'                        = $data.encryption.status;
                    'ClusterSize'                      = $data.managementCluster.clusterSize;
                }
                $tmp += $obj
                if ($ResUCount -eq 1) { $ResUCount = 0 } 

            }
            $tmp
        }
}
Else {
    if ($SmaResources.VMWare) {

        $TableName = ('VMWareTable_'+($SmaResources.VMWare.id | Select-Object -Unique).count)
        $Style = New-ExcelStyle -HorizontalAlignment Center -AutoSize -NumberFormat 0
        
        $Exc = New-Object System.Collections.Generic.List[System.Object]
        $Exc.Add('Subscription')
        $Exc.Add('ResourceGroup')
        $Exc.Add('Name')
        $Exc.Add('Location')
        $Exc.Add('SKU')
        $Exc.Add('AvailabilityStrategy')
        $Exc.Add('Zone')
        $Exc.Add('Encryption')
        $Exc.Add('ClusterSize')

        $ExcelVar = $SmaResources.VMWare 

        $ExcelVar | 
        ForEach-Object { [PSCustomObject]$_ } | Select-Object -Unique $Exc | 
        Export-Excel -Path $File -WorksheetName 'VMWare' -AutoSize -MaxAutoSizeRows 100 -TableName $TableName -TableStyle $tableStyle -Style $Style

    }
}
