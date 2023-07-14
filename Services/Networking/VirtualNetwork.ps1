param($SCPath, $Sub, $Resources, $Task , $File, $SmaResources, $TableStyle) 

If ($Task -eq 'Processing') {

    $VirtualNetwork = $Resources | Where-Object { $_.TYPE -eq 'microsoft.network/virtualnetworks' }

    if($VirtualNetwork)
        {
            $tmp = @()

            foreach ($1 in $VirtualNetwork) {
                $ResUCount = 1
                $sub1 = $SUB | Where-Object { $_.Id -eq $1.subscriptionId }
                $data = $1.PROPERTIES
                
                foreach ($2 in $data.addressSpace.addressPrefixes) {
                    foreach ($3 in $data.subnets) {
                        $obj = @{
                            'ID'                                           = $1.id;
                            'Subscription'                                 = $sub1.Name;
                            'Resource Group'                               = $1.RESOURCEGROUP;
                            'Name'                                         = $1.NAME;
                            'Location'                                     = $1.LOCATION;
                            'Zone'                                         = $1.ZONES;
                            'Enable DDOS Protection'                       = $data.enableDdosProtection;
                            'DNS Servers'                                  = [string]$data.dhcpOptions.dnsServers;
                            'Subnet Name'                                  = $3.name;
                            'Subnet Route Table'                           = if ($3.properties.routeTable.id) { $3.properties.routeTable.id.split("/")[8] };
                            'Subnet Network Security Group'                = if ($3.properties.networkSecurityGroup.id) { $3.properties.networkSecurityGroup.id.split("/")[8] };
                            'Resource U'                                   = $ResUCount;
                        }
                        $tmp += $obj
                        if ($ResUCount -eq 1) { $ResUCount = 0 }                    
                    }
                }
            }
            $tmp
        }
}

Else {
    if ($SmaResources.VirtualNetwork) {

        $TableName = ('VNETTable_'+($SmaResources.VirtualNetwork.id | Select-Object -Unique).count)
        $Style = New-ExcelStyle -HorizontalAlignment Center -AutoSize -NumberFormat '0'
                

        $Exc = New-Object System.Collections.Generic.List[System.Object]
        $Exc.Add('Subscription')
        $Exc.Add('Resource Group')
        $Exc.Add('Name')
        $Exc.Add('Location')
        $Exc.Add('Zone')
        $Exc.Add('Enable DDOS Protection')
        $Exc.Add('DNS Servers')
        $Exc.Add('Subnet Name')
        $Exc.Add('Subnet Route Table')
        $Exc.Add('Subnet Network Security Group')

        $ExcelVar = $SmaResources.VirtualNetwork 

        
        $ExcelVar | 
            ForEach-Object { [PSCustomObject]$_ } | Select-Object -Unique $Exc | 
        Export-Excel -Path $File -WorksheetName 'Virtual Networks' -AutoSize -TableName $TableName -TableStyle $tableStyle -Style $Style
    }
}
