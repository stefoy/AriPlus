param($SCPath, $Sub, $Resources, $Task ,$File, $SmaResources, $TableStyle)

If ($Task -eq 'Processing')
{
    <######### Insert the resource extraction here ########>

        $expressroute = $Resources | Where-Object {$_.TYPE -eq 'microsoft.network/expressroutecircuits'}

    <######### Insert the resource Process here ########>

    if($expressroute)
        {
            $tmp = @()

            foreach ($1 in $expressroute) {
                $ResUCount = 1
                $sub1 = $SUB | Where-Object { $_.id -eq $1.subscriptionId }
                $data = $1.PROPERTIES
                $sku = $1.SKU
                
                $obj = @{
                    'ID'                   = $1.id;
                    'Subscription'         = $sub1.name;
                    'Resource Group'       = $1.RESOURCEGROUP;
                    'Name'                 = $1.NAME;
                    'Location'             = $1.LOCATION;
                    'tier'                 = $sku.tier;
                    'Billing Model'        = $sku.family;
                    'Circuit status'       = $data.circuitProvisioningState;
                    'Provider Status'      = $data.serviceProviderProvisioningState;
                    'Provider'             = $data.serviceProviderProperties.serviceProviderName;
                    'Bandwidth'            = $data.bandwidthInMbps;
                    'ER Location'          = $data.peeringLocation;
                    'GlobalReach Enabled'  = $data.globalReachEnabled;
                    'Resource U'           = $ResUCount;
                }
                $tmp += $obj
                if ($ResUCount -eq 1) { $ResUCount = 0 }             
            }
            $tmp
        }
}

<######## Resource Excel Reporting Begins Here ########>

Else
{
    <######## $SmaResources.(RESOURCE FILE NAME) ##########>

    if($SmaResources.expressroute)
    {
        $TableName = ('ERs_'+($SmaResources.expressroute.id | Select-Object -Unique).count)
        $Style = New-ExcelStyle -HorizontalAlignment Center -AutoSize -NumberFormat '0'

        $Exc = New-Object System.Collections.Generic.List[System.Object]
        $Exc.Add('Subscription')
        $Exc.Add('Resource Group')
        $Exc.Add('Name')
        $Exc.Add('Location')
        $Exc.Add('tier')
        $Exc.Add('Billing Model')
        $Exc.Add('Circuit status')
        $Exc.Add('Provider Status')
        $Exc.Add('Provider')
        $Exc.Add('Bandwidth')
        $Exc.Add('ER Location')
        $Exc.Add('GlobalReach Enabled')


        $ExcelVar = $SmaResources.expressroute  

        $ExcelVar | 
        ForEach-Object { [PSCustomObject]$_ } | Select-Object -Unique $Exc | 
        Export-Excel -Path $File -WorksheetName 'Express Route' -AutoSize -MaxAutoSizeRows 100 -TableName $TableName -TableStyle $tableStyle -Style $Style
    }
}