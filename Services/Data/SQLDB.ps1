param($SCPath, $Sub, $Resources, $Task , $File, $SmaResources, $TableStyle) 

if ($Task -eq 'Processing') {

    $SQLDB = $Resources | Where-Object { $_.TYPE -eq 'microsoft.sql/servers/databases' -and $_.name -ne 'master' }

    if($SQLDB)
        {
            $tmp = @()

            foreach ($1 in $SQLDB) {
                $ResUCount = 1
                $sub1 = $SUB | Where-Object { $_.id -eq $1.subscriptionId }
                $data = $1.PROPERTIES
                $DBServer = [string]$1.id.split("/")[8]

                if (![string]::IsNullOrEmpty($data.elasticPoolId)) { $PoolId = $data.elasticPoolId.Split("/")[10] } else { $PoolId = "None"}
                if ($1.kind.Contains("vcore")) { $SqlType = "vcore" } else { $SqlType = "dtu"}

                $obj = @{
                    'ID'                         = $1.id;
                    'Subscription'               = $sub1.Name;
                    'Resource Group'             = $1.RESOURCEGROUP;
                    'Name'                       = $1.NAME;
                    'Location'                   = $1.LOCATION;
                    'Storage Account Type'       = $data.storageAccountType;
                    'Database Server'            = $DBServer;
                    'Default Secondary Location' = $data.defaultSecondaryLocation;
                    'Status'                     = $data.status;
                    'Type'                       = $SqlType;
                    'Capacity'                   = $data.currentSku.capacity;
                    'Tier'                       = $data.requestedServiceObjectiveName;
                    'Zone Redundant'             = $data.zoneRedundant;
                    'Catalog Collation'          = $data.catalogCollation;
                    'Read Replica Count'         = $data.readReplicaCount;
                    'Data Max Size (GB)'         = (($data.maxSizeBytes / 1024) / 1024) / 1024;
                    'Resource U'                 = $ResUCount;
                    'ElasticPool ID'             = $PoolId;
                }

                $tmp += $obj
                if ($ResUCount -eq 1) { $ResUCount = 0 }           
            }

            $tmp
        }
}
else {
    if ($SmaResources.SQLDB) {

        $TableName = ('SQLDBTable_'+($SmaResources.SQLDB.id | Select-Object -Unique).count)

        $Style = @()
        $Style += New-ExcelStyle -HorizontalAlignment Center -AutoSize -NumberFormat 0
        $Style += New-ExcelStyle -HorizontalAlignment Center -AutoSize -NumberFormat '0.0000' -Range Q:Z
        
        $Exc = New-Object System.Collections.Generic.List[System.Object]
        $Exc.Add('Subscription')
        $Exc.Add('Resource Group')
        $Exc.Add('Name')
        $Exc.Add('Location')
        $Exc.Add('Storage Account Type')
        $Exc.Add('Database Server')
        $Exc.Add('Default Secondary Location')
        $Exc.Add('Status')
        $Exc.Add('Type')
        $Exc.Add('Tier')
        $Exc.Add('Capacity')     
        $Exc.Add('Data Max Size (GB)')
        $Exc.Add('Zone Redundant')
        $Exc.Add('Catalog Collation')
        $Exc.Add('Read Replica Count')
        $Exc.Add('ElasticPool ID')

        $ExcelVar = $SmaResources.SQLDB 

        $ExcelVar | 
        ForEach-Object { [PSCustomObject]$_ } | Select-Object -Unique $Exc | 
        Export-Excel -Path $File -WorksheetName 'SQL DBs' -AutoSize -MaxAutoSizeRows 100 -TableName $TableName -TableStyle $tableStyle -Style $Style

    }
}
