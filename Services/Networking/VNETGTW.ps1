param($SCPath, $Sub, $Resources, $Task ,$File, $SmaResources, $TableStyle)
If ($Task -eq 'Processing') {

    $VNETGTW = $Resources | Where-Object { $_.TYPE -eq 'microsoft.network/virtualnetworkgateways' }

    if($VNETGTW)
        {
            $tmp = @()

            foreach ($1 in $VNETGTW) {
                $ResUCount = 1
                $sub1 = $SUB | Where-Object { $_.Id -eq $1.subscriptionId }
                $data = $1.PROPERTIES
                
                $obj = @{
                    'ID'                     = $1.id;
                    'Subscription'           = $sub1.Name;
                    'Resource Group'         = $1.RESOURCEGROUP;
                    'Name'                   = $1.NAME;
                    'Location'               = $1.LOCATION;
                    'SKU'                    = $data.sku.tier;
                    'Active-active mode'     = $data.activeActive; 
                    'Gateway Type'           = $data.gatewayType;
                    'Gateway Generation'     = $data.vpnGatewayGeneration;
                    'VPN Type'               = $data.vpnType;
                    'Enable Private Address' = $data.enablePrivateIpAddress;
                    'Enable BGP'             = $data.enableBgp;
                    'BGP ASN'                = $data.bgpsettings.asn;
                    'BGP Peering Address'    = $data.bgpSettings.bgpPeeringAddress;
                    'BGP Peer Weight'        = $data.bgpSettings.peerWeight;
                    'Gateway Public IP'      = [string]$data.ipConfigurations.properties.publicIPAddress.id.split("/")[8];
                    'Gateway Subnet Name'    = [string]$data.ipConfigurations.properties.subnet.id.split("/")[8];
                    'Resource U'             = $ResUCount;
                }
                $tmp += $obj
                if ($ResUCount -eq 1) { $ResUCount = 0 }                
            }
            $tmp
        }
}
Else {
    if ($SmaResources.VNETGTW) {

        $TableName = ('VNETGTWTable_'+($SmaResources.VNETGTW.id | Select-Object -Unique).count)
        $Style = New-ExcelStyle -HorizontalAlignment Center -AutoSize -NumberFormat 0

        $condtxt = @()

        $Exc = New-Object System.Collections.Generic.List[System.Object]
        $Exc.Add('Subscription')
        $Exc.Add('Resource Group')
        $Exc.Add('Name')
        $Exc.Add('Location')
        $Exc.Add('SKU')
        $Exc.Add('Active-active mode')
        $Exc.Add('Gateway Type')
        $Exc.Add('Gateway Generation')
        $Exc.Add('VPN Type')
        $Exc.Add('Enable Private Address')
        $Exc.Add('Enable BGP')
        $Exc.Add('BGP ASN')
        $Exc.Add('BGP Peering Address')
        $Exc.Add('BGP Peer Weight')
        $Exc.Add('Gateway Public IP')
        $Exc.Add('Gateway Subnet Name')


        $ExcelVar = $SmaResources.VNETGTW 

        $ExcelVar | 
        ForEach-Object { [PSCustomObject]$_ } | Select-Object -Unique $Exc | 
        Export-Excel -Path $File -WorksheetName 'VNET Gateways' -AutoSize -MaxAutoSizeRows 100 -TableName $TableName -TableStyle $tableStyle -ConditionalText $condtxt -Style $Style
    
    }
}