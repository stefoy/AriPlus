param($SCPath, $Sub, $Resources, $Task ,$File, $SmaResources, $TableStyle)

If ($Task -eq 'Processing')
{
    <######### Insert the resource extraction here ########>

        $connections = $Resources | Where-Object {$_.TYPE -eq 'microsoft.network/connections'}

    <######### Insert the resource Process here ########>

    if($connections)
        {
            $tmp = @()

            foreach ($1 in $connections) {
                $ResUCount = 1
                $sub1 = $SUB | Where-Object { $_.id -eq $1.subscriptionId }
                $data = $1.PROPERTIES
                
                $obj = @{
                    'ID'                   = $1.id;
                    'Subscription'         = $sub1.name;
                    'Resource Group'       = $1.RESOURCEGROUP;
                    'Name'                 = $1.NAME;
                    'Location'             = $1.LOCATION;
                    'Type'                 = $data.connectionType;
                    'Status'               = $data.connectionStatus;
                    'Connection Protocol'  = $data.connectionProtocol;
                    'Routing Weight'       = $data.routingWeight;
                    'connectionMode'       = $data.connectionMode;
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

    if($SmaResources.Connections)
    {
        $TableName = ('Connections_'+($SmaResources.Connections.id | Select-Object -Unique).count)
        $Style = New-ExcelStyle -HorizontalAlignment Center -AutoSize -NumberFormat '0'

        $Exc = New-Object System.Collections.Generic.List[System.Object]
        $Exc.Add('Subscription')
        $Exc.Add('Resource Group')
        $Exc.Add('Name')
        $Exc.Add('Location')
        $Exc.Add('Type')
        $Exc.Add('Status')
        $Exc.Add('Connection Protocol')
        $Exc.Add('Routing Weight')
        $Exc.Add('connectionMode')

        $ExcelVar = $SmaResources.Connections  

        $ExcelVar | 
        ForEach-Object { [PSCustomObject]$_ } | Select-Object -Unique $Exc | 
        Export-Excel -Path $File -WorksheetName 'Connections' -AutoSize -MaxAutoSizeRows 100 -TableName $TableName -TableStyle $tableStyle -Style $Style
    }
}