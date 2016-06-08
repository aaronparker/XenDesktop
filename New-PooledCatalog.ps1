# 
# Create Machine Catalog 'Windows 7 x86'
# 
# 21/07/2014 6:47 AM
# 
# Get-ConfigServiceStatus  -AdminAddress 'xd71.home.stealthpuppy.com:80'

# Get-LogSite  -AdminAddress 'xd71.home.stealthpuppy.com:80'

# Start-LogHighLevelOperation  -AdminAddress 'xd71.home.stealthpuppy.com:80' -Source 'Studio' -StartTime 20/07/2014 8:34:59 PM -Text 'Create Machine Catalog `'Windows 7 x86`''

New-BrokerCatalog  -AdminAddress 'xd71.home.stealthpuppy.com:80' -AllocationType 'Random' -Description 'Windows 7 x86 SP1 with Office 2010' -IsRemotePC $False -LoggingId f03ebe89-4133-4a69-8409-c8f83423e8fb -MinimumFunctionalLevel 'L7' -Name 'Windows 7 x86' -PersistUserChanges 'Discard' -ProvisioningType 'MCS' -Scope @() -SessionSupport 'SingleSession'

New-AcctIdentityPool  -AdminAddress 'xd71.home.stealthpuppy.com:80' -AllowUnicode -Domain 'home.stealthpuppy.com' -IdentityPoolName 'Windows 7 x86' -LoggingId f03ebe89-4133-4a69-8409-c8f83423e8fb -NamingScheme 'W7-MCS-###' -NamingSchemeType 'Numeric' -OU 'OU=MCS Pooled,OU=Workstations,DC=home,DC=stealthpuppy,DC=com' -Scope @()

Set-BrokerCatalogMetadata  -AdminAddress 'xd71.home.stealthpuppy.com:80' -CatalogId 2027 -LoggingId f03ebe89-4133-4a69-8409-c8f83423e8fb -Name 'Citrix_DesktopStudio_IdentityPoolUid' -Value 'a75840ff-9eda-4d31-bc16-5b98bd365368'

Test-ProvSchemeNameAvailable  -AdminAddress 'xd71.home.stealthpuppy.com:80' -ProvisioningSchemeName @('Windows 7 x86')

New-ProvScheme  -AdminAddress 'xd71.home.stealthpuppy.com:80' -CleanOnBoot -HostingUnitName 'HV1-LocalStorage' -IdentityPoolName 'Windows 7 x86' -LoggingId f03ebe89-4133-4a69-8409-c8f83423e8fb -MasterImageVM 'XDHyp:\HostingUnits\HV1-LocalStorage\WIN71.vm\MasterImage v1.snapshot' -NetworkMapping @{'A2AB1574-74E9-4C33-9029-26F2812BD675'='XDHyp:\HostingUnits\HV1-LocalStorage\\VM External Network.network'} -ProvisioningSchemeName 'Windows 7 x86' -RunAsynchronously -Scope @() -VMCpuCount 2 -VMMemoryMB 768

Get-ProvTask  -AdminAddress 'xd71.home.stealthpuppy.com:80' -MaxRecordCount 2147483647 -TaskId 61f871c8-dbbb-482f-955f-fc1d618bea67

Set-BrokerCatalog  -AdminAddress 'xd71.home.stealthpuppy.com:80' -LoggingId f03ebe89-4133-4a69-8409-c8f83423e8fb -Name 'Windows 7 x86' -ProvisioningSchemeId 3c5a298f-c8c1-4012-8198-a4526454a4c5 -RemotePCHypervisorConnectionUid $null

Add-ProvSchemeControllerAddress  -AdminAddress 'xd71.home.stealthpuppy.com:80' -ControllerAddress @('XD71.home.stealthpuppy.com') -LoggingId f03ebe89-4133-4a69-8409-c8f83423e8fb -ProvisioningSchemeName 'Windows 7 x86'

Get-AcctADAccount  -AdminAddress 'xd71.home.stealthpuppy.com:80' -IdentityPoolUid a75840ff-9eda-4d31-bc16-5b98bd365368 -Lock $False -MaxRecordCount 2147483647 -State 'Available'

