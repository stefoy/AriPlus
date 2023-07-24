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
                $ResUCount = 1
                $sub1 = $SUB | Where-Object { $_.id -eq $1.subscriptionId }
                $data = $1.PROPERTIES
                $PvtEndP = $data.privateEndpointConnections.properties.privateEndpoint.id.split('/')[8]
                if ($1.ZONES) { $Zones = $1.ZONES }else { $Zones = 'Not Configured' }
                if ([string]::IsNullOrEmpty($data.minimumTlsVersion)){$MinTLS = 'Default'}Else{$MinTLS = "TLS $($data.minimumTlsVersion)"}
                
                $obj = @{
                    'ID'                    = $1.id;
                    'Subscription'          = $sub1.Name;
                    'ResourceGroup'         = $1.RESOURCEGROUP;
                    'Name'                  = $1.NAME;
                    'Location'              = $1.LOCATION;
                    'Zone'                  = $Zones;
                    'Version'               = $data.redisVersion;
                    'Minimum TLS Version'   = $MinTLS;
                    'Sku'                   = $data.sku.name;
                    'Capacity'              = $data.sku.capacity;
                    'Family'                = $data.sku.family;
                    'Max Frag Mem Reserved' = $data.redisConfiguration.'maxfragmentationmemory-reserved';
                    'Max Mem Reserved'      = $data.redisConfiguration.'maxmemory-reserved';
                    'Max Memory Delta'      = $data.redisConfiguration.'maxmemory-delta';
                    'Max Clients'           = $data.redisConfiguration.'maxclients';
                    'Resource U'            = $ResUCount;
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

    if ($SmaResources.RedisCache) {

        $TableName = ('RedisCacheTable_'+($SmaResources.RedisCache.id | Select-Object -Unique).count)
        $condtxt = @()

        $Style = @()        
        
        $Exc = New-Object System.Collections.Generic.List[System.Object]
        $Exc.Add('Subscription')
        $Exc.Add('Resource Group')
        $Exc.Add('Name')                    
        $Exc.Add('Location')           
        $Exc.Add('Zone')                    
        $Exc.Add('Version')                               
        $Exc.Add('Minimum TLS Version')         
        $Exc.Add('Sku')                     
        $Exc.Add('Capacity')
        $Exc.Add('Family')                  
        $Exc.Add('Max Frag Mem Reserved')   
        $Exc.Add('Max Mem Reserved')        
        $Exc.Add('Max Memory Delta')        
        $Exc.Add('Max Clients')

        $ExcelVar = $SmaResources.RedisCache

        $ExcelVar | 
        ForEach-Object { [PSCustomObject]$_ } | Select-Object -Unique $Exc | 
        Export-Excel -Path $File -WorksheetName 'Redis Cache' -AutoSize -MaxAutoSizeRows 100 -TableName $TableName -TableStyle $tableStyle -ConditionalText $condtxt -Style $Style
    }
    <######## Insert Column comments and documentations here following this model #########>
}
