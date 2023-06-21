param($SCPath, $Sub, $Resources, $Task ,$File, $SmaResources, $TableStyle)

If ($Task -eq 'Processing')
{

    <######### Insert the resource extraction here ########>

        $arcservers = $Resources | Where-Object {$_.TYPE -eq 'microsoft.hybridcompute/machines'}

    <######### Insert the resource Process here ########>

    if($arcservers)
        {
            $tmp = @()
            foreach ($1 in $arcservers) {
                $ResUCount = 1
                $sub1 = $SUB | Where-Object { $_.id -eq $1.subscriptionId }
                $data = $1.PROPERTIES

                    foreach ($Tag in $Tags) { 
                        $obj = @{
                            'ID'                   = $1.id;
                            'Subscription'         = $sub1.name;
                            'ResourceGroup'       = $1.RESOURCEGROUP;
                            'Name'                 = $1.NAME;
                            'Location'             = $1.LOCATION;
                            'model'                = $data.detectedProperties.model;
                            'status'               = $data.status;
                            'osName'               = $data.osName;
                            'osVersion'            = $data.osVersion;
                            'osSku'                = $data.osSku;
                            'machineFqdn'          = $data.machineFqdn;
                            'dnsFqdn'              = $data.dnsFqdn;
                            'adFqdn'               = $data.adFqdn;
                            'domainName'           = $data.domainName;
                            'Resource U'           = $ResUCount;
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

    if($SmaResources.ARCServers)
    {
        $TableName = ('ARCServer_'+($SmaResources.ARCServer.id | Select-Object -Unique).count)
        $Style = New-ExcelStyle -HorizontalAlignment Center -AutoSize -NumberFormat '0'

        $Exc = New-Object System.Collections.Generic.List[System.Object]
        $Exc.Add('Subscription')
        $Exc.Add('ResourceGroup')
        $Exc.Add('Name')
        $Exc.Add('Location')
        $Exc.Add('model')
        $Exc.Add('status')
        $Exc.Add('osName')
        $Exc.Add('osVersion')
        $Exc.Add('osSku')
        $Exc.Add('machineFqdn')
        $Exc.Add('dnsFqdn')
        $Exc.Add('adFqdn')
        $Exc.Add('domainName')

        $ExcelVar = $SmaResources.ARCServers  

        $ExcelVar | 
        ForEach-Object { [PSCustomObject]$_ } | Select-Object -Unique $Exc | 
        Export-Excel -Path $File -WorksheetName 'ARC Servers' -AutoSize -MaxAutoSizeRows 100 -TableName $TableName -TableStyle $tableStyle -Style $Style
    }
}