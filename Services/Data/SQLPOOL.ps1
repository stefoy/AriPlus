param($SCPath, $Sub, $Resources, $Task , $File, $SmaResources, $TableStyle) 

if ($Task -eq 'Processing') {

    $SQLPOOL = $Resources | Where-Object { $_.TYPE -eq 'microsoft.sql/servers/elasticPools' }

    if($SQLPOOL)
        {
            $tmp = @()

            foreach ($1 in $SQLPOOL) {          
                $ResUCount = 1
                $sub1 = $SUB | Where-Object { $_.id -eq $1.subscriptionId }
                $data = $1.PROPERTIES
                
                $metricStartTime = (Get-Date).AddDays(-1)
                $metricEndTime = (Get-Date)

                
                $obj = @{
                    'ID'                         = $1.id;
                    'Subscription'               = $sub1.Name;
                    'Resource Group'             = $1.RESOURCEGROUP;
                    'Name'                       = $1.NAME;
                    'Location'                   = $1.LOCATION;
                    'Capacity'                   = $1.sku.Capacity;
                    'Sku'                        = $1.sku.name;
                    'Size'                       = $1.sku.size;
                    'Tier'                       = $1.sku.tier;
                    'Replica Count'              = $data.highAvailabilityReplicaCount;
                    'License'                    = $data.licenseType;
                    'Min Capacity'               = $data.minCapacity;
                    'Max Size (GB)'              = (($data.maxSizeBytes / 1024) / 1024) / 1024;
                    'DB Max Capacity'            = $data.perDatabaseSettings.maxCapacity;
                    'DB Min Capacity'            = $data.perDatabaseSettings.minCapacity;
                    'Zone Redundant'             = $data.zoneRedundant;
                }
                
                $tmp += $obj
                if ($ResUCount -eq 1) { $ResUCount = 0 }           
            }
            $tmp
        }
}
else {
    if ($SmaResources.SQLPOOL) {

        $TableName = ('SqlPoolTable_'+($SmaResources.SQLPOOL.id | Select-Object -Unique).count)
        $Style = New-ExcelStyle -HorizontalAlignment Center -AutoSize -NumberFormat 0
        
        $Exc = New-Object System.Collections.Generic.List[System.Object]
        $Exc.Add('Subscription')
        $Exc.Add('Resource Group')
        $Exc.Add('Name')
        $Exc.Add('Location')
        $Exc.Add('Capacity')
        $Exc.Add('Sku')
        $Exc.Add('Size')
        $Exc.Add('Tier')
        $Exc.Add('Replica Count')
        $Exc.Add('License')
        $Exc.Add('Min Capacity')
        $Exc.Add('Max Size (GB)')
        $Exc.Add('DB Min Capacity')
        $Exc.Add('DB Max Capacity')
        $Exc.Add('Zone Redundant')        

        $ExcelVar = $SmaResources.SQLPOOL 

        $ExcelVar | 
        ForEach-Object { [PSCustomObject]$_ } | Select-Object -Unique $Exc | 
        Export-Excel -Path $File -WorksheetName 'SQL Pools' -AutoSize -MaxAutoSizeRows 100 -TableName $TableName -TableStyle $tableStyle -Style $Style
    }
}
