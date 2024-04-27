param (
    [Parameter(Mandatory=$true)]
    [string] $configFile
)

$config = Get-Content $configFile -ErrorAction Stop | ConvertFrom-Json

# Set the context or log in
if ($null -ne (Get-AzContext).Account) {
    $oldContext = Get-AzContext
    Write-Output "Setting Azure context to subscription $($config.subscriptionId)"
    Set-AzContext -SubscriptionId $config.subscriptionId -ErrorAction Stop | Out-Null
} else {
    $signedIn = $true
    Write-Output "Logging into Azure account"
    Login-AzAccount -SubscriptionId $config.subscriptionId -ErrorAction Stop | Out-Null
}

# Set the deployment name if not provided
$deploymentName = $config.deploymentName -ne '' ? $config.deploymentName : "deployment-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

# Create the resource group if it doesn't exist
if (!(Get-AzResourceGroup -Name $config.resourceGroupName -ErrorAction SilentlyContinue)) {
    Write-Output "Creating resource group $($config.resourceGroupName) in location $($config.location)"
    New-AzResourceGroup -Name $config.resourceGroupName -Location $config.location -ErrorAction Stop | Out-Null
}

# Deploy the template
Write-Output "Deploying to resource group $($config.resourceGroupName)"
New-AzResourceGroupDeployment `
    -ResourceGroupName $config.resourceGroupName `
    -TemplateFile $config.templateFile `
    -adminPassword (Read-Host -AsSecureString -Prompt "Admin password") `
    -DeploymentName $deploymentName `
    -ErrorAction Stop `
    -WarningAction SilentlyContinue

# Switch back to previous context or log out
if ($null -ne $oldContext) {
    Write-Output "Switching back to previous Azure context"
    Set-AzContext -SubscriptionId $oldContext.Subscription.Id | Out-Null
}
elseif ($signedIn) {
    Write-Output "Logging out of Azure account"
    Logout-AzAccount | Out-Null
}
