param($SCPath, $Sub, $Resources, $Task ,$File, $SmaResources, $TableStyle)

If ($Task -eq 'Processing')
{

    <######### Insert the resource extraction here ########>

        $disk = $Resources | Where-Object {$_.TYPE -eq 'microsoft.compute/disks'}

    <######### Insert the resource Process here ########>

    if($disk)
        {
            $tmp = @()            
            foreach ($1 in $disk) {
                $ResUCount = 1
                $sub1 = $SUB | Where-Object { $_.Id -eq $1.subscriptionId }
                $data = $1.PROPERTIES
                $timecreated = $data.timeCreated
                $timecreated = [datetime]$timecreated
                $timecreated = $timecreated.ToString("yyyy-MM-dd HH:mm")
                $SKU = $1.SKU
                
                $obj = @{
                    'ID'                     = $1.id;
                    'Subscription'           = $sub1.Name;
                    'Resource Group'         = $1.RESOURCEGROUP;
                    'Disk Name'              = $1.NAME;
                    'Disk State'             = $data.diskState;
                    'Associated Resource'    = $1.MANAGEDBY.split('/')[8];
                    'Location'               = $1.LOCATION;
                    'Zone'                   = [string]$1.ZONES;
                    'SKU'                    = $SKU.Name;
                    'Disk Size'              = $data.diskSizeGB;
                    'Encryption'             = $data.encryption.type;
                    'OS Type'                = $data.osType;
                    'Disk IOPS Read / Write' = $data.diskIOPSReadWrite;
                    'Disk MBps Read / Write' = $data.diskMBpsReadWrite;
                    'HyperV Generation'      = $data.hyperVGeneration;
                    'Created Time'           = $timecreated;   
                    'Resource U'             = $ResUCount;
                }
                $tmp += $obj
                if ($ResUCount -eq 1) { $ResUCount = 0}
            }
            $tmp
        }
}

<######## Resource Excel Reporting Begins Here ########>

Else
{
    <######## $SmaResources.(RESOURCE FILE NAME) ##########>

    if($SmaResources.VMDisk)
    {

        $TableName = ('VMDiskT_'+($SmaResources.VMDisk.id | Select-Object -Unique).count)
        $condtxt = @()
        $condtxt += New-ConditionalText Unattached -Range D:D

        $Style = New-ExcelStyle -HorizontalAlignment Center -AutoSize -NumberFormat '0'

        $Exc = New-Object System.Collections.Generic.List[System.Object]
        $Exc.Add('Subscription')
        $Exc.Add('Resource Group')
        $Exc.Add('Disk Name')
        $Exc.Add('Disk State')
        $Exc.Add('Associated Resource')        
        $Exc.Add('Zone')
        $Exc.Add('SKU')
        $Exc.Add('Disk Size')
        $Exc.Add('Location')
        $Exc.Add('Encryption')
        $Exc.Add('OS Type')        
        $Exc.Add('Disk IOPS Read / Write')
        $Exc.Add('Disk MBps Read / Write')
        $Exc.Add('HyperV Generation')
        $Exc.Add('Created Time')

        $ExcelVar = $SmaResources.VMDisk

        $ExcelVar | 
        ForEach-Object { [PSCustomObject]$_ } | Select-Object -Unique $Exc | 
        Export-Excel -Path $File -WorksheetName 'Disks' -TableName $TableName -MaxAutoSizeRows 100 -TableStyle $tableStyle -ConditionalText $condtxt -Style $Style
    }
}