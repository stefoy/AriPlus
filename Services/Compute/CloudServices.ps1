param($SCPath, $Sub, $Resources, $Task ,$File, $SmaResources, $TableStyle, $Metrics)

If ($Task -eq 'Processing') {

    <######### Insert the resource extraction here ########>

    #$CloudServices0 = $Resources | Where-Object { $_.TYPE -eq 'microsoft.compute/cloudservices' }
    $CloudServices = $Resources | Where-Object { $_.TYPE -eq 'microsoft.classiccompute/domainnames' }

    <######### Insert the resource Process here ########>

    if($CloudServices)
        {
            $tmp = @()
            foreach ($1 in $CloudServices) {
                $ResUCount = 1
                $sub1 = $SUB | Where-Object { $_.id -eq $1.subscriptionId }
                $data = $1.PROPERTIES
                $obj = @{
                    'ID'                   = $1.id;
                    'Subscription'         = $sub1.Name;
                    'ResourceGroup'       = $1.RESOURCEGROUP;
                    'Name'                 = $1.name;
                    'Location'             = $1.location;
                    'Status'               = $data.status;
                    'Label'                = $data.label;
                    'Hostname'             = $data.hostname;    
                    'ResourceU'           = $ResUCount;
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

    if ($SmaResources.CloudServices) {

        $TableName = ('CloudServicesTable_'+($SmaResources.CloudServices.id | Select-Object -Unique).count)
        $Style = New-ExcelStyle -HorizontalAlignment Center -AutoSize -NumberFormat '0'

        $Exc = New-Object System.Collections.Generic.List[System.Object]
        $Exc.Add('Subscription')
        $Exc.Add('ResourceGroup')
        $Exc.Add('Name')         
        $Exc.Add('Location')             
        $Exc.Add('Status')          
        $Exc.Add('Label')           
        $Exc.Add('Hostname')      

        $ExcelVar = $SmaResources.CloudServices

        $ExcelVar | 
        ForEach-Object { [PSCustomObject]$_ } | Select-Object -Unique $Exc | 
        Export-Excel -Path $File -WorksheetName 'CloudServices' -AutoSize -TableName $TableName -MaxAutoSizeRows 100 -TableStyle $tableStyle -Numberformat '0' -Style $Style
    
    }
}