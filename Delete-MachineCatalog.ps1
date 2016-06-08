# 
# Delete Machine Catalog 'Windows 7 x86'
# 
# 21/07/2014 6:59 AM
# 
Get-ConfigServiceStatus  -AdminAddress 'xd71.home.stealthpuppy.com:80'

Get-LogSite  -AdminAddress 'xd71.home.stealthpuppy.com:80'

Start-LogHighLevelOperation  -AdminAddress 'xd71.home.stealthpuppy.com:80' -Source 'Studio' -StartTime 20/07/2014 8:59:05 PM -Text 'Delete Machine Catalog `'Windows 7 x86`''

Set-Variable  -Name 'ProvSchemeNames' -Value @('Windows 7 x86')

Get-ProvScheme  -AdminAddress 'xd71.home.stealthpuppy.com:80' -Filter 'ProvisioningSchemeName -in $ProvSchemeNames' -MaxRecordCount 2147483647 -ReturnTotalRecordCount -Skip 0

# Get-ProvScheme : Returned 1 of 1 items
# 
# 	+ CategoryInfo : OperationStopped: (:) [Get-ProvScheme], PartialDataException
# 	+ FullyQualifiedErrorId : Citrix.XDPowerShell.Status.PartialData,Citrix.MachineCreation.Sdk.Commands.GetProvSchemeCommand
Remove-Variable  -Name 'ProvSchemeNames'

Set-Variable  -Name 'CatalogIds' -Value @(2027)

Get-BrokerMachine  -AdminAddress 'xd71.home.stealthpuppy.com:80' -Filter 'CatalogUid -in $CatalogIds' -MaxRecordCount 2147483647 -ReturnTotalRecordCount -Skip 0

# Get-BrokerMachine : Returned 5 of 5 items
# 
# 	+ CategoryInfo : OperationStopped: (:) [Get-BrokerMachine], PartialDataException
# 	+ FullyQualifiedErrorId : Citrix.XDPowerShell.Broker.PartialData,Citrix.Broker.Admin.SDK.GetBrokerMachineCommand
Remove-Variable  -Name 'CatalogIds'

Set-Variable  -Name 'Machines' -Value @(1118,1119,1120,1121,1122)

Get-BrokerMachine  -AdminAddress 'xd71.home.stealthpuppy.com:80' -Filter {(Uid -in $Machines)} -MaxRecordCount 2147483647

Remove-Variable  -Name 'Machines'

Set-Variable  -Name 'MCSVirtualMachineNames' -Value @('S-1-5-21-733536048-680991148-2551668650-2894','S-1-5-21-733536048-680991148-2551668650-2895','S-1-5-21-733536048-680991148-2551668650-2896','S-1-5-21-733536048-680991148-2551668650-2897','S-1-5-21-733536048-680991148-2551668650-2898')

Get-ProvVM  -AdminAddress 'xd71.home.stealthpuppy.com:80' -Filter 'ADAccountSid -in $MCSVirtualMachineNames' -MaxRecordCount 2147483647 -ReturnTotalRecordCount -Skip 0

# Get-ProvVM : Returned 5 of 5 items
# 
# 	+ CategoryInfo : OperationStopped: (:) [Get-ProvVM], PartialDataException
# 	+ FullyQualifiedErrorId : Citrix.XDPowerShell.Status.PartialData,Citrix.MachineCreation.Sdk.Commands.GetProvVMCommand
Remove-Variable  -Name 'MCSVirtualMachineNames'

Unlock-ProvVM  -AdminAddress 'xd71.home.stealthpuppy.com:80' -LoggingId a34c8bcb-7112-42c1-8b5a-d7deedc072db -ProvisioningSchemeUid 3c5a298f-c8c1-4012-8198-a4526454a4c5 -VMID @('c889616d-bf11-4fc3-bf51-324e2a3c5e00','2a1c1892-35b1-49a4-aa68-be18d243474b','811b4d54-d9b1-4052-b296-78be5a0fb173','e32f7150-6e3e-4954-a8fb-05427be03802','504a2875-de64-426f-8708-328dbb2045b5')

Remove-ProvVM  -AdminAddress 'xd71.home.stealthpuppy.com:80' -ForgetVM -LoggingId a34c8bcb-7112-42c1-8b5a-d7deedc072db -ProvisioningSchemeUid 3c5a298f-c8c1-4012-8198-a4526454a4c5 -RunAsynchronously -VMName @('W7-MCS-001','W7-MCS-002','W7-MCS-003','W7-MCS-004','W7-MCS-005')

Get-ProvScheme  -AdminAddress 'xd71.home.stealthpuppy.com:80' -MaxRecordCount 2147483647 -ProvisioningSchemeUid 3c5a298f-c8c1-4012-8198-a4526454a4c5

Set-Variable  -Name 'Machines' -Value @('S-1-5-21-733536048-680991148-2551668650-2894','S-1-5-21-733536048-680991148-2551668650-2895','S-1-5-21-733536048-680991148-2551668650-2896','S-1-5-21-733536048-680991148-2551668650-2897','S-1-5-21-733536048-680991148-2551668650-2898')

Get-BrokerMachine  -AdminAddress 'xd71.home.stealthpuppy.com:80' -Filter {(SID -in $Machines)} -MaxRecordCount 2147483647

Remove-Variable  -Name 'Machines'

Remove-BrokerMachine  -AdminAddress 'xd71.home.stealthpuppy.com:80' -Force -InputObject @(1118,1119,1120,1121,1122) -LoggingId a34c8bcb-7112-42c1-8b5a-d7deedc072db

Get-BrokerRemotePCAccount  -AdminAddress 'xd71.home.stealthpuppy.com:80' -CatalogUid 2027 -MaxRecordCount 2147483647

Get-ProvVM  -AdminAddress 'xd71.home.stealthpuppy.com:80' -Filter {ProvisioningSchemeUid -eq '3c5a298f-c8c1-4012-8198-a4526454a4c5'} -MaxRecordCount 0 -ProvisioningSchemeUid 3c5a298f-c8c1-4012-8198-a4526454a4c5 -ReturnTotalRecordCount

# Get-ProvVM : Returned 0 of 0 items
# 
# 	+ CategoryInfo : OperationStopped: (:) [Get-ProvVM], PartialDataException
# 	+ FullyQualifiedErrorId : Citrix.XDPowerShell.Status.PartialData,Citrix.MachineCreation.Sdk.Commands.GetProvVMCommand
Remove-ProvScheme  -AdminAddress 'xd71.home.stealthpuppy.com:80' -LoggingId a34c8bcb-7112-42c1-8b5a-d7deedc072db -ProvisioningSchemeUid 3c5a298f-c8c1-4012-8198-a4526454a4c5

Get-BrokerCatalog  -AdminAddress 'xd71.home.stealthpuppy.com:80' -MaxRecordCount 2147483647 -ProvisioningType 'MCS'

Get-AcctADAccount  -AdminAddress 'xd71.home.stealthpuppy.com:80' -IdentityPoolUid a75840ff-9eda-4d31-bc16-5b98bd365368 -MaxRecordCount 2147483647

Remove-AcctADAccount  -ADAccountSid @('S-1-5-21-733536048-680991148-2551668650-2894','S-1-5-21-733536048-680991148-2551668650-2895','S-1-5-21-733536048-680991148-2551668650-2896','S-1-5-21-733536048-680991148-2551668650-2897','S-1-5-21-733536048-680991148-2551668650-2898') -AdminAddress 'xd71.home.stealthpuppy.com:80' -Force -IdentityPoolUid a75840ff-9eda-4d31-bc16-5b98bd365368 -LoggingId a34c8bcb-7112-42c1-8b5a-d7deedc072db -RemovalOption 'None'

Remove-AcctIdentityPool  -AdminAddress 'xd71.home.stealthpuppy.com:80' -IdentityPoolUid a75840ff-9eda-4d31-bc16-5b98bd365368 -LoggingId a34c8bcb-7112-42c1-8b5a-d7deedc072db

Remove-BrokerCatalog  -AdminAddress 'xd71.home.stealthpuppy.com:80' -InputObject @(2027) -LoggingId a34c8bcb-7112-42c1-8b5a-d7deedc072db

Stop-LogHighLevelOperation  -AdminAddress 'xd71.home.stealthpuppy.com:80' -EndTime 20/07/2014 8:59:20 PM -HighLevelOperationId 'a34c8bcb-7112-42c1-8b5a-d7deedc072db' -IsSuccessful $True
# Script completed successfully
