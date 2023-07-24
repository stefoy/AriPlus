param($SCPath, $Sub, $Resources, $Task ,$File, $SmaResources, $TableStyle, $Metrics)

If ($Task -eq 'Processing')
{

    <######### Insert the resource extraction here ########>

        $REGISTRIES = $Resources | Where-Object {$_.TYPE -eq 'microsoft.containerregistry/registries'}

    <######### Insert the resource Process here ########>

    if($REGISTRIES)
        {
            $tmp = @()

            foreach ($1 in $REGISTRIES) {
                $ResUCount = 1
                $sub1 = $SUB | Where-Object { $_.id -eq $1.subscriptionId }
                $data = $1.PROPERTIES
                $timecreated = $data.creationDate
                $timecreated = [datetime]$timecreated
                $timecreated = $timecreated.ToString("yyyy-MM-dd HH:mm")
                
                $obj = @{
                    'ID'                        = $1.id;
                    'Subscription'              = $sub1.Name;
                    'Resource Group'            = $1.RESOURCEGROUP;
                    'Name'                      = $1.NAME;
                    'Location'                  = $1.LOCATION;
                    'SKU'                       = $1.sku.name;
                    'Encryption'                = $data.encryption.status;
                    'Zone Redundancy'           = $data.zoneredundancy;
                    'Private Link'              = if($data.privateendpointconnections){'True'}else{'False'};
                    'Soft Delete Policy'        = $data.policies.softdeletepolicy.status;
                    'Trust Policy'              = $data.policies.trustpolicy.status;
                    'Created Time'              = $timecreated;
                    'Resource U'                = $ResUCount;
                    'Total'                     = $Total;
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

    if($SmaResources.REGISTRIES)
    {
        $TableName = ('ContsTable_'+($SmaResources.REGISTRIES.id | Select-Object -Unique).count)
        $Style = New-ExcelStyle -HorizontalAlignment Center -AutoSize -NumberFormat '0'

        $cond = @()

        $Exc = New-Object System.Collections.Generic.List[System.Object]
        $Exc.Add('Subscription')
        $Exc.Add('Resource Group')
        $Exc.Add('Name')
        $Exc.Add('Location')
        $Exc.Add('SKU')
        $Exc.Add('Encryption')
        $Exc.Add('Zone Redundancy')
        $Exc.Add('Private Link')
        $Exc.Add('Soft Delete Policy')
        $Exc.Add('Trust Policy')
        $Exc.Add('Created Time')  

        $ExcelVar = $SmaResources.REGISTRIES 
            
        $ExcelVar | 
        ForEach-Object { [PSCustomObject]$_ } | Select-Object -Unique $Exc | 
        Export-Excel -Path $File -WorksheetName 'Registries' -AutoSize -ConditionalText $cond -MaxAutoSizeRows 100 -TableName $TableName -TableStyle $tableStyle -Style $Style

    }
}
