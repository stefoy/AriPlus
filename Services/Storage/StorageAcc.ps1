param($SCPath, $Sub, $Resources, $Task ,$File, $SmaResources, $TableStyle)

If ($Task -eq 'Processing') {
    <######### Insert the resource extraction here ########>

    $storageacc = $Resources | Where-Object { $_.TYPE -eq 'microsoft.storage/storageaccounts' }

    <######### Insert the resource Process here ########>

    if($storageacc)
        {
            $tmp = @()

            foreach ($1 in $storageacc) {
                $ResUCount = 1
                $sub1 = $SUB | Where-Object { $_.Id -eq $1.subscriptionId }
                $data = $1.PROPERTIES
                $timecreated = $data.creationTime
                $timecreated = [datetime]$timecreated
                $timecreated = $timecreated.ToString("yyyy-MM-dd HH:mm")
                $TLSv = if ($data.minimumTlsVersion -eq 'TLS1_2') { "TLS 1.2" }elseif ($data.minimumTlsVersion -eq 'TLS1_1') { "TLS 1.1" }else { "TLS 1.0" }
                $PvtEnd = [string]$data.privateEndpointConnections.count
                
                $obj = @{
                    'ID'                                    = $1.id;
                    'Subscription'                          = $sub1.Name;
                    'Resource Group'                        = $1.RESOURCEGROUP;
                    'Name'                                  = $1.NAME;
                    'Location'                              = $1.LOCATION;
                    'Zone'                                  = $1.ZONES;
                    'SKU'                                   = $1.sku.name;
                    'Tier'                                  = $1.sku.tier;
                    'Minimum TLS Version'                   = $TLSv;
                    'Access Tier'                           = $data.accessTier;
                    'Primary Location'                      = $data.primaryLocation;
                    'Status Of Primary'                     = $data.statusOfPrimary;
                    'Secondary Location'                    = $data.secondaryLocation;
                    'Hierarchical namespace'                = $data.isHnsEnabled;
                    'Created Time'                          = $timecreated;   
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

    if ($SmaResources.StorageAcc) {

        $TableName = ('StorAccTable_'+($SmaResources.StorageAcc.id | Select-Object -Unique).count)
        $Style = @()
        
        $condtxt = @()

        $Exc = New-Object System.Collections.Generic.List[System.Object]
        $Exc.Add('Subscription')
        $Exc.Add('Resource Group')
        $Exc.Add('Name')
        $Exc.Add('Location')
        $Exc.Add('Zone')
        $Exc.Add('SKU')
        $Exc.Add('Tier')
        $Exc.Add('Minimum TLS Version')
        $Exc.Add('Access Tier')
        $Exc.Add('Primary Location')
        $Exc.Add('Status Of Primary')
        $Exc.Add('Secondary Location')
        $Exc.Add('Hierarchical namespace')
        $Exc.Add('Created Time')

        $ExcelVar = $SmaResources.StorageAcc

        $ExcelVar |
        ForEach-Object { [PSCustomObject]$_ } | Select-Object -Unique $Exc |
        Export-Excel -Path $File -WorksheetName 'Storage Acc' -AutoSize -MaxAutoSizeRows 100 -TableName $TableName -TableStyle $tableStyle -ConditionalText $condtxt -Style $Style
    }
}
