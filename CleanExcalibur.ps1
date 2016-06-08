Add-pssnapin Citrix*
Get-BrokerDesktopGroup | Set-BrokerDesktopGroup -InMaintenanceMode $True
Get-BrokerDesktopGroup | Remove-BrokerDesktopGroup
Get-BrokerCatalog | Remove-BrokerCatalog
# Get-ProvScheme | Unlock-ProvScheme
# Get-ProvScheme | Remove-ProvSchemeMasterVMImageHistory
# Get-ProvScheme | Remove-ProvSchemeControllerAddress
# Get-ProvScheme | Remove-ProvSchemeMetadata
# Get-ProvScheme | Remove-ProvSchemeScope
Get-ProvVM | Unlock-ProvVM -Verbose
Get-ProvVM | Remove-ProvVM -verbose
Get-ProvScheme | Remove-ProvScheme
Get-AcctADAccount | Remove-AcctADAccount -Verbose
Get-AcctIdentityPool | Remove-AcctIdentityPool -Verbose