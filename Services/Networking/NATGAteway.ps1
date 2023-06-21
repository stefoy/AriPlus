param($SCPath, $Sub, $Resources, $Task ,$File, $SmaResources, $TableStyle)
If ($Task -eq 'Processing') {

    $NATGAT = $Resources | Where-Object { $_.TYPE -eq 'microsoft.network/natgateways' }

    if($NATGAT)
        {
            $tmp = @()

            foreach ($1 in $NATGAT) 
                {
                    $ResUCount = 1
                    $sub1 = $SUB | Where-Object { $_.Id -eq $1.subscriptionId }
                    $data = $1.PROPERTIES
                    
                        foreach ($2 in $data.subnets)
                            {
                                $t_pip_addresses = ''
                                $t_pip_prefixes = ''

                                if (!!$data.publicipaddresses) {
                                    $t_pip_addresses = [string]$data.publicipaddresses.id.split("/")[8]
                                }

                                
                                if (!!$data.publicipprefixes) {
                                    $t_pip_prefixes = [string]$data.publicipprefixes.id.split("/")[8]
                                }

                                $obj = @{
                                    'ID'                    = $1.id;
                                    'Subscription'          = $sub1.Name;
                                    'Resource Group'        = $1.RESOURCEGROUP;
                                    'Name'                  = $1.NAME;
                                    'Location'              = $1.LOCATION;
                                    'SKU'                   = $1.sku.name;
                                    'Idle Timeout (Min)'    = $data.idleTimeoutInMinutes;
                                    'Public IP'             = $t_pip_addresses;
                                    'Public Prefixes'       = $t_pip_prefixes;
                                    'VNET'                  = [string]$2.id.split("/")[8];
                                    'Subnet'                = [string]$2.id.split("/")[10];
                                    'Resource U'            = $ResUCount;
                                }
                                $tmp += $obj
                                if ($ResUCount -eq 1) { $ResUCount = 0 } 
                            }               
                }
            $tmp
        }
}
Else {
    if ($SmaResources.NATGateway) {

        $TableName = ('NATGatewayTable_'+($SmaResources.NATGateway.id | Select-Object -Unique).count)
        $Style = New-ExcelStyle -HorizontalAlignment Center -AutoSize -NumberFormat 0

        $Exc = New-Object System.Collections.Generic.List[System.Object]
        $Exc.Add('Subscription')
        $Exc.Add('Resource Group')
        $Exc.Add('Name')
        $Exc.Add('Location')
        $Exc.Add('SKU')
        $Exc.Add('Idle Timeout (Min)')
        $Exc.Add('Public IP')
        $Exc.Add('Public Prefixes')
        $Exc.Add('VNET')
        $Exc.Add('Subnet')


        $ExcelVar = $SmaResources.NATGateway

        $ExcelVar | 
        ForEach-Object { [PSCustomObject]$_ } | Select-Object -Unique $Exc | 
        Export-Excel -Path $File -WorksheetName 'NAT Gateway' -AutoSize -MaxAutoSizeRows 100 -TableName $TableName -TableStyle $tableStyle -Style $Style
    
    }
}