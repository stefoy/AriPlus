param($SCPath, $Sub, $Resources, $Task , $File, $SmaResources, $TableStyle)

If ($Task -eq 'Processing') {

    <######### Insert the resource extraction here ########>
    $TrafficManager = $Resources | Where-Object { $_.TYPE -eq 'microsoft.network/trafficmanagerprofiles' }

    if($TrafficManager)
        {
            $tmp = @()

            foreach ($1 in $TrafficManager) {
                $ResUCount = 1
                $sub1 = $SUB | Where-Object { $_.Id -eq $1.subscriptionId }
                $data = $1.PROPERTIES
                
                $obj = @{
                    'ID'                                = $1.id;
                    'Subscription'                      = $sub1.Name;
                    'Resource Group'                    = $1.RESOURCEGROUP;
                    'Name'                              = $1.NAME;
                    'Status'                            = $data.profilestatus;
                    'Routing method'                    = $data.trafficroutingmethod;
                    'Monitor status'                    = $data.monitorconfig.profilemonitorstatus;                            
                    'Resource U'                        = $ResUCount;
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

    if ($SmaResources.TrafficManager) {

        $TableName = ('TrafficManagerTable_'+($SmaResources.TrafficManager.id | Select-Object -Unique).count)
        $condtxt = New-ConditionalText inactive -Range G:G

        $Style = New-ExcelStyle -HorizontalAlignment Center -AutoSize -NumberFormat 0
        
        $Exc = New-Object System.Collections.Generic.List[System.Object]
        $Exc.Add('Subscription')
        $Exc.Add('Resource Group')
        $Exc.Add('Name')
        $Exc.Add('Status')
        $Exc.Add('Routing method')
        $Exc.Add('Monitor status')

        $ExcelVar = $SmaResources.TrafficManager

        $ExcelVar | 
        ForEach-Object { [PSCustomObject]$_ } | Select-Object -Unique $Exc | 
        Export-Excel -Path $File -WorksheetName 'Traffic Manager' -AutoSize -MaxAutoSizeRows 100 -TableName $TableName -TableStyle $tableStyle -ConditionalText $condtxt -Style $Style

    }
    <######## Insert Column comments and documentations here following this model #########>
}
