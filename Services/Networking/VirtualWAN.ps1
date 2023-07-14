param($SCPath, $Sub, $Resources, $Task , $File, $SmaResources, $TableStyle) 
If ($Task -eq 'Processing') {

    $VirtualWAN = $Resources | Where-Object { $_.TYPE -eq 'microsoft.network/virtualwans' }
    $VirtualHub = $Resources | Where-Object { $_.TYPE -eq 'microsoft.network/virtualhubs' }
    $VPNSite = $Resources | Where-Object { $_.TYPE -eq 'microsoft.network/vpnsites' }
    #$ERSite = $Resources | Where-Object { $_.TYPE -eq 'microsoft.network/expressroutegateways'}

    if($VirtualWAN)
        {
            $tmp = @()

            foreach ($1 in $VirtualWAN) {
                $ResUCount = 1
                $sub1 = $SUB | Where-Object { $_.Id -eq $1.subscriptionId }
                $data = $1.PROPERTIES
                $vhub = $VirtualHub | Where-Object { $_.ID -in $data.virtualHubs.id }
                $vpn = $VPNSite | Where-Object { $_.ID -in $data.vpnSites.id }
                
                if($vpn)
                    {
                        foreach ($2 in $vhub) {
                            foreach ($3 in $vpn) {                        
                                $obj = @{
                                    'ID'                                 = $1.id;
                                    'Subscription'                       = $sub1.Name;
                                    'Resource Group'                     = $1.RESOURCEGROUP;
                                    'Name'                               = $1.NAME;
                                    'Location'                           = $1.LOCATION;
                                    'HUB Name'                           = [string]$2.name;
                                    'HUB Location'                       = [string]$2.location;
                                    'Device Vendor'                      = [string]$3.properties.deviceProperties.deviceVendor;
                                    'Link Provider name'                 = [string]$3.properties.vpnSiteLinks.properties.linkProperties.linkProviderName;
                                    'Link Speed in Mbps'                 = [string]$3.properties.vpnSiteLinks.properties.linkProperties.linkSpeedInMbps;
                                    'Virtual Site Private Address Space' = [string]$3.properties.addressSpace.addressPrefixes;
                                    'Resource U'                         = $ResUCount;
                                }
                                $tmp += $obj
                                if ($ResUCount -eq 1) { $ResUCount = 0 }                     
                            }
                        }
                    }
                else
                    {
                        foreach ($2 in $vhub) {                    
                                    foreach ($Tag in $Tags) {  
                                        $obj = @{
                                            'ID'                                 = $1.id;
                                            'Subscription'                       = $sub1.Name;
                                            'Resource Group'                     = $1.RESOURCEGROUP;
                                            'Name'                               = $1.NAME;
                                            'Location'                           = $1.LOCATION;
                                            'HUB Name'                           = [string]$2.name;
                                            'HUB Location'                       = [string]$2.location;
                                            'Virtual Site Name'                  = $null;
                                            'Device Vendor'                      = $null;
                                            'Link Provider name'                 = $null;
                                            'Link Speed in Mbps'                 = $null;
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
    if ($SmaResources.VirtualWAN) {

        $TableName = ('VWANTable_'+($SmaResources.VirtualWAN.id | Select-Object -Unique).count)
        $Style = New-ExcelStyle -HorizontalAlignment Center -AutoSize -NumberFormat 0

        $Exc = New-Object System.Collections.Generic.List[System.Object]
        $Exc.Add('Subscription')
        $Exc.Add('Resource Group')
        $Exc.Add('Name')                              
        $Exc.Add('Location')                                     
        $Exc.Add('HUB Name')                          
        $Exc.Add('HUB Location')                                       
        $Exc.Add('Virtual Site Name')                 
        $Exc.Add('Device Vendor')                     
        $Exc.Add('Link Provider name')                
        $Exc.Add('Link Speed in Mbps')                


        $ExcelVar = $SmaResources.VirtualWAN 

        $ExcelVar | 
        ForEach-Object { [PSCustomObject]$_ } | Select-Object -Unique $Exc | 
        Export-Excel -Path $File -WorksheetName 'Virtual WAN' -AutoSize -MaxAutoSizeRows 100 -TableName $TableName -TableStyle $tableStyle -Style $Style
    
    }
}
