param($SCPath, $Sub, $Resources, $Task ,$File, $SmaResources, $TableStyle)

If ($Task -eq 'Processing')
{
    <######### Insert the resource extraction here ########>

        $AvSet = $Resources | Where-Object {$_.TYPE -eq 'microsoft.compute/availabilitysets'}

    <######### Insert the resource Process here ########>

    if($AvSet)
        {
            $tmp = @()

            foreach ($1 in $AvSet) {
                $sub1 = $SUB | Where-Object { $_.Id -eq $1.subscriptionId }
                $data = $1.PROPERTIES
                
                Foreach ($vmid in $data.virtualMachines.id) {
                    $vmIds = $vmid.split('/')[8]
                    $obj = @{
                        'ID'               = $1.id;
                        'Subscription'     = $sub1.Name;
                        'Resource Group'   = $1.RESOURCEGROUP;
                        'Name'             = $1.NAME;
                        'Location'         = $1.LOCATION;
                        'Fault Domains'    = [string]$data.platformFaultDomainCount;
                        'Update Domains'   = [string]$data.platformUpdateDomainCount;
                        'Virtual Machines' = [string]$vmIds;
                    }
                    $tmp += $obj                 
                }
            }
            $tmp
        }
}

<######## Resource Excel Reporting Begins Here ########>

Else
{
    <######## $SmaResources.(RESOURCE FILE NAME) ##########>

    if($SmaResources.AvSet)
    {

        $TableName = ('AvSetTable_'+($SmaResources.AvSet.id | Select-Object -Unique).count)
        $Style = New-ExcelStyle -HorizontalAlignment Center -AutoSize -NumberFormat '0'
            
        $Exc = New-Object System.Collections.Generic.List[System.Object]
        $Exc.Add('Subscription')
        $Exc.Add('Resource Group')
        $Exc.Add('Name')
        $Exc.Add('Location')
        $Exc.Add('Fault Domains')
        $Exc.Add('Update Domains')
        $Exc.Add('Virtual Machines')

        $ExcelVar = $SmaResources.AvSet  

        $ExcelVar | 
        ForEach-Object { [PSCustomObject]$_ } | Select-Object -Unique $Exc | 
        Export-Excel -Path $File -WorksheetName 'Availability Sets' -AutoSize -MaxAutoSizeRows 100 -TableName $TableName -TableStyle $tableStyle -Style $Style

        <######## Insert Column comments and documentations here following this model #########>


        #$excel = Open-ExcelPackage -Path $File -KillExcel


        #Close-ExcelPackage $excel 

    }
}