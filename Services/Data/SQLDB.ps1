param($SCPath, $Sub, $Resources, $Task , $File, $SmaResources, $TableStyle, $Metrics) 

if ($Task -eq 'Processing') 
{
    $SQLDB = $Resources | Where-Object { $_.TYPE -eq 'microsoft.sql/servers/databases' -and $_.name -ne 'master' }
    $sqlMetrics = $Metrics.Metrics | Where-Object { $_.Service -eq 'SQL Database' }

    if($SQLDB)
    {
        $tmp = @()

        foreach ($1 in $SQLDB) 
        {
            $sub1 = $SUB | Where-Object { $_.id -eq $1.subscriptionId }
            $data = $1.PROPERTIES
            $DBServer = [string]$1.id.split("/")[8]

            if (![string]::IsNullOrEmpty($data.elasticPoolId)) { $PoolId = $data.elasticPoolId.Split("/")[10] } else { $PoolId = "None"}
            if ($1.kind.Contains("vcore")) { $SqlType = "vcore" } else { $SqlType = "dtu"}

            $sqlDbMetrics = $sqlMetrics | Where-Object { $_.Id -eq $1.id }
            $sqlAllocatedStorage = $sqlDbMetrics | Where-Object { $_.Metric -eq 'allocated_data_storage' }
            $sqlStorage = $sqlDbMetrics | Where-Object { $_.Metric -eq 'storage' }
            $sqlPhysicalReadPercent = $sqlDbMetrics | Where-Object { $_.Metric -eq 'physical_data_read_percent' }
            $sqlLogWritePercent = $sqlDbMetrics | Where-Object { $_.Metric -eq 'log_write_percent' }

            if ($SqlType -eq 'vcore') 
            {
                $sqlDtuLimit = $sqlDbMetrics | Where-Object { $_.Metric -eq 'cpu_limit' }
                $sqlDtuUsed = $sqlDbMetrics | Where-Object { ($_.Metric -eq 'cpu_used') -and ($_.MetricMeasure -eq 'Average') }
            }
            else 
            {
                $sqlDtuLimit = $sqlDbMetrics | Where-Object { $_.Metric -eq 'dtu_limit' }
                $sqlDtuUsed = $sqlDbMetrics | Where-Object { ($_.Metric -eq 'dtu_used') -and ($_.MetricMeasure -eq 'Average') }
            }  

            $obj = @{
                'ID'                         = $1.id;
                'Subscription'               = $sub1.Name;
                'ResourceGroup'              = $1.RESOURCEGROUP;
                'Name'                       = $1.NAME;
                'Location'                   = $1.LOCATION;
                'StorageAccountType'         = $data.storageAccountType;
                'DatabaseServer'             = $DBServer;
                'SecondaryLocation'          = $data.defaultSecondaryLocation;
                'Status'                     = $data.status;
                'Tier'                       = $data.currentSku.Tier;
                'Type'                       = $SqlType;
                'Capacity'                   = $data.currentSku.capacity;
                'Sku'                        = $data.requestedServiceObjectiveName;
                'ZoneRedundant'              = $data.zoneRedundant;
                'License'                    = if ($null -ne $data.licenseType) { $data.licenseType } else { 'License Included' }
                'CatalogCollation'           = $data.catalogCollation;
                'ReadReplicaCount'           = if ($null -ne $data.readReplicaCount) { $data.readReplicaCount } else { '0' }
                'DataMaxSizeGB'              = (($data.maxSizeBytes / 1024) / 1024) / 1024;
                'ElasticPoolID'              = $PoolId;
                'DtuLimit'                   = if ($null -ne $sqlDtuLimit.MetricValue) { $sqlDtuLimit.MetricValue } else { '0' }
                'DtuUsed'                    = if ($null -ne $sqlDtuUsed.MetricValue) { $sqlDtuUsed.MetricValue } else { '0' }
                'AllocatedDataStorage'       = if ($null -ne $sqlAllocatedStorage.MetricValue) { $sqlAllocatedStorage.MetricValue } else { '0' }
                'Storage'                    = if ($null -ne $sqlStorage.MetricValue) { $sqlStorage.MetricValue } else { '0' }
                'ReadPercent'                = if ($null -ne $sqlPhysicalReadPercent.MetricValue) { $sqlPhysicalReadPercent.MetricValue } else { '0' }
                'WritePercent'               = if ($null -ne $sqlLogWritePercent.MetricValue) { $sqlLogWritePercent.MetricValue } else { '0' }
            }

            $tmp += $obj 
        }

        $tmp
    }
}
else 
{
    if ($SmaResources.SQLDB) 
    {
        $TableName = ('SQLDBTable_'+($SmaResources.SQLDB.id | Select-Object -Unique).count)

        $Style = @()
        $Style += New-ExcelStyle -HorizontalAlignment Center -AutoSize -NumberFormat 0
        
        $Exc = New-Object System.Collections.Generic.List[System.Object]
        $Exc.Add('Subscription')
        $Exc.Add('ResourceGroup')
        $Exc.Add('Name')
        $Exc.Add('Location')
        $Exc.Add('StorageAccountType')
        $Exc.Add('DatabaseServer')
        $Exc.Add('SecondaryLocation')
        $Exc.Add('Status')
        $Exc.Add('Type')
        $Exc.Add('Tier')
        $Exc.Add('Sku')
        $Exc.Add('License')
        $Exc.Add('Capacity')     
        $Exc.Add('DataMaxSizeGB')
        $Exc.Add('ZoneRedundant')
        $Exc.Add('CatalogCollation')
        $Exc.Add('ReadReplicaCount')
        $Exc.Add('ElasticPoolID')
        $Exc.Add('DtuLimit')
        $Exc.Add('DtuUsed')
        $Exc.Add('AllocatedDataStorage')
        $Exc.Add('Storage')
        $Exc.Add('ReadPercent')
        $Exc.Add('WritePercent')

        $ExcelVar = $SmaResources.SQLDB 

        $ExcelVar | 
        ForEach-Object { [PSCustomObject]$_ } | Select-Object -Unique $Exc | 
        Export-Excel -Path $File -WorksheetName 'SQL DBs' -AutoSize -MaxAutoSizeRows 100 -TableName $TableName -TableStyle $tableStyle -Style $Style
    }
}