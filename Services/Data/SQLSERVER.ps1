param($SCPath, $Sub, $Resources, $Task ,$File, $SmaResources, $TableStyle, $Metrics)

if ($Task -eq 'Processing') {

    $SQLSERVER = $Resources | Where-Object { $_.TYPE -eq 'microsoft.sql/servers' }

    if($SQLSERVER)
        {
            $tmp = @()

            foreach ($1 in $SQLSERVER) {
                $ResUCount = 1
                $sub1 = $SUB | Where-Object { $_.id -eq $1.subscriptionId }
                $data = $1.PROPERTIES

                

                $pvteps = if(!($data.privateEndpointConnections)) {[pscustomobject]@{id = 'NONE'}} else {$data.privateEndpointConnections | Select-Object @{Name="id";Expression={$_.id.split("/")[10]}}}

                foreach ($pvtep in $pvteps) {
                    $obj = @{
                        'ID'                    = $1.id;
                        'Subscription'          = $sub1.Name;
                        'Resource Group'        = $1.RESOURCEGROUP;
                        'Name'                  = $1.NAME;
                        'Location'              = $1.LOCATION;
                        'Kind'                  = $1.kind;
                        'State'                 = $data.state;
                        'Version'               = $data.version;
                        'Resource U'            = $ResUCount;
                        'Zone Redundant'        = $1.zones;
                    }
                    $tmp += $obj
                    if ($ResUCount -eq 1) { $ResUCount = 0 }    
                }          
            }
            $tmp
        }
}
else {
    if ($SmaResources.SQLSERVER) {

        $TableName = ('SQLSERVERTable_'+($SmaResources.SQLSERVER.id | Select-Object -Unique).count)
        $Style = New-ExcelStyle -HorizontalAlignment Center -AutoSize -NumberFormat 0

        $condtxt = @()
        $condtxt += New-ConditionalText FALSE -Range G:G
        $condtxt += New-ConditionalText FALSO -Range G:G
        $condtxt += New-ConditionalText Enabled -Range I:I

        $Exc = New-Object System.Collections.Generic.List[System.Object]
        $Exc.Add('Subscription')
        $Exc.Add('Resource Group')
        $Exc.Add('Name')
        $Exc.Add('Location')
        $Exc.Add('Kind')
        $Exc.Add('State')
        $Exc.Add('Version')
        $Exc.Add('Zone Redundant')

        $ExcelVar = $SmaResources.SQLSERVER 

        $ExcelVar | 
        ForEach-Object { [PSCustomObject]$_ } | Select-Object -Unique $Exc | 
        Export-Excel -Path $File -WorksheetName 'SQL Servers' -AutoSize -MaxAutoSizeRows 100 -TableName $TableName -TableStyle $tableStyle -ConditionalText $condtxt -Style $Style

    }
}
