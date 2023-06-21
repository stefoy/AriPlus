param($SCPath, $Sub, $Resources, $Task ,$File, $SmaResources, $TableStyle)

If ($Task -eq 'Processing')
{
    <######### Insert the resource extraction here ########>

        $APIM = $Resources | Where-Object {$_.TYPE -eq 'microsoft.apimanagement/service'}

    <######### Insert the resource Process here ########>

    if($APIM)
        {
            $tmp = @()

            foreach ($1 in $APIM) {
                $ResUCount = 1
                $sub1 = $SUB | Where-Object { $_.id -eq $1.subscriptionId }
                $data = $1.PROPERTIES
                if ($data.virtualNetworkType -eq 'None') { $NetType = '' } else { $NetType = [string]$data.virtualNetworkConfiguration.subnetResourceId.split("/")[8] }
                
                $obj = @{
                    'ID'                   = $1.id;
                    'Subscription'         = $sub1.Name;
                    'Resource Group'       = $1.RESOURCEGROUP;
                    'Name'                 = $1.NAME;
                    'Location'             = $1.LOCATION;
                    'SKU'                  = $1.sku.name;
                    'Gateway URL'          = $data.gatewayUrl;
                    'Virtual Network Type' = $data.virtualNetworkType;
                    'Virtual Network'      = $NetType;
                    'Http2'                = $data.customProperties."Microsoft.WindowsAzure.ApiManagement.Gateway.Protocols.Server.Http2";
                    'Backend SSL 3.0'      = $data.customProperties."Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Ssl30";
                    'Backend TLS 1.0'      = $data.customProperties."Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Tls10";
                    'Backend TLS 1.1'      = $data.customProperties."Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Tls11";
                    'Triple DES'           = $data.customProperties."Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TripleDes168";
                    'Client SSL 3.0'       = $data.customProperties."Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Ssl30";
                    'Client TLS 1.0'       = $data.customProperties."Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Tls10";
                    'Client TLS 1.1'       = $data.customProperties."Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Tls11";
                    'Public IP'            = [string]$data.publicIPAddresses;
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

    if($SmaResources.APIM)
    {

        $TableName = ('APIMTable_'+($SmaResources.APIM.id | Select-Object -Unique).count)
        $Style = New-ExcelStyle -HorizontalAlignment Center -AutoSize -NumberFormat '0'

        $condtxt = @()

        $Exc = New-Object System.Collections.Generic.List[System.Object]
        $Exc.Add('Subscription')
        $Exc.Add('Resource Group')
        $Exc.Add('Name')
        $Exc.Add('Location')
        $Exc.Add('SKU')
        $Exc.Add('Gateway URL')
        $Exc.Add('Virtual Network Type')
        $Exc.Add('Virtual Network')
        $Exc.Add('Http2')
        $Exc.Add('Backend SSL 3.0')
        $Exc.Add('Backend TLS 1.0')
        $Exc.Add('Backend TLS 1.1')
        $Exc.Add('Triple DES')
        $Exc.Add('Client SSL 3.0')
        $Exc.Add('Client TLS 1.0')
        $Exc.Add('Client TLS 1.1')
        $Exc.Add('Public IP')

        $ExcelVar = $SmaResources.APIM 

        $ExcelVar | 
        ForEach-Object { [PSCustomObject]$_ } | Select-Object -Unique $Exc | 
        Export-Excel -Path $File -WorksheetName 'APIM' -AutoSize -MaxAutoSizeRows 100 -TableName $TableName -TableStyle $tableStyle -ConditionalText $condtxt -Style $Style

        <######## Insert Column comments and documentations here following this model #########>


        #$excel = Open-ExcelPackage -Path $File -KillExcel


        #Close-ExcelPackage $excel 

    }
}