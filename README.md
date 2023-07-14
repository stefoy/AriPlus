# AriPlus

Based on Azure Resource Inventory (https://github.com/microsoft/ARI), Azure Resource inventory (ARI) is a powerful script written in powershell that generates an Excel report of any Azure Environment you have read access.
This project is intend to help Cloud Admins and anyone that might need an easy and fast way to build a full Excel Report of an Azure Environment.

ARIPlus has been customized to capture additional information such as utilization metrics.

## Prerequisites
You can use Azure Resource Inventory in both in Cloudshell and Powershell Desktop.

What things you need to run the script

* Install-Module ImportExcel
* Install Azure CLI
* Install Azure CLI Account Extension
* Install Azure CLI Resource-Graph Extension
* :exclamation: **REQUIRES POWERSHELL 7 or AZURE CLOUDSHELL**
  
By default Azure Resource Inventory will call to install the required Powershell modules and Azure CLI components but you must have administrator privileges during the script execution.

Special Thanks for Doug Finke, the Author of Powershell ImportExcel Module.

## Running the script

This script uses Concurrency to to execute commands in parallel when gathering metrics, the default is set to 2, to override this use the option.

  -ConcurrencyLimit <value> 

* Run "ResourceInventory.ps1". In Azure CloudShell you're already authenticated. In PowerShell Desktop you will be redirected to  Azure sign-in page. 

