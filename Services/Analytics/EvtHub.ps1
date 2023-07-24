param($SCPath, $Sub, $Resources, $Task ,$File, $SmaResources, $TableStyle, $Metrics)

If ($Task -eq 'Processing')
{

    <######### Insert the resource extraction here ########>

        $evthub = $Resources | Where-Object {$_.TYPE -eq 'microsoft.eventhub/namespaces'}

    <######### Insert the resource Process here ########>

    if($evthub)
        {
            $tmp = @()
            foreach ($1 in $evthub) {
                $ResUCount = 1
                $sub1 = $SUB | Where-Object { $_.id -eq $1.subscriptionId }
                $data = $1.PROPERTIES
                $timecreated = $data.createdAt
                $timecreated = [datetime]$timecreated
                $timecreated = $timecreated.ToString("yyyy-MM-dd HH:mm")
                $sku = $1.SKU
                $obj = @{
                    'ID'                   = $1.id;
                    'Subscription'         = $sub1.Name;
                    'ResourceGroup'       = $1.RESOURCEGROUP;
                    'Name'                 = $1.NAME;
                    'Location'             = $1.LOCATION;
                    'SKU'                  = $sku.name;
                    'Status'               = $data.status;
                    'GeoReplication'      = $data.zoneRedundant;
                    'ThroughputUnits'     = $1.sku.capacity;
                    'AutoInflate'         = $data.isAutoInflateEnabled;
                    'MaxThroughputUnits' = $data.maximumThroughputUnits;
                    'KafkaEnabled'        = $data.kafkaEnabled;
                    'CreatedTime'         = $timecreated;
                    'ResourceU'           = $ResUCount;
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

    if($SmaResources.EvtHub)
    {
        $TableName = ('EvtHubTable_'+($SmaResources.EvtHub.id | Select-Object -Unique).count)
        $Style = New-ExcelStyle -HorizontalAlignment Center -AutoSize -NumberFormat '0'

        $condtxt = @()
        $condtxt += New-ConditionalText false -Range I:I
        $condtxt += New-ConditionalText falso -Range I:I

        $Exc = New-Object System.Collections.Generic.List[System.Object]
        $Exc.Add('Subscription')
        $Exc.Add('ResourceGroup')
        $Exc.Add('Name')
        $Exc.Add('Location')
        $Exc.Add('SKU')
        $Exc.Add('Status')
        $Exc.Add('GeoRep')
        $Exc.Add('ThroughputUnits')
        $Exc.Add('AutoInflate')
        $Exc.Add('MaxThroughputUnits')
        $Exc.Add('KafkaEnabled')
        $Exc.Add('CreatedTime')  

        $ExcelVar = $SmaResources.EvtHub  

        $ExcelVar | 
        ForEach-Object { [PSCustomObject]$_ } | Select-Object -Unique $Exc | 
        Export-Excel -Path $File -WorksheetName 'Event Hubs' -AutoSize -MaxAutoSizeRows 100 -TableName $TableName -TableStyle $tableStyle -ConditionalText $condtxt -Style $Style, $StyleCost
    }
}
