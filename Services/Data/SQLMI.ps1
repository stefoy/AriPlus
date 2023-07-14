param($SCPath, $Sub, $Resources, $Task ,$File, $SmaResources, $TableStyle)

if ($Task -eq 'Processing') {

    $SQLSERVERMI = $Resources | Where-Object { $_.TYPE -eq 'microsoft.sql/managedInstances' }

    if($SQLSERVERMI)
        {
            $tmp = @()

            foreach ($1 in $SQLSERVERMI) {
                $ResUCount = 1
                $sub1 = $SUB | Where-Object { $_.id -eq $1.subscriptionId }
                $data = $1.PROPERTIES

                $pvteps = if(!($1.privateEndpointConnections)) {[pscustomobject]@{id = 'NONE'}} else {$1.privateEndpointConnections | Select-Object @{Name="id";Expression={$_.id.split("/")[8]}}}

                foreach ($pvtep in $pvteps) {
                    $obj = @{
                        'ID'                    = $1.id;
                        'Subscription'          = $sub1.Name;
                        'Resource Group'        = $1.RESOURCEGROUP;
                        'Name'                  = $1.NAME;
                        'Location'              = $1.LOCATION;
                        'SkuName'               = $1.sku.Name;
                        'SkuCapacity'           = $1.sku.capacity;
                        'SkuTier'               = $1.sku.tier;
                        'licenseType'           = $data.licenseType;
                        'managedInstanceCreateMode'               = $data.managedInstanceCreateMode;
                        'Resource U'            = $ResUCount;
                        'Zone Redundant'        = $data.zoneRedundant;
                    }
                    $tmp += $obj
                    if ($ResUCount -eq 1) { $ResUCount = 0 } 
                }          
            }
            $tmp
        }
}
else {
    if ($SmaResources.SQLMI) {

        $TableName = ('SQLMITable_'+($SmaResources.SQLMI.id | Select-Object -Unique).count)
        $Style = New-ExcelStyle -HorizontalAlignment Center -AutoSize -NumberFormat 0

        $condtxt = @()

        $Exc = New-Object System.Collections.Generic.List[System.Object]
        $Exc.Add('Subscription')
        $Exc.Add('Resource Group')
        $Exc.Add('Name')
        $Exc.Add('Location')
        $Exc.Add('SkuName')
        $Exc.Add('SkuCapacity')
        $Exc.Add('SkuTier')
        $Exc.Add('licenseType')
        $Exc.Add('managedInstanceCreateMode')
        $Exc.Add('Zone Redundant')

        $ExcelVar = $SmaResources.SQLMI

        $ExcelVar | 
        ForEach-Object { [PSCustomObject]$_ } | Select-Object -Unique $Exc | 
        Export-Excel -Path $File -WorksheetName 'SQL MI' -AutoSize -MaxAutoSizeRows 100 -TableName $TableName -TableStyle $tableStyle -ConditionalText $condtxt -Style $Style

    }
}
