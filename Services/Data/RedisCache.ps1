param($SCPath, $Sub, $Resources, $Task ,$File, $SmaResources, $TableStyle, $Metrics)

If ($Task -eq 'Processing') {

    <######### Insert the resource extraction here ########>

    $RedisCache = @()
    $RedisCache += $Resources | Where-Object { $_.TYPE -eq 'microsoft.cache/redis' }
    $RedisCache += $Resources | Where-Object { $_.TYPE -eq 'microsoft.cache/redisenterprise' }

    if($RedisCache)
        {
            $tmp = @()

            foreach ($1 in $RedisCache) {
                $sub1 = $SUB | Where-Object { $_.id -eq $1.subscriptionId }
                $data = $1.PROPERTIES
                if ([string]::IsNullOrEmpty($data.minimumTlsVersion)){$MinTLS = 'Default'}Else{$MinTLS = "TLS $($data.minimumTlsVersion)"}
                
                $obj = @{
                    'ID'                    = $1.id;
                    'Subscription'          = $sub1.Name;
                    'ResourceGroup'         = $1.RESOURCEGROUP;
                    'Name'                  = $1.NAME;
                    'Location'              = $1.LOCATION;
                    'Version'               = $data.redisVersion;
                    'Sku'                   = $data.sku.name;
                    'Capacity'              = $data.sku.capacity;
                    'Family'                = $data.sku.family;
                    'MaxFragMemReserved' = $data.redisConfiguration.'maxfragmentationmemory-reserved';
                    'MaxMemReserved'      = $data.redisConfiguration.'maxmemory-reserved';
                    'MaxMemoryDelta'      = $data.redisConfiguration.'maxmemory-delta';
                    'MaxClients'           = $data.redisConfiguration.'maxclients';
                }
                $tmp += $obj
            }
            $tmp
        }
}
<######## Resource Excel Reporting Begins Here ########>

Else {
    <######## $SmaResources.(RESOURCE FILE NAME) ##########>

    if ($SmaResources.RedisCache) {

        $TableName = ('RedisCacheTable_'+($SmaResources.RedisCache.id | Select-Object -Unique).count)
        $condtxt = @()

        $Style = @()        
        
        $Exc = New-Object System.Collections.Generic.List[System.Object]
        $Exc.Add('Subscription')
        $Exc.Add('ResourceGroup')
        $Exc.Add('Name')                    
        $Exc.Add('Location')           
        $Exc.Add('Version')                               
        $Exc.Add('Sku')                     
        $Exc.Add('Capacity')
        $Exc.Add('Family')                  
        $Exc.Add('MaxFragMemReserved')   
        $Exc.Add('MaxMemReserved')        
        $Exc.Add('MaxMemoryDelta')        
        $Exc.Add('MaxClients')

        $ExcelVar = $SmaResources.RedisCache

        $ExcelVar | 
        ForEach-Object { [PSCustomObject]$_ } | Select-Object -Unique $Exc | 
        Export-Excel -Path $File -WorksheetName 'Redis Cache' -AutoSize -MaxAutoSizeRows 100 -TableName $TableName -TableStyle $tableStyle -ConditionalText $condtxt -Style $Style
    }
    <######## Insert Column comments and documentations here following this model #########>
}
