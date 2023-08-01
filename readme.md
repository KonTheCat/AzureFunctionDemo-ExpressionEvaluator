# What this Is

# Deployment Guide

1. Clone repository.
2. Run something like the below: 

```
$rg = New-AzResourceGroup -ResourceGroupName "ExpressionEvaluator" -Location "East US"
New-AzResourceGroupDeployment -TemplateFile .\infrastructure.bicep -Location $rg.Location -ResourceGroupName $rg.ResourceGroupName -Verbose
```

# Sources

1. Initial Bicep: https://learn.microsoft.com/en-us/azure/azure-functions/functions-create-first-function-bicep?tabs=CLI
2. Additional Azure Functions Bicep: https://gist.github.com/kkamegawa/6594200b770c0326f249ea797e3b61cd
3. Source Control: https://azure.github.io/AppService/2021/07/23/Quickstart-Intro-to-Bicep-with-Web-App-plus-DB.html
4. Manual deployment because of this: https://learn.microsoft.com/en-us/azure/azure-functions/functions-deployment-technologies?tabs=linux#deployment-technology-availability
5. Using identity for function storage instead of keys: https://learn.microsoft.com/en-us/azure/azure-functions/functions-identity-based-connections-tutorial
6. Key Vault: https://learn.microsoft.com/en-us/azure/key-vault/secrets/quick-create-bicep?tabs=CLI
7. Key Vault secret in function environment variables: https://dev.to/dazfuller/azure-bicep-deploy-function-apps-with-keyvault-references-36o1