param($SCPath, $Sub, $Resources, $Task , $File, $SmaResources, $TableStyle) 
If ($Task -eq 'Processing') {

    $VNET = $Resources | Where-Object { $_.TYPE -eq 'microsoft.network/virtualnetworks' }        
    $VNETProperties = $VNET.PROPERTIES
    $VNETPeering = $Resources | Where-Object { $_.TYPE -eq 'microsoft.network/virtualnetworks' -and $null -ne $VNETProperties.Peering -and $VNETProperties.Peering -ne '' }

    if($VNETPeering)
        {
            $tmp = @()

            foreach ($1 in $VNETPeering) {
                $ResUCount = 1
                $sub1 = $SUB | Where-Object { $_.Id -eq $1.subscriptionId }
                $data = $1.PROPERTIES
                
                foreach ($2 in $data.addressSpace.addressPrefixes) {
                    foreach ($4 in $data.virtualNetworkPeerings) {
                        foreach ($5 in $4.properties.remoteAddressSpace.addressPrefixes) {
                            $obj = @{
                                'ID'                                    = $1.id;
                                'Subscription'                          = $sub1.Name;
                                'Resource Group'                        = $1.RESOURCEGROUP;
                                'VNET Name'                             = $1.NAME;
                                'Location'                              = $1.LOCATION;
                                'Zone'                                  = $1.ZONES;
                                'Peering Name'                          = $4.name;
                                'Peering VNet'                          = $4.properties.remoteVirtualNetwork.id.split('/')[8];
                                'Peering State'                         = $4.properties.peeringState;
                                'Resource U'                            = $ResUCount;
                            }
                            $tmp += $obj
                            if ($ResUCount -eq 1) { $ResUCount = 0 }                        
                        }
                    }
                }                    
            }
            $tmp
        }
}
Else {
    if ($SmaResources.VNETPeering) {

        $TableName = ('PeeringsTable_'+($SmaResources.VNETPeering.id | Select-Object -Unique).count)
        $Style = New-ExcelStyle -HorizontalAlignment Center -AutoSize -NumberFormat 0

        $Exc = New-Object System.Collections.Generic.List[System.Object]
        $Exc.Add('Subscription')
        $Exc.Add('Resource Group')
        $Exc.Add('Location')
        $Exc.Add('Zone')
        $Exc.Add('Peering Name')
        $Exc.Add('VNET Name')
        $Exc.Add('Address Space')
        $Exc.Add('Peering VNet')
        $Exc.Add('Peering State')


        $ExcelVar = $SmaResources.VNETPeering 

        $ExcelVar | 
        ForEach-Object { [PSCustomObject]$_ } | Select-Object -Unique $Exc | 
        Export-Excel -Path $File -WorksheetName 'Peering' -AutoSize -MaxAutoSizeRows 100 -TableName $TableName -TableStyle $tableStyle -Style $Style
    
    }
}
