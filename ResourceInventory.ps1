param ($TenantID,
        $Appid, 
        $Secret, 
        $ResourceGroup, 
        [switch]$Online, 
        [switch]$Debug, 
        [switch]$SkipMetrics, 
        [switch]$Help, 
        [switch]$DeviceLogin,
        $ConcurencyLimit = 2,
        $AzureEnvironment,
        $ReportName = 'ResourcesReport', 
        $OutputDirectory)


if ($Debug.IsPresent) {$DebugPreference = 'Continue'}

if ($Debug.IsPresent) {$ErrorActionPreference = "Continue" }Else {$ErrorActionPreference = "silentlycontinue" }

Write-Debug ('Debbuging Mode: On. ErrorActionPreference was set to "Continue", every error will be presented.')

function Variables 
{
    $Global:ResourceContainers = @()
    $Global:Resources = @()
    $Global:Subscriptions = ''
    $Global:ReportName = $ReportName   

    if ($Online.IsPresent) { $Global:RunOnline = $true }else { $Global:RunOnline = $false }

    $Global:Repo = 'https://github.com/stefoy/ARI/tree/main/Modules'
    $Global:RawRepo = 'https://raw.githubusercontent.com/stefoy/ARI/main'

    $Global:TableStyle = "Medium15"

    Write-Debug ('Checking if -Online parameter will have to be forced.')

    if(!$Online.IsPresent)
    {
        if($PSScriptRoot -like '*\*')
        {
            $LocalFilesValidation = New-Object System.IO.StreamReader($PSScriptRoot + '\Extension\Metrics.ps1')
        }
        else
        {
            $LocalFilesValidation = New-Object System.IO.StreamReader($PSScriptRoot + '/Extension/Metrics.ps1')
        } 

        if([string]::IsNullOrEmpty($LocalFilesValidation))
        {
            Write-Debug ('Using -Online by force.')
            $Global:RunOnline = $true
        }
        else
        {
            $Global:RunOnline = $false
        }
    }
}

