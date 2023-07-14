param($Subscriptions, $Resources, $Task ,$File, $Metrics, $TableStyle, $ConcurrencyLimit)

If ($Task -eq 'Processing')
{
    $tmp = [System.Collections.Concurrent.ConcurrentBag[psobject]]::new()
    $tmpParallel = [System.Collections.Concurrent.ConcurrentBag[psobject]]::new()


    $metricDefs = [System.Collections.Generic.List[object]]::new()

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

            $metricDefs.Add([PSCustomObject]@{ MetricName = 'Percentage CPU'; StartTime = $metricStartTime;  EndTime = $metricEndTime; Interval = '1h';  Aggregation = 'Maximum'; Measure = 'Average'; Id = $virtualMachine.Id; SubName = $subscription.Name; ResourceGroup = $virtualMachine.ResourceGroup; Name = $virtualMachine.Name; Location = $virtualMachine.Location; Service = 'Virtual Machines' })
            $metricDefs.Add([PSCustomObject]@{ MetricName = 'Available Memory Bytes'; StartTime = $metricStartTime;  EndTime = $metricEndTime; Interval = '1h';  Aggregation = 'Minimum'; Measure = 'Average'; Id = $virtualMachine.Id; SubName = $subscription.Name; ResourceGroup = $virtualMachine.ResourceGroup; Name = $virtualMachine.Name; Location = $virtualMachine.Location; Service = 'Virtual Machines' })
        }
    }

    #Define Storage Account Metrics

    $storageAccounts = $Resources | Where-Object { $_.TYPE -eq 'microsoft.storage/storageaccounts' }

    if($storageAccounts)
    {
        foreach ($storageAccount in $storageAccounts) 
         {
             $subscription = $Subscriptions | Where-Object { $_.id -eq $storageAccount.subscriptionId }

             $metricDefs.Add([PSCustomObject]@{ MetricName = 'UsedCapacity'; StartTime = $metricTimeOneDay;  EndTime = $metricEndTime; Interval = '1h';  Aggregation = 'Average'; Measure = 'Largest'; Id = $storageAccount.Id; SubName = $subscription.Name; ResourceGroup = $storageAccount.ResourceGroup; Name = $storageAccount.Name; Location = $storageAccount.Location; Service = 'Storage Account' })
             $metricDefs.Add([PSCustomObject]@{ MetricName = 'Transactions'; StartTime = $metricTimeSevenDay;  EndTime = $metricEndTime; Interval = '24h';  Aggregation = 'Total'; Measure = 'Sum'; Id = $storageAccount.Id; SubName = $subscription.Name; ResourceGroup = $storageAccount.ResourceGroup; Name = $storageAccount.Name; Location = $storageAccount.Location; Service = 'Storage Account' })
             $metricDefs.Add([PSCustomObject]@{ MetricName = 'Egress'; StartTime = $metricTimeOneDay;  EndTime = $metricEndTime; Interval = '1h';  Aggregation = 'Total'; Measure = 'Sum'; Id = $storageAccount.Id; SubName = $subscription.Name; ResourceGroup = $storageAccount.ResourceGroup; Name = $storageAccount.Name; Location = $storageAccount.Location; Service = 'Storage Account' })
             $metricDefs.Add([PSCustomObject]@{ MetricName = 'Ingress'; StartTime = $metricTimeOneDay;  EndTime = $metricEndTime; Interval = '1h';  Aggregation = 'Total'; Measure = 'Sum'; Id = $storageAccount.Id; SubName = $subscription.Name; ResourceGroup = $storageAccount.ResourceGroup; Name = $storageAccount.Name; Location = $storageAccount.Location; Service = 'Storage Account' })
         }
    }

    #Define Blob Metrics

     if($storageAccounts)
     {
         foreach ($storageAccount in $storageAccounts) 
         {
             $subscription = $Subscriptions | Where-Object { $_.id -eq $storageAccount.subscriptionId }
             $blobResourceId = $storageAccount.id + '/blobServices/default'

             $metricDefs.Add([PSCustomObject]@{ MetricName = 'ContainerCount'; StartTime = $metricTimeOneDay;  EndTime = $metricEndTime; Interval = '1h';  Aggregation = 'Average'; Measure = 'Largest'; Id = $blobResourceId; SubName = $subscription.Name; ResourceGroup = $storageAccount.ResourceGroup; Name = $storageAccount.Name; Location = $storageAccount.Location; Service = 'Blob Service Account' })
             $metricDefs.Add([PSCustomObject]@{ MetricName = 'BlobCapacity'; StartTime = $metricTimeOneDay;  EndTime = $metricEndTime; Interval = '1h';  Aggregation = 'Average'; Measure = 'Largest'; Id = $blobResourceId; SubName = $subscription.Name; ResourceGroup = $storageAccount.ResourceGroup; Name = $storageAccount.Name; Location = $storageAccount.Location; Service = 'Blob Service Account' })
             $metricDefs.Add([PSCustomObject]@{ MetricName = 'BlobCount'; StartTime = $metricTimeOneDay;  EndTime = $metricEndTime; Interval = '1h';  Aggregation = 'Average'; Measure = 'Largest'; Id = $blobResourceId; SubName = $subscription.Name; ResourceGroup = $storageAccount.ResourceGroup; Name = $storageAccount.Name; Location = $storageAccount.Location; Service = 'Blob Service Account' })
             $metricDefs.Add([PSCustomObject]@{ MetricName = 'Transactions'; StartTime = $metricTimeSevenDay;  EndTime = $metricEndTime; Interval = '24h';  Aggregation = 'Average'; Measure = 'Sum'; Id = $blobResourceId; SubName = $subscription.Name; ResourceGroup = $storageAccount.ResourceGroup; Name = $storageAccount.Name; Location = $storageAccount.Location; Service = 'Blob Service Account' })
             $metricDefs.Add([PSCustomObject]@{ MetricName = 'Egress'; StartTime = $metricStartTime;  EndTime = $metricEndTime; Interval = '1h';  Aggregation = 'Total'; Measure = 'Sum'; Id = $blobResourceId; SubName = $subscription.Name; ResourceGroup = $storageAccount.ResourceGroup; Name = $storageAccount.Name; Location = $storageAccount.Location; Service = 'Blob Service Account' })
             $metricDefs.Add([PSCustomObject]@{ MetricName = 'Ingress'; StartTime = $metricStartTime;  EndTime = $metricEndTime; Interval = '1h';  Aggregation = 'Total'; Measure = 'Sum'; Id = $blobResourceId; SubName = $subscription.Name; ResourceGroup = $storageAccount.ResourceGroup; Name = $storageAccount.Name; Location = $storageAccount.Location; Service = 'Blob Service Account' })
         }
     }

    #Define SQL Metrics

    $sqlDatabases = $Resources | Where-Object { $_.TYPE -eq 'microsoft.sql/servers/databases' -and $_.name -ne 'master' }

    if($sqlDatabases)
    {
        foreach ($sqlDb in $sqlDatabases) 
        {
            $subscription = $Subscriptions | Where-Object { $_.id -eq $sqlDb.subscriptionId }
            
            if ($sqlDb.kind.Contains("vcore")) 
            {
                $metricDefs.Add([PSCustomObject]@{ MetricName = 'cpu_limit'; StartTime = $metricTimeSevenDay;  EndTime = $metricEndTime; Interval = '24h';  Aggregation = 'Maximum'; Measure = 'Largest'; Id = $sqlDb.Id; SubName = $subscription.Name; ResourceGroup = $sqlDb.ResourceGroup; Name = $sqlDb.Name; Location = $sqlDb.Location; Service = 'SQL Database' })
                $metricDefs.Add([PSCustomObject]@{ MetricName = 'cpu_used'; StartTime = $metricTimeSevenDay;  EndTime = $metricEndTime; Interval = '1h';  Aggregation = 'Maximum'; Measure = 'Average'; Id = $sqlDb.Id; SubName = $subscription.Name; ResourceGroup = $sqlDb.ResourceGroup; Name = $sqlDb.Name; Location = $sqlDb.Location; Service = 'SQL Database' })             
            }
            else 
            {
                $metricDefs.Add([PSCustomObject]@{ MetricName = 'dtu_limit'; StartTime = $metricTimeSevenDay;  EndTime = $metricEndTime; Interval = '24h';  Aggregation = 'Maximum'; Measure = 'Largest'; Id = $sqlDb.Id; SubName = $subscription.Name; ResourceGroup = $sqlDb.ResourceGroup; Name = $sqlDb.Name; Location = $sqlDb.Location; Service = 'SQL Database' })
                $metricDefs.Add([PSCustomObject]@{ MetricName = 'dtu_used'; StartTime = $metricTimeSevenDay;  EndTime = $metricEndTime; Interval = '1h';  Aggregation = 'Maximum'; Measure = 'Average'; Id = $sqlDb.Id; SubName = $subscription.Name; ResourceGroup = $sqlDb.ResourceGroup; Name = $sqlDb.Name; Location = $sqlDb.Location; Service = 'SQL Database' })
            }
            
            $metricDefs.Add([PSCustomObject]@{ MetricName = 'allocated_data_storage'; StartTime = $metricTimeOneDay;  EndTime = $metricEndTime; Interval = '24h';  Aggregation = 'Average'; Measure = 'Largest'; Id = $sqlDb.Id; SubName = $subscription.Name; ResourceGroup = $sqlDb.ResourceGroup; Name = $sqlDb.Name; Location = $sqlDb.Location; Service = 'SQL Database' })
            $metricDefs.Add([PSCustomObject]@{ MetricName = 'storage'; StartTime = $metricTimeOneDay;  EndTime = $metricEndTime; Interval = '24h';  Aggregation = 'Average'; Measure = 'Largest'; Id = $sqlDb.Id; SubName = $subscription.Name; ResourceGroup = $sqlDb.ResourceGroup; Name = $sqlDb.Name; Location = $sqlDb.Location; Service = 'SQL Database' })
            $metricDefs.Add([PSCustomObject]@{ MetricName = 'physical_data_read_percent'; StartTime = $metricTimeSevenDay;  EndTime = $metricEndTime; Interval = '1h';  Aggregation = 'Average'; Measure = 'Largest'; Id = $sqlDb.Id; SubName = $subscription.Name; ResourceGroup = $sqlDb.ResourceGroup; Name = $sqlDb.Name; Location = $sqlDb.Location; Service = 'SQL Database' })
            $metricDefs.Add([PSCustomObject]@{ MetricName = 'log_write_percent'; StartTime = $metricTimeSevenDay;  EndTime = $metricEndTime; Interval = '1h';  Aggregation = 'Average'; Measure = 'Largest'; Id = $sqlDb.Id; SubName = $subscription.Name; ResourceGroup = $sqlDb.ResourceGroup; Name = $sqlDb.Name; Location = $sqlDb.Location; Service = 'SQL Database' })
        }
    }

    # Define App Service Metrics

    $appServices = $Resources | Where-Object { $_.TYPE -eq 'microsoft.web/sites' }
    
    if($appServices)
    {
        foreach ($app in $appServices) 
        {
            $subscription = $Subscriptions | Where-Object { $_.id -eq $app.subscriptionId }
            
            if ($app.kind.Contains("functionapp")) 
            {
                $metricDefs.Add([PSCustomObject]@{ MetricName = 'FunctionExecutionCount'; StartTime = $metricTimeSevenDay;  EndTime = $metricEndTime; Interval = '24h';  Aggregation = 'Total'; Measure = 'Sum'; Id = $app.Id; SubName = $subscription.Name; ResourceGroup = $app.ResourceGroup; Name = $app.Name; Location = $app.Location; Service = 'Functions' })
                $metricDefs.Add([PSCustomObject]@{ MetricName = 'FunctionExecutionUnits'; StartTime = $metricTimeSevenDay;  EndTime = $metricEndTime; Interval = '24h';  Aggregation = 'Total'; Measure = 'Sum'; Id = $app.Id; SubName = $subscription.Name; ResourceGroup = $app.ResourceGroup; Name = $app.Name; Location = $app.Location; Service = 'Functions' })              
            }
        }
    }

    # Define Scale Set Metrics

    $vmScaleSets = $Resources | Where-Object { $_.TYPE -eq 'microsoft.compute/virtualmachinescalesets' }
    
    if($vmScaleSets)
    {
        foreach ($vmss in $vmScaleSets) 
        {
            $subscription = $Subscriptions | Where-Object { $_.id -eq $vmss.subscriptionId }
            
            $metricDefs.Add([PSCustomObject]@{ MetricName = 'Percentage CPU'; StartTime = $metricStartTime;  EndTime = $metricEndTime; Interval = '1h';  Aggregation = 'Maximum'; Measure = 'Average'; Id = $vmss.Id; SubName = $subscription.Name; ResourceGroup = $vmss.ResourceGroup; Name = $vmss.Name; Location = $vmss.Location; Service = 'Virtual Machines Scale Sets' })
            $metricDefs.Add([PSCustomObject]@{ MetricName = 'Available Memory Bytes'; StartTime = $metricStartTime;  EndTime = $metricEndTime; Interval = '1h';  Aggregation = 'Minimum'; Measure = 'Average'; Id = $vmss.Id; SubName = $subscription.Name; ResourceGroup = $vmss.ResourceGroup; Name = $vmss.Name; Location = $vmss.Location; Service = 'Virtual Machines Scale Sets' })
        }
    }

    $metricCount = $metricDefs.Count
    $metricCurrent = 0

    $metricDefs | ForEach-Object -Parallel {
        
        Write-Host ("Processing {0} Metrics: {1}-{2}" -f $_.Service, $_.Name, $_.MetricName) -BackgroundColor Black -ForegroundColor Green

        $metricQuery = (az monitor metrics list --resource $_.Id --metric $_.MetricName --start-time $_.StartTime  --end-time $_.EndTime --interval $_.Interval --aggregation $_.Aggregation | ConvertFrom-Json)
        
        $metricQueryResults = 0

        switch ($_.Aggregation)
        {
            'Average'   { $metricQueryResults = $metricQuery.value.timeseries.data.average }
            'Maximum'   { $metricQueryResults = $metricQuery.value.timeseries.data.maximum }
            'Total'     { $metricQueryResults = $metricQuery.value.timeseries.data.total }
            'Minimum'   { $metricQueryResults = $metricQuery.value.timeseries.data.minimum }
        }

        $metricQueryResultsCount = ($metricQueryResults.Where({$_ -ne $null}).Count)

        switch ($_.Measure)
        {
            'Average'   { $metricQueryResults = ($metricQueryResults | Measure-Object -Average).Average }
            'Maximum'   { $metricQueryResults = ($metricQueryResults | Measure-Object -Maximum).Maximum }
            'Sum'       { $metricQueryResults = ($metricQueryResults | Measure-Object -Sum).Sum }
            'Minimum'   { $metricQueryResults = ($metricQueryResults | Measure-Object -Minimum).Minimum }
            'Largest'   { $metricQueryResults = ($metricQueryResults | Sort-Object -Descending)[0] }
        }

        $obj = @{
            'ID'                = $_.Id;
            'Subscription'      = $_.SubName;
            'Resource Group'    = $_.ResourceGroup;
            'Name'              = $_.Name;
            'Location'          = $_.Location;
            'Service'           = $_.Service;
            'Metric'            = $_.MetricName;
            'Metric Aggregate'  = $_.Aggregation;
            'Metric Time Grain' = $_.Interval;
            'Metric Value'      = $metricQueryResults;
            'Metric Count'      = $metricQueryResultsCount;
        }
        
        ($using:tmp).Add($obj)

        $metricQuery = $null
        $metricQueryResults = $null
        $metricQueryResultsCount = $null

        #$([System.GC]::GetTotalMemory($false))
        [System.GC]::Collect()
        #$([System.GC]::GetTotalMemory($true))
    } -ThrottleLimit $ConcurrencyLimit

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
