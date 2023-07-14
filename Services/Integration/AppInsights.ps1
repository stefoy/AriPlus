param($SCPath, $Sub, $Resources, $Task , $File, $SmaResources, $TableStyle)

If ($Task -eq 'Processing') {

    <######### Insert the resource extraction here ########>

    $AppInsights = $Resources | Where-Object { $_.TYPE -eq 'microsoft.insights/components' }

    if($AppInsights)
        {
            $tmp = @()
            foreach ($1 in $AppInsights) {
                $ResUCount = 1
                $sub1 = $SUB | Where-Object { $_.id -eq $1.subscriptionId }
                $data = $1.PROPERTIES
                $timecreated = $data.CreationDate
                $timecreated = [datetime]$timecreated
                $timecreated = $timecreated.ToString("yyyy-MM-dd HH:mm")
                $Sampling = if([string]::IsNullOrEmpty($data.SamplingPercentage)){'Disabled'}else{$data.SamplingPercentage}
                
                $obj = @{
                    'ID'                                = $1.id;
                    'Subscription'                      = $sub1.Name;
                    'Resource Group'                    = $1.RESOURCEGROUP;
                    'Name'                              = $1.NAME;
                    'Location'                          = $1.LOCATION;
                    'Application Type'                  = $data.Application_Type;
                    'Flow Type'                         = $data.Flow_Type;
                    'Version'                           = $data.Ver;
                    'Data Sampling %'                   = [string]$Sampling;
                    'Retention In Days'                 = $data.RetentionInDays;
                    'Ingestion Mode'                    = $data.IngestionMode;
                    'Created Time'                      = $timecreated;                            
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

    if ($SmaResources.AppInsights) {

        $TableName = ('AppInsightsTable_'+($SmaResources.AppInsights.id | Select-Object -Unique).count)
        $Style = New-ExcelStyle -HorizontalAlignment Center -AutoSize -NumberFormat 0

        $condtxt = @()
        $condtxt += New-ConditionalText Disabled -Range I:I
        
        $Exc = New-Object System.Collections.Generic.List[System.Object]
        $Exc.Add('Subscription')
        $Exc.Add('Resource Group')
        $Exc.Add('Name')
        $Exc.Add('Location')
        $Exc.Add('Application Type')
        $Exc.Add('Flow Type')
        $Exc.Add('Version')
        $Exc.Add('Data Sampling %')
        $Exc.Add('Retention In Days')
        $Exc.Add('Ingestion Mode')
        $Exc.Add('Created Time')

        $ExcelVar = $SmaResources.AppInsights 

        $ExcelVar | 
        ForEach-Object { [PSCustomObject]$_ } | Select-Object -Unique $Exc | 
        Export-Excel -Path $File -WorksheetName 'AppInsights' -AutoSize -MaxAutoSizeRows 100 -TableName $TableName -TableStyle $tableStyle -Style $Style -ConditionalText $condtxt

    }
    <######## Insert Column comments and documentations here following this model #########>
}
