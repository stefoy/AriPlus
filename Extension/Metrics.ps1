param($Subscriptions, $Resources, $Task ,$File, $Metrics, $TableStyle)

If ($Task -eq 'Processing')
{
    $tmp = @()
    $metricDefs = @()

    $metricsLookbackPeriodDays = -31
    $metricStartTime = (Get-Date).AddDays($metricsLookbackPeriodDays)
    $metricEndTime = (Get-Date)

    $metricTimeOneDay = (Get-Date).AddDays(-1)
    $metricTimeSevenDay = (Get-Date).AddDays(-7)

    # Define VM Metrics
    $virtualMachines =  $Resources | Where-Object {$_.TYPE -eq 'microsoft.compute/virtualmachines'}

    if($virtualMachines)
    {
        foreach ($virtualMachine in $virtualMachines) 
        {
            $subscription = $Subscriptions | Where-Object { $_.id -eq $virtualMachine.subscriptionId }

            $metricDefs += [PSCustomObject]@{ MetricName = 'Percentage CPU'; StartTime = $metricStartTime;  EndTime = $metricEndTime; Interval = '1h';  Aggregation = 'Maximum'; Measure = 'Average'; Id = $virtualMachine.Id; SubName = $subscription.Name; ResourceGroup = $virtualMachine.ResourceGroup; Name = $virtualMachine.Name; Location = $virtualMachine.Location; Service = 'Virtual Machines' }
            $metricDefs += [PSCustomObject]@{ MetricName = 'Available Memory Bytes'; StartTime = $metricStartTime;  EndTime = $metricEndTime; Interval = '1h';  Aggregation = 'Minimum'; Measure = 'Average'; Id = $virtualMachine.Id; SubName = $subscription.Name; ResourceGroup = $virtualMachine.ResourceGroup; Name = $virtualMachine.Name; Location = $virtualMachine.Location; Service = 'Virtual Machines' }
        }
    }

    #Define Storage Account Metrics

    $storageAccounts = $Resources | Where-Object { $_.TYPE -eq 'microsoft.storage/storageaccounts' }

    if($storageAccounts)
    {
        foreach ($storageAccount in $storageAccounts) 
        {
            $subscription = $Subscriptions | Where-Object { $_.id -eq $storageAccount.subscriptionId }

            $metricDefs += [PSCustomObject]@{ MetricName = 'UsedCapacity'; StartTime = $metricTimeOneDay;  EndTime = $metricEndTime; Interval = '1h';  Aggregation = 'Average'; Measure = 'Largest'; Id = $storageAccount.Id; SubName = $subscription.Name; ResourceGroup = $storageAccount.ResourceGroup; Name = $storageAccount.Name; Location = $storageAccount.Location; Service = 'Storage Account' }
            $metricDefs += [PSCustomObject]@{ MetricName = 'Transactions'; StartTime = $metricStartTime;  EndTime = $metricEndTime; Interval = '24h';  Aggregation = 'Total'; Measure = 'Sum'; Id = $storageAccount.Id; SubName = $subscription.Name; ResourceGroup = $storageAccount.ResourceGroup; Name = $storageAccount.Name; Location = $storageAccount.Location; Service = 'Storage Account' }
            $metricDefs += [PSCustomObject]@{ MetricName = 'Egress'; StartTime = $metricTimeOneDay;  EndTime = $metricEndTime; Interval = '1h';  Aggregation = 'Total'; Measure = 'Sum'; Id = $storageAccount.Id; SubName = $subscription.Name; ResourceGroup = $storageAccount.ResourceGroup; Name = $storageAccount.Name; Location = $storageAccount.Location; Service = 'Storage Account' }
            $metricDefs += [PSCustomObject]@{ MetricName = 'Ingress'; StartTime = $metricTimeOneDay;  EndTime = $metricEndTime; Interval = '1h';  Aggregation = 'Total'; Measure = 'Sum'; Id = $storageAccount.Id; SubName = $subscription.Name; ResourceGroup = $storageAccount.ResourceGroup; Name = $storageAccount.Name; Location = $storageAccount.Location; Service = 'Storage Account' }
        }
    }

    #Define Blob Metrics

    if($storageAccounts)
    {
        foreach ($storageAccount in $storageAccounts) 
        {
            $subscription = $Subscriptions | Where-Object { $_.id -eq $storageAccount.subscriptionId }
            $blobResourceId = $storageAccount.id + '/blobServices/default'

            $metricDefs += [PSCustomObject]@{ MetricName = 'ContainerCount'; StartTime = $metricTimeOneDay;  EndTime = $metricEndTime; Interval = '1h';  Aggregation = 'Average'; Measure = 'Largest'; Id = $blobResourceId; SubName = $subscription.Name; ResourceGroup = $storageAccount.ResourceGroup; Name = $storageAccount.Name; Location = $storageAccount.Location; Service = 'Blob Service Account' }
            $metricDefs += [PSCustomObject]@{ MetricName = 'BlobCapacity'; StartTime = $metricTimeOneDay;  EndTime = $metricEndTime; Interval = '1h';  Aggregation = 'Average'; Measure = 'Largest'; Id = $blobResourceId; SubName = $subscription.Name; ResourceGroup = $storageAccount.ResourceGroup; Name = $storageAccount.Name; Location = $storageAccount.Location; Service = 'Blob Service Account' }
            $metricDefs += [PSCustomObject]@{ MetricName = 'BlobCount'; StartTime = $metricTimeOneDay;  EndTime = $metricEndTime; Interval = '1h';  Aggregation = 'Average'; Measure = 'Largest'; Id = $blobResourceId; SubName = $subscription.Name; ResourceGroup = $storageAccount.ResourceGroup; Name = $storageAccount.Name; Location = $storageAccount.Location; Service = 'Blob Service Account' }
            $metricDefs += [PSCustomObject]@{ MetricName = 'Transactions'; StartTime = $metricStartTime;  EndTime = $metricEndTime; Interval = '24h';  Aggregation = 'Average'; Measure = 'Sum'; Id = $blobResourceId; SubName = $subscription.Name; ResourceGroup = $storageAccount.ResourceGroup; Name = $storageAccount.Name; Location = $storageAccount.Location; Service = 'Blob Service Account' }
            $metricDefs += [PSCustomObject]@{ MetricName = 'Egress'; StartTime = $metricStartTime;  EndTime = $metricEndTime; Interval = '1h';  Aggregation = 'Total'; Measure = 'Sum'; Id = $blobResourceId; SubName = $subscription.Name; ResourceGroup = $storageAccount.ResourceGroup; Name = $storageAccount.Name; Location = $storageAccount.Location; Service = 'Blob Service Account' }
            $metricDefs += [PSCustomObject]@{ MetricName = 'Ingress'; StartTime = $metricStartTime;  EndTime = $metricEndTime; Interval = '1h';  Aggregation = 'Total'; Measure = 'Sum'; Id = $blobResourceId; SubName = $subscription.Name; ResourceGroup = $storageAccount.ResourceGroup; Name = $storageAccount.Name; Location = $storageAccount.Location; Service = 'Blob Service Account' }
        }
    }

    #Define SQL Metrics

    $sqlDatabases = $Resources | Where-Object { $_.TYPE -eq 'microsoft.sql/servers/databases' -and $_.name -ne 'master' }

    if($sqlDatabases)
    {
        foreach ($sqlDb in $sqlDatabases) 
        {
            $subscription = $Subscriptions | Where-Object { $_.id -eq $storageAccount.subscriptionId }
            
            if ($sqlDb.kind.Contains("vcore")) 
            {
                $metricDefs += [PSCustomObject]@{ MetricName = 'cpu_limit'; StartTime = $metricStartTime;  EndTime = $metricEndTime; Interval = '24h';  Aggregation = 'Maximum'; Measure = 'Largest'; Id = $sqlDb.Id; SubName = $sqlDb.Name; ResourceGroup = $sqlDb.ResourceGroup; Name = $sqlDb.Name; Location = $sqlDb.Location; Service = 'SQL Database' }
                $metricDefs += [PSCustomObject]@{ MetricName = 'cpu_used'; StartTime = $metricStartTime;  EndTime = $metricEndTime; Interval = '1h';  Aggregation = 'Maximum'; Measure = 'Average'; Id = $sqlDb.Id; SubName = $sqlDb.Name; ResourceGroup = $sqlDb.ResourceGroup; Name = $sqlDb.Name; Location = $sqlDb.Location; Service = 'SQL Database' }               
            }
            else 
            {
                $metricDefs += [PSCustomObject]@{ MetricName = 'dtu_limit'; StartTime = $metricStartTime;  EndTime = $metricEndTime; Interval = '24h';  Aggregation = 'Maximum'; Measure = 'Largest'; Id = $sqlDb.Id; SubName = $sqlDb.Name; ResourceGroup = $sqlDb.ResourceGroup; Name = $sqlDb.Name; Location = $sqlDb.Location; Service = 'SQL Database' }
                $metricDefs += [PSCustomObject]@{ MetricName = 'dtu_used'; StartTime = $metricStartTime;  EndTime = $metricEndTime; Interval = '1h';  Aggregation = 'Maximum'; Measure = 'Average'; Id = $sqlDb.Id; SubName = $sqlDb.Name; ResourceGroup = $sqlDb.ResourceGroup; Name = $sqlDb.Name; Location = $sqlDb.Location; Service = 'SQL Database' }
            }
            
            $metricDefs += [PSCustomObject]@{ MetricName = 'allocated_data_storage'; StartTime = $metricTimeOneDay;  EndTime = $metricEndTime; Interval = '24h';  Aggregation = 'Average'; Measure = 'Largest'; Id = $sqlDb.Id; SubName = $sqlDb.Name; ResourceGroup = $sqlDb.ResourceGroup; Name = $sqlDb.Name; Location = $sqlDb.Location; Service = 'SQL Database' }
            $metricDefs += [PSCustomObject]@{ MetricName = 'storage'; StartTime = $metricTimeOneDay;  EndTime = $metricEndTime; Interval = '24h';  Aggregation = 'Average'; Measure = 'Largest'; Id = $sqlDb.Id; SubName = $sqlDb.Name; ResourceGroup = $sqlDb.ResourceGroup; Name = $sqlDb.Name; Location = $sqlDb.Location; Service = 'SQL Database' }
            $metricDefs += [PSCustomObject]@{ MetricName = 'physical_data_read_percent'; StartTime = $metricTimeSevenDay;  EndTime = $metricEndTime; Interval = '1h';  Aggregation = 'Average'; Measure = 'Largest'; Id = $sqlDb.Id; SubName = $sqlDb.Name; ResourceGroup = $sqlDb.ResourceGroup; Name = $sqlDb.Name; Location = $sqlDb.Location; Service = 'SQL Database' }
            $metricDefs += [PSCustomObject]@{ MetricName = 'log_write_percent'; StartTime = $metricTimeSevenDay;  EndTime = $metricEndTime; Interval = '1h';  Aggregation = 'Average'; Measure = 'Largest'; Id = $sqlDb.Id; SubName = $sqlDb.Name; ResourceGroup = $sqlDb.ResourceGroup; Name = $sqlDb.Name; Location = $sqlDb.Location; Service = 'SQL Database' }
        }
    }

    # Run Metrics Queries
    foreach($metricDef in $metricDefs)
    {
        Write-Host ("Processing {0} Metrics: {1}-{2}" -f $metricDef.Service, $metricDef.Name, $metricDef.MetricName) -BackgroundColor Black -ForegroundColor Green

        $metricQuery = (az monitor metrics list --resource $metricDef.Id --metric $metricDef.MetricName --start-time $metricDef.StartTime  --end-time $metricDef.EndTime --interval $metricDef.Interval --aggregation $metricDef.Aggregation | ConvertFrom-Json)
        
        $metricQueryResults = 0

        switch ($metricDef.Aggregation)
        {
            'Average'   { $metricQueryResults = $metricQuery.value.timeseries.data.average }
            'Maximum'   { $metricQueryResults = $metricQuery.value.timeseries.data.maximum }
            'Total'     { $metricQueryResults = $metricQuery.value.timeseries.data.total }
            'Minimum'   { $metricQueryResults = $metricQuery.value.timeseries.data.minimum }
        }

        $metricQueryResultsCount = ($metricQueryResults.Where({$_ -ne $null}).Count)

        switch ($metricDef.Measure)
        {
            'Average'   { $metricQueryResults = ($metricQueryResults | Measure-Object -Average).Average }
            'Maximum'   { $metricQueryResults = ($metricQueryResults | Measure-Object -Maximum).Maximum }
            'Sum'     { $metricQueryResults = ($metricQueryResults | Measure-Object -Sum).Sum }
            'Minimum'   { $metricQueryResults = ($metricQueryResults | Measure-Object -Minimum).Minimum }
            'Largest'   { $metricQueryResults = ($metricQueryResults | Sort-Object -Descending)[0] }
        }

        $obj = @{
            'ID'                = $metricDef.Id;
            'Subscription'      = $metricDef.SubName;
            'Resource Group'    = $metricDef.ResourceGroup;
            'Name'              = $metricDef.Name;
            'Location'          = $metricDef.Location;
            'Service'           = $metricDef.Service;
            'Metric'            = $metricDef.MetricName;
            'Metric Aggregate'  = $metricDef.Aggregation;
            'Metric Time Grain' = $metricDef.Interval;
            'Metric Value'      = $metricQueryResults;
            'Metric Count'      = $metricQueryResultsCount;
        }

        $tmp += $obj

        $metricQuery = $null
        $metricQueryResults = $null
        $metricQueryResultsCount = $null

        #$([System.GC]::GetTotalMemory($false))
        [System.GC]::Collect()
        #$([System.GC]::GetTotalMemory($true))
    }

    $tmp
}
else 
{
    $Style = New-ExcelStyle -HorizontalAlignment Center -AutoSize -NumberFormat '0'
    
    $Metrics | 
        ForEach-Object { [PSCustomObject]$_ } | 
        Select-Object 'Subscription',
        'Resource Group',
        'Name',
        'Location',
        'Service',
        'Metric',
        'Metric Aggregate',
        'Metric Time Grain',
        'Metric Value',
        'Metric Count' | Export-Excel -Path $File -WorksheetName 'Metrics' -AutoSize -MaxAutoSizeRows 100 -TableName 'Metrics' -TableStyle $tableStyle -Style $Style -Numberformat '0' -MoveToEnd 
}