New-AcctADAccount  -AdminAddress 'xd71.home.stealthpuppy.com:80' -Count 5 -IdentityPoolUid a75840ff-9eda-4d31-bc16-5b98bd365368 -LoggingId f03ebe89-4133-4a69-8409-c8f83423e8fb

New-ProvVM  -ADAccountName @('HOME\W7-MCS-001$','HOME\W7-MCS-002$','HOME\W7-MCS-003$','HOME\W7-MCS-004$','HOME\W7-MCS-005$') -AdminAddress 'xd71.home.stealthpuppy.com:80' -LoggingId f03ebe89-4133-4a69-8409-c8f83423e8fb -ProvisioningSchemeName 'Windows 7 x86' -RunAsynchronously

Lock-ProvVM  -AdminAddress 'xd71.home.stealthpuppy.com:80' -LoggingId f03ebe89-4133-4a69-8409-c8f83423e8fb -ProvisioningSchemeName 'Windows 7 x86' -Tag 'Brokered' -VMID @('c889616d-bf11-4fc3-bf51-324e2a3c5e00')

New-BrokerMachine  -AdminAddress 'xd71.home.stealthpuppy.com:80' -CatalogUid 2027 -LoggingId f03ebe89-4133-4a69-8409-c8f83423e8fb -MachineName 'S-1-5-21-733536048-680991148-2551668650-2894'

Lock-ProvVM  -AdminAddress 'xd71.home.stealthpuppy.com:80' -LoggingId f03ebe89-4133-4a69-8409-c8f83423e8fb -ProvisioningSchemeName 'Windows 7 x86' -Tag 'Brokered' -VMID @('2a1c1892-35b1-49a4-aa68-be18d243474b')

New-BrokerMachine  -AdminAddress 'xd71.home.stealthpuppy.com:80' -CatalogUid 2027 -LoggingId f03ebe89-4133-4a69-8409-c8f83423e8fb -MachineName 'S-1-5-21-733536048-680991148-2551668650-2895'

Lock-ProvVM  -AdminAddress 'xd71.home.stealthpuppy.com:80' -LoggingId f03ebe89-4133-4a69-8409-c8f83423e8fb -ProvisioningSchemeName 'Windows 7 x86' -Tag 'Brokered' -VMID @('811b4d54-d9b1-4052-b296-78be5a0fb173')

New-BrokerMachine  -AdminAddress 'xd71.home.stealthpuppy.com:80' -CatalogUid 2027 -LoggingId f03ebe89-4133-4a69-8409-c8f83423e8fb -MachineName 'S-1-5-21-733536048-680991148-2551668650-2896'

Lock-ProvVM  -AdminAddress 'xd71.home.stealthpuppy.com:80' -LoggingId f03ebe89-4133-4a69-8409-c8f83423e8fb -ProvisioningSchemeName 'Windows 7 x86' -Tag 'Brokered' -VMID @('e32f7150-6e3e-4954-a8fb-05427be03802')

New-BrokerMachine  -AdminAddress 'xd71.home.stealthpuppy.com:80' -CatalogUid 2027 -LoggingId f03ebe89-4133-4a69-8409-c8f83423e8fb -MachineName 'S-1-5-21-733536048-680991148-2551668650-2897'

Lock-ProvVM  -AdminAddress 'xd71.home.stealthpuppy.com:80' -LoggingId f03ebe89-4133-4a69-8409-c8f83423e8fb -ProvisioningSchemeName 'Windows 7 x86' -Tag 'Brokered' -VMID @('504a2875-de64-426f-8708-328dbb2045b5')

New-BrokerMachine  -AdminAddress 'xd71.home.stealthpuppy.com:80' -CatalogUid 2027 -LoggingId f03ebe89-4133-4a69-8409-c8f83423e8fb -MachineName 'S-1-5-21-733536048-680991148-2551668650-2898'

Stop-LogHighLevelOperation  -AdminAddress 'xd71.home.stealthpuppy.com:80' -EndTime 20/07/2014 8:47:15 PM -HighLevelOperationId 'f03ebe89-4133-4a69-8409-c8f83423e8fb' -IsSuccessful $True
# Script completed successfully

