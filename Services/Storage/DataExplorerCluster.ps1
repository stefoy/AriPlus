param($SCPath, $Sub, $Resources, $Task ,$File, $SmaResources, $TableStyle, $Metrics)

If ($Task -eq 'Processing') {

    $DataExplorer = $Resources | Where-Object { $_.TYPE -eq 'microsoft.kusto/clusters' }

    if($DataExplorer)
        {
            $tmp = @()

            foreach ($1 in $DataExplorer) {
                $ResUCount = 1
                $sub1 = $SUB | Where-Object { $_.Id -eq $1.subscriptionId }
                $data = $1.PROPERTIES
                $sku = $1.SKU
                $VNET = $data.virtualNetworkConfiguration.subnetid.split('/')[8]
                $Subnet = $data.virtualNetworkConfiguration.subnetid.split('/')[10]
                $DataPIP = $data.virtualNetworkConfiguration.dataManagementPublicIpId.split('/')[8]
                $EnginePIP = $data.virtualNetworkConfiguration.enginePublicIpId.split('/')[8]
                $TenantPerm = if($data.trustedExternalTenants.value -eq '*'){'All Tenants'}else{$data.trustedExternalTenants.value}
                $AutoScale = if($data.optimizedAutoscale.isEnabled -eq 'true'){'Enabled'}else{'Disabled'}
                
                $obj = @{
                    'ID'                        = $1.id;
                    'Subscription'              = $sub1.Name;
                    'Resource Group'            = $1.RESOURCEGROUP;
                    'Name'                      = $1.NAME;
                    'Location'                  = $1.LOCATION;
                    'Compute specifications'    = $sku.name;
                    'Instance count'            = $sku.capacity;
                    'State'                     = $data.state;
                    'State Reason'              = $data.stateReason;
                    'Virtual Network'           = $VNET;
                    'Subnet'                    = $Subnet;
                    'Disk Encryption'           = $data.enableDiskEncryption;
                    'Streaming Ingestion'       = $data.enableStreamingIngest;
                    'Optimized Autoscale'       = $AutoScale;
                    'Optimized Autoscale Min'   = $data.optimizedAutoscale.minimum;
                    'Optimized Autoscale Max'   = $data.optimizedAutoscale.maximum;
                    'Resource U'                = $ResUCount;
                }
                $tmp += $obj
                if ($ResUCount -eq 1) { $ResUCount = 0 }               
            }
            $tmp
        }
}
<######## Resource Excel Reporting Begins Here ########>

Else {
    <######## $SmaResources.(RESOURCE FILE NAME) ##########>

    if ($SmaResources.DataExplorerCluster) {

        $TableName = ('DTExplTable_'+($SmaResources.DataExplorerCluster.id | Select-Object -Unique).count)
        $Style = New-ExcelStyle -HorizontalAlignment Center -AutoSize -NumberFormat 0

        $condtxt = @()
        $condtxt += New-ConditionalText 'All Tenants' -Range M:M
        $condtxt += New-ConditionalText FALSO -Range N:N
        $condtxt += New-ConditionalText FALSE -Range N:N
        $condtxt += New-ConditionalText Disabled -Range P:P


        $Exc = New-Object System.Collections.Generic.List[System.Object]
        $Exc.Add('Subscription')
        $Exc.Add('Resource Group')
        $Exc.Add('Name')
        $Exc.Add('Location')
        $Exc.Add('Compute specifications')
        $Exc.Add('Instance count')
        $Exc.Add('State')
        $Exc.Add('State Reason')
        $Exc.Add('Virtual Network')
        $Exc.Add('Subnet')
        $Exc.Add('Disk Encryption')
        $Exc.Add('Streaming Ingestion')
        $Exc.Add('Optimized Autoscale')
        $Exc.Add('Optimized Autoscale Min')
        $Exc.Add('Optimized Autoscale Max')

        $ExcelVar = $SmaResources.DataExplorerCluster 

        $ExcelVar | 
        ForEach-Object { [PSCustomObject]$_ } | Select-Object -Unique $Exc | 
        Export-Excel -Path $File -WorksheetName 'Data Explorer Clusters' -AutoSize -MaxAutoSizeRows 100 -TableName $TableName -TableStyle $tableStyle -ConditionalText $condtxt -Style $Style

    }
    <######## Insert Column comments and documentations here following this model #########>
}
