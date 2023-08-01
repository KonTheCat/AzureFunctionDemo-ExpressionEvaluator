# What this Is

This is a teaching/demonstration model of a Consumption-tier Azure Function in Python. It is intended to demonstrate different triggers by getting from the trigger an expression to be evaluated and running it through the Python eval() function.

Please note that this allows for code injection and thus should not be used in any production setting: https://vk9-sec.com/exploiting-python-eval-code-injection/

# Deployment Guide

Requirements: git, Python 3.10, VS Code, Azure Tools Extensions for VScode, Azure PowerShell or Azure CLI.

1. Clone repository.
2. Run something like the below: 

```
$rg = New-AzResourceGroup -ResourceGroupName "ExpressionEvaluator" -Location "East US"
New-AzResourceGroupDeployment -TemplateFile .\infrastructure.bicep -Location $rg.Location -ResourceGroupName $rg.ResourceGroupName -Verbose
```
3. Deploy from Visual Studio Code: https://learn.microsoft.com/en-us/azure/azure-functions/functions-develop-vs-code?tabs=csharp#republish-project-files

# Sources

1. Initial Bicep: https://learn.microsoft.com/en-us/azure/azure-functions/functions-create-first-function-bicep?tabs=CLI
2. Additional Azure Functions Bicep: https://gist.github.com/kkamegawa/6594200b770c0326f249ea797e3b61cd
3. Source Control: https://azure.github.io/AppService/2021/07/23/Quickstart-Intro-to-Bicep-with-Web-App-plus-DB.html
4. Manual deployment because of this: https://learn.microsoft.com/en-us/azure/azure-functions/functions-deployment-technologies?tabs=linux#deployment-technology-availability