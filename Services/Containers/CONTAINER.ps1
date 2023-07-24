param($SCPath, $Sub, $Resources, $Task ,$File, $SmaResources, $TableStyle, $Metrics)

If ($Task -eq 'Processing')
{

    <######### Insert the resource extraction here ########>

        $CONTAINER = $Resources | Where-Object {$_.TYPE -eq 'microsoft.containerinstance/containergroups'}

    <######### Insert the resource Process here ########>

    if($CONTAINER)
        {
            $tmp = @()

            foreach ($1 in $CONTAINER) {
                $ResUCount = 1
                $sub1 = $SUB | Where-Object { $_.id -eq $1.subscriptionId }
                $data = $1.PROPERTIES
                
                foreach ($2 in $data.containers) {
                    $obj = @{
                        'ID'                  = $1.id;
                        'Subscription'        = $sub1.Name;
                        'Resource Group'      = $1.RESOURCEGROUP;
                        'Instance Name'       = $1.NAME;
                        'Location'            = $1.LOCATION;
                        'Instance OS Type'    = $data.osType;
                        'Container Name'      = $2.name;
                        'Container State'     = $2.properties.instanceView.currentState.state;
                        'Container Image'     = [string]$2.properties.image;
                        'Restart Count'       = $2.properties.instanceView.restartCount;
                        'Start Time'          = $2.properties.instanceView.currentState.startTime;
                        'Command'             = [string]$2.properties.command;
                        'Request CPU'         = $2.properties.resources.requests.cpu;
                        'Request Memory (GB)' = $2.properties.resources.requests.memoryInGB;
                        'Total'               = $Total;
                    }
                    $tmp += $obj
                    if ($ResUCount -eq 1) { $ResUCount = 0 }                
                }
            }
            $tmp
        }
}

<######## Resource Excel Reporting Begins Here ########>

Else
{
    <######## $SmaResources.(RESOURCE FILE NAME) ##########>

    if($SmaResources.CONTAINER)
    {
        $TableName = ('ContsTable_'+($SmaResources.CONTAINER.id | Select-Object -Unique).count)
        $Style = New-ExcelStyle -HorizontalAlignment Center -AutoSize -NumberFormat '0'

        $Exc = New-Object System.Collections.Generic.List[System.Object]
        $Exc.Add('Subscription')
        $Exc.Add('Resource Group')
        $Exc.Add('Instance Name')
        $Exc.Add('Location')
        $Exc.Add('Instance OS Type')
        $Exc.Add('Container Name')
        $Exc.Add('Container State')
        $Exc.Add('Container Image')
        $Exc.Add('Restart Count')
        $Exc.Add('Start Time')
        $Exc.Add('Command')
        $Exc.Add('Request CPU')
        $Exc.Add('Request Memory (GB)')

        $ExcelVar = $SmaResources.CONTAINER 
            
        $ExcelVar | 
        ForEach-Object { [PSCustomObject]$_ } | Select-Object -Unique $Exc | 
        Export-Excel -Path $File -WorksheetName 'Containers' -AutoSize -MaxAutoSizeRows 100 -TableName $TableName -TableStyle $tableStyle -Style $Style

    }
}