Function RunInventorySetup()
{
    function CheckCliRequirements() 
    {
        Write-Host "Checking Cli Installed..."
        $azCliVersion = az --version
        Write-Host ('CLI Version: {0}' -f $azCliVersion[0]) -ForegroundColor Green
    
        if ($null -eq $azCliVersion) 
        {
            Read-Host "Azure CLI Not Found. Please install to and run the script again, press <Enter> to exit." -ForegroundColor Red
            Exit
        }
    
        Write-Host "Checking Cli Extension..."
        $azCliExtension = az extension list --output json | ConvertFrom-Json
        $azCliExtension = $azCliExtension | Where-Object {$_.name -eq 'resource-graph'}
    
        Write-Host ('Current Resource-Graph Extension Version: {0}' -f $azCliExtension.Version) -ForegroundColor Green
    
        $azCliExtensionVersion = $azcliExt | Where-Object {$_.name -eq 'resource-graph'}
    
        if (!$azCliExtensionVersion) 
        {
            Write-Host "Installng Az Cli Extension..."
            az extension add --name resource-graph
        }
        
        Write-Host "Checking ImportExcel Module..."
    
        $VarExcel = Get-InstalledModule -Name ImportExcel -ErrorAction silentlycontinue
    
        Write-Host ('ImportExcel Module Version: {0}.{1}.{2}' -f ([string]$VarExcel.Version.Major,  [string]$VarExcel.Version.Minor, [string]$VarExcel.Version.Build)) -ForegroundColor Green
    
        if ($null -eq $VarExcel) 
        {
            Write-Host "Trying to install ImportExcel Module.." -ForegroundColor Yellow
            Install-Module -Name ImportExcel -Force
        }
    
        $VarExcel = Get-InstalledModule -Name ImportExcel -ErrorAction silentlycontinue
    
        if ($null -eq $VarExcel) 
        {
            Read-Host 'Admininstrator rights required to install ImportExcel Module. Press <Enter> to finish script'
            Exit
        }
    }
    
    function CheckPowerShell() 
    {
        Write-Host 'Checking PowerShell...'
    
        $Global:PlatformOS = 'PowerShell Desktop'
        $cloudShell = try{Get-CloudDrive}catch{}
        
        if ($cloudShell) 
        {
            Write-Host 'Identified Environment as Azure CloudShell' -ForegroundColor Green
            $Global:PlatformOS = 'Azure CloudShell'
            $defaultOutputDir = "$HOME/AzureResourceInventory/"
        }
        elseif ($PSVersionTable.Platform -eq 'Unix') 
        {
            Write-Host 'Identified Environment as PowerShell Unix.' -ForegroundColor Green
            $Global:PlatformOS = 'PowerShell Unix'
            $defaultOutputDir = "$HOME/AzureResourceInventory/"
        }
        else 
        {
            Write-Host 'Identified Environment as PowerShell Desktop.' -ForegroundColor Green
            $Global:PlatformOS= 'PowerShell Desktop'
            $defaultOutputDir = "C:\AzureResourceInventory\"
        }
    
        if ($OutputDirectory) 
        {
            try 
            {
                $OutputDirectory = Join-Path (Resolve-Path $OutputDirectory -ErrorAction Stop) ('/' -or '\')
            }
            catch 
            {
                Write-Host "ERROR: Wrong OutputDirectory Path! OutputDirectory Parameter must contain the full path." -NoNewline -ForegroundColor Red
                Exit
            }
        }
    
        $Global:DefaultPath = if($OutputDirectory) {$OutputDirectory} else {$defaultOutputDir}
    
        if ($platformOS -eq 'Azure CloudShell') 
        {
            $Global:Subscriptions = @(az account list --output json --only-show-errors | ConvertFrom-Json)
        }
        elseif ($platformOS -eq 'PowerShell Unix' -or $platformOS -eq 'PowerShell Desktop') 
        {
            LoginSession
        }
    }
    
    function LoginSession() 
    {
        Write-Debug ('Checking Login Session')
    
        if(![string]::IsNullOrEmpty($AzureEnvironment))
        {
            az cloud set --name $AzureEnvironment
        }
    
        $CloudEnv = az cloud list | ConvertFrom-Json
        Write-Host "Azure Cloud Environment: " -NoNewline
    
        $CurrentCloudEnvName = $CloudEnv | Where-Object {$_.isActive -eq 'True'}
        Write-Host $CurrentCloudEnvName.name -ForegroundColor Green
    
        if (!$TenantID) 
        {
            Write-Host "Tenant ID not specified. Use -TenantID parameter if you want to specify directly." -ForegroundColor Yellow
            Write-Host "Authenticating Azure"
    
            Write-Debug ('Cleaning az account cache')
            az account clear | Out-Null
            Write-Debug ('Calling az login')
    
            if($DeviceLogin.IsPresent)
            {
                az login --use-device-code
            }
            else 
            {
                az login --only-show-errors | Out-Null
            }
    
            $Tenants = az account list --query [].homeTenantId -o tsv --only-show-errors | Sort-Object -Unique
            Write-Debug ('Checking number of Tenants')
            Write-Host ("")
            Write-Host ("")
    
            if ($Tenants.Count -eq 1) 
            {
                Write-Host "You have privileges only in One Tenant " -ForegroundColor Green
                $TenantID = $Tenants
            }
            else 
            {
                Write-Host "Select the the Azure Tenant ID that you want to connect: "
    
                $SequenceID = 1
                foreach ($TenantID in $Tenants) 
                {
                    write-host "$SequenceID)  $TenantID"
                    $SequenceID ++
                }
    
                [int]$SelectTenant = read-host "Select Tenant (Default 1)"
                $defaultTenant = --$SelectTenant
                $TenantID = $Tenants[$defaultTenant]
    
                if($DeviceLogin.IsPresent)
                {
                    az login --use-device-code -t $TenantID
                }
                else 
                {
                    az login -t $TenantID --only-show-errors | Out-Null
                }
            }
    
            Write-Host "Extracting from Tenant $TenantID" -ForegroundColor Yellow
            Write-Debug ('Extracting Subscription details') 
    
            $Global:Subscriptions = @(az account list --output json --only-show-errors | ConvertFrom-Json)
            $Global:Subscriptions = @($Subscriptions | Where-Object { $_.tenantID -eq $TenantID })
        }
        else 
        {
            az account clear | Out-Null
    
            if (!$Appid) 
            {
                if($DeviceLogin.IsPresent)
                {
                    az login --use-device-code -t $TenantID
                }
                else 
                {
                    az login -t $TenantID --only-show-errors | Out-Null
                }
            }
            elseif ($Appid -and $Secret -and $tenantid) 
            {
                Write-Host "Using Service Principal Authentication Method" -ForegroundColor Green
                az login --service-principal -u $appid -p $secret -t $TenantID | Out-Null
            }
            else
            {
                Write-Host "You are trying to use Service Principal Authentication Method in a wrong way." -ForegroundColor Red
                Write-Host "It's Mandatory to specify Application ID, Secret and Tenant ID in Azure Resource Inventory" -ForegroundColor Red
                Write-Host ".\AzureResourceInventory.ps1 -appid <SP AppID> -secret <SP Secret> -tenant <TenantID>" -ForegroundColor Red
                Exit
            }
    
            $Global:Subscriptions = @(az account list --output json --only-show-errors | ConvertFrom-Json)
            $Global:Subscriptions = @($Subscriptions | Where-Object { $_.tenantID -eq $TenantID })
        }
    }
    
    function GetSubscriptionsData()
    {
        Write-Progress -activity 'Azure Inventory' -Status "1% Complete." -PercentComplete 2 -CurrentOperation 'Discovering Subscriptions..'
    
        $SubscriptionCount = $Subscriptions.Count
        
        Write-Debug ("Number of Subscriptions Found: {0}" -f $SubscriptionCount)
        Write-Progress -activity 'Azure Inventory' -Status "3% Complete." -PercentComplete 3 -CurrentOperation "$SubscriptionCount Subscriptions found.."
        
        Write-Debug ('Checking report folder: ' + $DefaultPath )
        
        if ((Test-Path -Path $DefaultPath -PathType Container) -eq $false) 
        {
            New-Item -Type Directory -Force -Path $DefaultPath | Out-Null
        }
    }
    
    function ResourceInventoryLoop()
    {
        Write-Progress -activity 'Azure Inventory' -Status "4% Complete." -PercentComplete 4 -CurrentOperation "Starting Resources extraction jobs.."        
    
        $GraphQuery = "resources | where strlen(properties.definition.actions) < 123000 | summarize count()"
        $EnvSize = az graph query -q  $GraphQuery --output json --only-show-errors | ConvertFrom-Json
        $EnvSizeCount = $EnvSize.Data.'count_'
        
        Write-Host ("Resources Output: {0} Resources Identified" -f $EnvSizeCount) -BackgroundColor Black -ForegroundColor Green
        
        if ($EnvSizeCount -ge 1) 
        {
            $Loop = $EnvSizeCount / 1000
            $Loop = [math]::Ceiling($Loop)
            $Looper = 0
            $Limit = 0
        
            while ($Looper -lt $Loop) 
            {
                $GraphQuery = "resources | where strlen(properties.definition.actions) < 123000 | project id,name,type,tenantId,kind,location,resourceGroup,subscriptionId,managedBy,sku,plan,properties,identity,zones,extendedLocation | order by id asc"
                $Resource = (az graph query -q $GraphQuery --skip $Limit --first 1000 --output json --only-show-errors).tolower() | ConvertFrom-Json
        
                $Global:Resources += $Resource.Data
                Start-Sleep 2
                $Looper++
                Write-Progress -Id 1 -activity "Running Resource Inventory Job" -Status "$Looper / $Loop of Inventory Jobs" -PercentComplete (($Looper / $Loop) * 100)
                $Limit = $Limit + 1000
            }
        }
        
        Write-Progress -Id 1 -activity "Running Resource Inventory Job" -Status "$Looper / $Loop of Inventory Jobs" -Completed
    }
    
    function ResourceInventoryAvd()
    {
        Write-Progress -activity 'Azure Inventory' -Status "4% Complete." -PercentComplete 4 -CurrentOperation "Starting AVD Resources extraction jobs.."       
    
        $AVDSize = az graph query -q "desktopvirtualizationresources | summarize count()" --output json --only-show-errors | ConvertFrom-Json
        $AVDSizeCount = $AVDSize.data.'count_'
    
        Write-Host ("AVD Resources Output: {0} AVD Resources Identified" -f $AVDSizeCount) -BackgroundColor Black -ForegroundColor Green
    
        if ($AVDSizeCount -ge 1) 
        {
            $Loop = $AVDSizeCount / 1000
            $Loop = [math]::ceiling($Loop)
            $Looper = 0
            $Limit = 0
    
            while ($Looper -lt $Loop) 
            {
                $GraphQuery = "desktopvirtualizationresources | project id,name,type,tenantId,kind,location,resourceGroup,subscriptionId,managedBy,sku,plan,properties,identity,zones,extendedLocation$($GraphQueryTags) | order by id asc"
                $AVD = (az graph query -q $GraphQuery --skip $Limit --first 1000 --output json --only-show-errors).tolower() | ConvertFrom-Json
    
                $Global:Resources += $AVD.data
                Start-Sleep 2
                $Looper++
                Write-Progress -Id 1 -activity "Running AVD Resource Inventory Job" -Status "$Looper / $Loop of Inventory Jobs" -PercentComplete (($Looper / $Loop) * 100)
                $Limit = $Limit + 1000
            }
        }
    
        Write-Progress -Id 1 -activity "Running AVD Resource Inventory Job" -Status "$Looper / $Loop of Inventory Jobs" -Completed
    }

    CheckCliRequirements
    CheckPowerShell
    GetSubscriptionsData
    ResourceInventoryLoop
    ResourceInventoryAvd
}

function ExecuteInventoryProcessing()
{
    function InitializeInventoryProcessing()
    {
        $CurrentDateTime = (get-date -Format "yyyyMMddHHmm")
        $Global:File = ($DefaultPath + $Global:ReportName + $CurrentDateTime + ".xlsx")
        $Global:AllResourceFile = ($DefaultPath + "Full_" + $Global:ReportName + $CurrentDateTime + ".json")
        $Global:JsonFile = ($DefaultPath + "Inventory_"+ $Global:ReportName + "_"+  $CurrentDateTime + ".json")
        $Global:MetricsJsonFile = ($DefaultPath + "Metrics_"+ $Global:ReportName + "_"+  $CurrentDateTime + ".json")

        Write-Debug ('Report Excel File: {0}' -f $File)
        Write-Progress -activity 'Azure Inventory' -Status "21% Complete." -PercentComplete 21 -CurrentOperation "Starting to process extraction data.."
    }

    function CreateMetricsJob()
    {
        Write-Debug ('Checking if Metrics Job Should be Run.')

        if (!$SkipMetrics.IsPresent) 
        {
            Write-Debug ('Starting Metrics Processing Job.')

            If ($RunOnline -eq $true) 
            {
                Write-Debug ('Looking for the following file: '+$RawRepo + '/Extension/Metrics.ps1')
                $ModuSeq = (New-Object System.Net.WebClient).DownloadString($RawRepo + '/Extension/Metrics.ps1')
            }
            else 
            {
                if($PSScriptRoot -like '*\*')
                {
                    $MetricPath = Get-ChildItem -Path ($PSScriptRoot + '\Extension\Metrics.ps1') -Recurse
                }
                else
                {
                    $MetricPath = Get-ChildItem -Path ($PSScriptRoot + '/Extension/Metrics.ps1') -Recurse
                }
            }

            $Global:AzMetrics = & $MetricPath -Subscriptions $Subscriptions -Resources $Resources -Task "Processing" -File $file -Metrics $null -TableStyle $null -ConcurencyLimit $ConcurencyLimit
        }
    }

    function ProcessMetricsResult()
    {
        if (!$SkipMetrics.IsPresent) 
        {
            Write-Debug ('Generating Subscription Metrics Outputs.')
            Write-Progress -activity 'Resource Inventory Metrics' -Status "50% Complete." -PercentComplete 50 -CurrentOperation "Building Metrics Outputs"

            $Global:AzMetrics | ConvertTo-Json -depth 100 -compress | Out-File $Global:MetricsJsonFile
    
            If ($RunOnline -eq $true) 
            {
                Write-Debug ('Looking for the following file: '+$RawRepo + '/Extension/Metrics.ps1')
                $ModuSeq = (New-Object System.Net.WebClient).DownloadString($RawRepo + '/Extension/Metrics.ps1')
            }
            else 
            {
                if($PSScriptRoot -like '*\*')
                {
                    $MetricPath = Get-ChildItem -Path ($PSScriptRoot + '\Extension\Metrics.ps1') -Recurse
                }
                else
                {
                    $MetricPath = Get-ChildItem -Path ($PSScriptRoot + '/Extension/Metrics.ps1') -Recurse
                }
            }

            $ProcessResults = & $MetricPath -Subscriptions $null -Resources $null -Task "Reporting" -File $file -Metrics $Global:AzMetrics -TableStyle $Global:TableStyle
        }
    }

    function CreateResourceJobs()
    {
        $Global:SmaResources = New-Object PSObject

        Write-Debug ('Starting Service Processing Jobs.')

        if($($args[1]) -like '*\*')
        {
            $Modules = Get-ChildItem -Path ($PSScriptRoot +  '\Services\*.ps1') -Recurse
        }
        else
        {
            $Modules = Get-ChildItem -Path ($PSScriptRoot +  '/Services/*.ps1') -Recurse
        }

        $Resource = $Resources | Select-Object -First $Resources.count
        $Resource = ($Resource | ConvertTo-Json -Depth 50)

        foreach ($Module in $Modules) 
        {
            $ModName = $Module.Name.Substring(0, $Module.Name.length - ".ps1".length)
            
            Write-Host ("Service Processing: {0} {1}" -f $Module, $ModName) -ForegroundColor Green
            $result = & $Module -SCPath $SCPath -Sub $Subscriptions -Resources ($Resource | ConvertFrom-Json) -Task "Processing" -File $file -SmaResources $null -TableStyle $null 
            $Global:SmaResources | Add-Member -MemberType NoteProperty -Name $ModName -Value NotSet
            $Global:SmaResources.$ModName = $result

            $result = $null
            #$([System.GC]::GetTotalMemory($false))
            [System.GC]::Collect()
            #$([System.GC]::GetTotalMemory($true))

            #$Global:SmaResources = & $Module -SCPath $SCPath -Sub $Subscriptions -Resources ($Resource | ConvertFrom-Json) -Task "Processing" -File $file -SmaResources $null -TableStyle $null 
        }
    }

    function ProcessResourceResult()
    {
        Write-Debug ('Starting Reporting Phase.')
        $DataActive = ('Azure Resource Inventory Reporting (' + ($resources.count) + ') Resources')
        Write-Progress -activity $DataActive -Status "Processing Inventory" -PercentComplete 50

        $ResourceJobs = 'Compute', 'Analytics', 'Containers', 'Data', 'Infrastructure', 'Integration', 'Networking', 'Storage'
        $Services = @()

        if($PSScriptRoot -like '*\*')
        {
            $Services = Get-ChildItem -Path ($PSScriptRoot + '\Services\*.ps1') -Recurse
        }
        else
        {
            $Services = Get-ChildItem -Path ($PSScriptRoot + '/Services/*.ps1') -Recurse
        }

        Write-Debug ('Services Found: ' + $Services.Count)
        $Lops = $Services.count
        $ReportCounter = 0

        foreach ($Service in $Services) 
        {
            $c = (($ReportCounter / $Lops) * 100)
            $c = [math]::Round($c)
            Write-Progress -Id 1 -activity "Building Report" -Status "$c% Complete." -PercentComplete $c

            Write-Debug "Running Services: '$Service'"
            
            $ProcessResults = & $Service.FullName -SCPath $PSScriptRoot -Sub $null -Resources $null -Task "Reporting" -File $file -SmaResources $Global:SmaResources -TableStyle $Global:TableStyle

            $ReportCounter++
        }

        $Global:SmaResources | ConvertTo-Json -depth 100 -compress | Out-File $Global:JsonFile
        $Global:Resources | ConvertTo-Json -depth 100 -compress | Out-File $Global:AllResourceFile
        
        Write-Debug ('Resource Reporting Phase Done.')
    }


    InitializeInventoryProcessing
    CreateMetricsJob
    CreateResourceJobs   
    ProcessMetricsResult
    ProcessResourceResult
}


$Global:Runtime = Measure-Command -Expression {
    Variables
    RunInventorySetup
}

$Global:ReportingRunTime = Measure-Command -Expression {
    ExecuteInventoryProcessing
}

Write-Host ("Execution Time: {0}" -f $Runtime)
Write-Host ("Reporting Time: {0}" -f $ReportingRunTime)
