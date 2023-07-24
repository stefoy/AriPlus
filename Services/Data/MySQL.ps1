param($SCPath, $Sub, $Resources, $Task ,$File, $SmaResources, $TableStyle, $Metrics)

If ($Task -eq 'Processing') {

    $MySQL = $Resources | Where-Object { $_.TYPE -eq 'microsoft.dbformysql/servers' }

    if($MySQL)
        {
            $tmp = @()

            foreach ($1 in $MySQL) {
                $ResUCount = 1
                $sub1 = $SUB | Where-Object { $_.id -eq $1.subscriptionId }
                $data = $1.PROPERTIES
                if(!$data.privateEndpointConnections){$PVTENDP = $false}else{$PVTENDP = $data.privateEndpointConnections.Id.split("/")[8]}
                $sku = $1.SKU
                
                $obj = @{
                    'ID'                        = $1.id;
                    'Subscription'              = $sub1.Name;
                    'Resource Group'            = $1.RESOURCEGROUP;
                    'Name'                      = $1.NAME;
                    'Location'                  = $1.LOCATION;
                    'SKU'                       = $sku.name;
                    'SKU Family'                = $sku.family;
                    'Tier'                      = $sku.tier;
                    'Capacity'                  = $sku.capacity;
                    'MySQL Version'             = "=$($data.version)";
                    'Backup Retention Days'     = $data.storageProfile.backupRetentionDays;
                    'Geo-Redundant Backup'      = $data.storageProfile.geoRedundantBackup;
                    'Auto Grow'                 = $data.storageProfile.storageAutogrow;
                    'Storage MB'                = $data.storageProfile.storageMB;
                    'Minimum TLS Version'       = "$($data.minimalTlsVersion -Replace '_', '.' -Replace 'tls', 'TLS ')";
                    'State'                     = $data.userVisibleState;
                    'Replica Capacity'          = $data.replicaCapacity;
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

    if ($SmaResources.MySQL) {

        $TableName = ('MySQLTable_'+($SmaResources.MySQL.id | Select-Object -Unique).count)
        $Style = New-ExcelStyle -HorizontalAlignment Center -AutoSize -NumberFormat 0.0

        $condtxt = @()
        $condtxt += New-ConditionalText FALSE -Range J:J
        $condtxt += New-ConditionalText FALSO -Range J:J
        $condtxt += New-ConditionalText Disabled -Range L:L
        $condtxt += New-ConditionalText Enabled -Range O:O
        $condtxt += New-ConditionalText TLSEnforcementDisabled -Range R:R
        $condtxt += New-ConditionalText Disabled -Range W:W

        $Exc = New-Object System.Collections.Generic.List[System.Object]
        $Exc.Add('Subscription')
        $Exc.Add('Resource Group')
        $Exc.Add('Name')
        $Exc.Add('Location')
        $Exc.Add('SKU')
        $Exc.Add('SKU Family')
        $Exc.Add('Tier')
        $Exc.Add('Capacity')
        $Exc.Add('MySQL Version')
        $Exc.Add('Backup Retention Days')
        $Exc.Add('Geo-Redundant Backup')
        $Exc.Add('Auto Grow')
        $Exc.Add('Storage MB')
        $Exc.Add('Minimum TLS Version')
        $Exc.Add('State')
        $Exc.Add('Replica Capacity')

        $ExcelVar = $SmaResources.MySQL

        $ExcelVar | 
        ForEach-Object { [PSCustomObject]$_ } | Select-Object -Unique $Exc | 
        Export-Excel -Path $File -WorksheetName 'MySQL' -AutoSize -MaxAutoSizeRows 100 -TableName $TableName -TableStyle $tableStyle -ConditionalText $condtxt -Style $Style

    }
    <######## Insert Column comments and documentations here following this model #########>
}
