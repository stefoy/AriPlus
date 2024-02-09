# CloudRays ARI+

ARI+ is an enhanced version of the [Azure Resource Inventory](https://github.com/microsoft/ARI) (ARI) tool. ARI is a robust PowerShell script provided by Microsoft that generates an Excel report of any Azure environment to which you have read access. This tool aims to assist Cloud Administrators and other professionals in creating a comprehensive Excel report of an Azure Environment quickly and easily. ARI+ enhances the original script by capturing additional utilization metrics. This repository is professionally maintained by AWS, focusing exclusively on read-only integrations with Azure API's and Azure Monitor.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Running the Script](#running-the-script)
- [Acknowledgments](#acknowledgments)

## Prerequisites

ARI+ can be executed in both Azure Cloudshell and PowerShell Desktop environments. 

### Requirements
> **Note:** By default, Azure Resource Inventory will attempt to install the necessary PowerShell modules and Azure CLI components, but you need administrator privileges during the script execution.


- PowerShell 7 or Azure CloudShell
- Azure CLI
- Azure CLI Account Extension
- Azure CLI Resource-Graph Extension


### Dependencies

Install the required PowerShell module:

```powershell
Install-Module ImportExcel
```

## Installation

1. Clone the repository or download the `ResourceInventory.ps1` script.

```bash
git clone https://github.com/stefoy/AriPlus
```

## Running the Script

ARI+ uses concurrency to execute commands in parallel, especially when gathering metrics. By default, the concurrency limit is set to 6. To change this, use the `-ConcurrencyLimit` option. 

2. If you are in Azure CloudShell, you're already authenticated. In PowerShell Desktop, you will be redirected to the Azure sign-in page.

```powershell
./ResourceInventory.ps1 -ConcurrencyLimit 8
```

## Script Output/Reports
3. When the script has completed, a zip file of the report will be saved in the folder **_AriPlusReports._**
     - ARI+ will create 4 files and one zip 
         - Consumption_ResourcesReport_(date).json 
         - Inventory_ResourcesReport_(date).json 
         - Metrics_ResourcesReport_(date).json 
         - ResourcesReport_(date).xlsx 

     - These 4 files zipped up automatically and the zip is what is sent back to AWS
         - ResourcesReport_(date).zip

---

## Parameters

The following table lists the parameters that can be used with the script:

| Parameter         | Type     | Description                                                                                                     |
|-------------------|----------|-----------------------------------------------------------------------------------------------------------------|
| `$TenantID`       | String   | Specifies the Tenant ID you want to create a Resource Inventory                                                                                       |
| `$Appid`          | String   | Service Principal Authentication ID.                                                                                   |
| `$SubscriptionID` | String   | Specifies the Subscription which will be run for Inventory.                                                                                  |
| `$Secret`         | String   | Client Secret of the Service Principal key.                                                                                       |
| `$ResourceGroup`  | String   | Specifies the Resource Group.                                                                                   |
| `$Debug`          | Switch   | Enable Debug Mode                                                                                  |
| `$SkipMetrics`    | Switch   | A switch to skip metrics retrieval.                                                                             |
| `$Help`           | Switch   | A switch to display the help message.                                                                           |
| `$SkipConsumption`| Switch   | A switch to indicate if consumption metrics should be gathered.                                                |
| `$DeviceLogin`    | Switch   | A switch to trigger device login.                                                                               |
| `$ConcurrencyLimit` | Integer | Specifies the concurrency limit for parallel command execution. Default value is `6`.                            |

---

## ⚠️ Warning Messages

- **Important:** Azure Resource Inventory will not upgrade the current version of the Powershell modules.
  
- **Important:** If you're running the script inside Azure CloudShell, the final Excel will not have auto-fit columns, and you will see warnings during the script execution. This is an issue with the Import-Excel module but it does not affect the inventory which will remain accurate.

---

## Maintained by

- **Stephen Foy** | [foys@amazon.com](mailto:foys@amazon.com)
- **Aidan Keane** | [ajkeane@amazon.com](mailto:ajkeane@amazon.com)

---

## Acknowledgments

Special thanks to Doug Finke, the author of the PowerShell ImportExcel Module. 

---
