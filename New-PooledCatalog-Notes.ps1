$adminAddress = 'xd71.home.stealthpuppy.com' 
$storageResource = "HV1-LocalStorage"
$hostResource = "Lab SCVMM"
$machineCatalogName = "Windows 7 x86 v1"

$hostingUnit = Get-ChildItem -AdminAddress $adminAddress "XDHyp:\HostingUnits" | Where-Object { $_.PSChildName -like $storageResource } | Select-Object PSChildName, PsPath
$hostConnection = Get-ChildItem -AdminAddress $adminAddress "XDHyp:\Connections" | Where-Object { $_.PSChildName -like $hostResource }
$brokerHypConnection = Get-BrokerHypervisorConnection -AdminAddress $adminAddress -HypHypervisorConnectionUid $hostConnection.HypervisorConnectionUid
$brokerServiceGroup = Get-ConfigServiceGroup  -AdminAddress $adminAddress -ServiceType 'Broker' -MaxRecordCount 2147483647

New-BrokerCatalog -AdminAddress $adminAddress  -PersistUserChanges Discard -ProvisioningType MCS -SessionSupport SingleSession -AllocationType Random -Name $machineCatalogName -Description 'Windows 7 x86 SP1 with Office 2010' -IsRemotePC $False
$BrokerUID = Get-BrokerCatalog | Where-Object Name -eq $machineCatalogName | Select-Object Uid
New-AcctIdentityPool -AdminAddress $adminAddress  -Domain 'home.stealthpuppy.com' -IdentityPoolName $machineCatalogName -NamingScheme 'W7-MCS-###' -NamingSchemeType Numeric -OU 'OU=MCS Pooled,OU=Workstations,DC=home,DC=stealthpuppy,DC=com'
$guid = [guid]::NewGuid()
Set-BrokerCatalogMetadata -AdminAddress $adminAddress -CatalogId $BrokerUID.Uid -Name 'Citrix_DesktopStudio_IdentityPoolUid' -Value $guid
If (Test-ProvSchemeNameAvailable -AdminAddress $adminAddress -ProvisioningSchemeName @($machineCatalogName))
  {
  $VM = Get-ChildItem | Where-Object { $_.ObjectType -eq "VM" -and $_.PSChildName -like "*WIN71*" }
  $VMDetails = Get-ChildItem $VM.FullPath
  New-ProvScheme -AdminAddress $adminAddress -CleanOnBoot $True -HostingUnitName $storageResource -IdentityPoolName $machineCatalogName -MasterImageVM $VMDetails.FullPath -ProvisioningSchemeName $machineCatalogName -RunAsynchronously -VMCpuCount 2 -VMMemoryMB 768
  # $ProvTask = Get-ProvTask  -AdminAddress $adminAddress | Where-Object ProvisioningSchemeName -eq $machineCatalogName -and MasterImage -like "*MasterImage v1*"
  }