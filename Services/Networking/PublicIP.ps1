param($SCPath, $Sub, $Resources, $Task ,$File, $SmaResources, $TableStyle, $Metrics)

If ($Task -eq 'Processing') {

    $PublicIP = $Resources | Where-Object { $_.TYPE -eq 'microsoft.network/publicipaddresses' }

    if($PublicIP)
        {
            $tmp = @()

            foreach ($1 in $PublicIP) {
                $ResUCount = 1
                $sub1 = $SUB | Where-Object { $_.Id -eq $1.subscriptionId }
                $data = $1.PROPERTIES
                if (!($data.ipConfiguration.id)) { $Use = 'Underutilized' } else { $Use = 'Utilized' }
                if (!($data.natGateway.id) -and $Use -eq 'Underutilized') { $Use = 'Underutilized' } else { $Use = 'Utilized' }
                
                
                if ($null -ne $data.ipConfiguration.id) {
                    $obj = @{
                        'ID'                       = $1.id;
                        'Subscription'             = $sub1.Name;
                        'Resource Group'           = $1.RESOURCEGROUP;
                        'Name'                     = $1.NAME;
                        'SKU'                      = $1.SKU.Name;
                        'Location'                 = $1.LOCATION;
                        'Use'                      = $Use;
                        'Associated Resource'      = $data.ipConfiguration.id.split('/')[8];
                        'Associated Resource Type' = $data.ipConfiguration.id.split('/')[7];
                    }
                    $tmp += $obj
                    if ($ResUCount -eq 1) { $ResUCount = 0 } 
                }               
                else {
                    foreach ($Tag in $Tags) {  
                        $obj = @{
                            'ID'                       = $1.id;
                            'Subscription'             = $sub1.name;
                            'Resource Group'           = $1.RESOURCEGROUP;
                            'Name'                     = $1.NAME;
                            'SKU'                      = $1.SKU.Name;
                            'Location'                 = $1.LOCATION;
                            'Use'                      = $Use;
                            'Associated Resource'      = $null;
                            'Associated Resource Type' = $null;
                        }
                        $tmp += $obj
                        if ($ResUCount -eq 1) { $ResUCount = 0 } 
                    }               
                }            
        }
        $tmp
    }
}
Else {
    if ($SmaResources.PublicIP) {        

        $TableName = ('PIPTable_'+($SmaResources.PublicIP.id | Select-Object -Unique).count)
        $Style = New-ExcelStyle -HorizontalAlignment Center -AutoSize -NumberFormat 0

        $condtxt = @()
        $condtxt += New-ConditionalText Underutilized -Range J:J

        $Exc = New-Object System.Collections.Generic.List[System.Object]
        $Exc.Add('Subscription')
        $Exc.Add('Resource Group')
        $Exc.Add('Name')
        $Exc.Add('SKU')
        $Exc.Add('Location')
        $Exc.Add('Version')
        $Exc.Add('Use')
        $Exc.Add('Associated Resource')
        $Exc.Add('Associated Resource Type')

        $ExcelVar = $SmaResources.PublicIP

        $ExcelVar | 
        ForEach-Object { [PSCustomObject]$_ } | Select-Object -Unique $Exc | 
        Export-Excel -Path $File -WorksheetName 'Public IPs' -AutoSize -MaxAutoSizeRows 100 -TableName $TableName -TableStyle $tableStyle -Style $Style -ConditionalText $condtxt
    
    }
}
