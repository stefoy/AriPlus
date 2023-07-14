param($SCPath, $Sub, $Resources, $Task , $File, $SmaResources, $TableStyle) 
If ($Task -eq 'Processing') {

    $ROUTETABLE = $Resources | Where-Object { $_.TYPE -eq 'microsoft.network/routetables' }

    if($ROUTETABLE)
        {
            $tmp = @()

            foreach ($1 in $ROUTETABLE) {
                $ResUCount = 1
                $sub1 = $SUB | Where-Object { $_.Id -eq $1.subscriptionId }
                $data = $1.PROPERTIES
                
                    foreach($2 in $data.routes)
                        {
                            $obj = @{
                                'ID'                            = $1.id;
                                'Subscription'                  = $sub1.Name;
                                'Resource Group'                = $1.RESOURCEGROUP;
                                'Name'                          = $1.NAME;
                                'Location'                      = $1.LOCATION;
                            }
                            $tmp += $obj
                            if ($ResUCount -eq 1) { $ResUCount = 0 } 
                    }               
            }
            $tmp
        }
}
Else {
    if ($SmaResources.ROUTETABLE) {

        $TableName = ('RouteTbTable_'+($SmaResources.ROUTETABLE.id | Select-Object -Unique).count)
        $Style = New-ExcelStyle -HorizontalAlignment Center -AutoSize -NumberFormat 0

        $Exc = New-Object System.Collections.Generic.List[System.Object]
        $Exc.Add('Subscription')
        $Exc.Add('Resource Group')
        $Exc.Add('Name')
        $Exc.Add('Location')


        $ExcelVar = $SmaResources.ROUTETABLE 

        $ExcelVar | 
        ForEach-Object { [PSCustomObject]$_ } | Select-Object -Unique $Exc | 
        Export-Excel -Path $File -WorksheetName 'Route Tables' -AutoSize -MaxAutoSizeRows 100 -TableName $TableName -TableStyle $tableStyle -Style $Style
    
    }
}
