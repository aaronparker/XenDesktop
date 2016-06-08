# Set up some useful variables including the hostingUnit and connections and the number of Virtual machines to create and add to the catalog
# You will need to update the HostingUnit string and the number of Vms to create appropriately.

Add-PSSnapin *Citrix*

$MachineObjectOU = "OU=Desktops,OU=Desktop Virtualization,DC=UCS-POC,DC=CO,DC=UK"
$Domain = $env:USERDNSDOMAIN.ToLower()
$adminAddress = "ctx-xd56-ddc1.ucs-poc.co.uk"

$DesktopGroupName = "Windows 7 x86"
$DesktopAccNameScheme = "W7-XD-###"
$TargetVM_Name = "Win7-x86-VDA-Template"

$PublishedDesktopName = "My Desktop"
$TimeZone = "GMT Standard Time"
$BrokerUsers =  "UCS-POC\Domain Users"

$numVMsToCreate = 5
$numVMsToAdd = 5
$hostingUnit = Get-Item -AdminAddress $adminAddress -Path @("XDHyp:\HostingUnits\UCS-vCenter-SSD")
$hostConnection = Get-Item -AdminAddress $adminAddress -Path @("XDHyp:\Connections\UCS-vCenter")
$brokerHypConnection = Get-BrokerHypervisorConnection -AdminAddress $adminAddress -HypHypervisorConnectionUid $hostConnection.HypervisorConnectionUid
$brokerServiceGroup = Get-ConfigServiceGroup  -AdminAddress $adminAddress -ServiceType 'Broker' -MaxRecordCount 2147483647

# Create the broker catalog and the AC Identity account pool
$catalog = New-BrokerCatalog -AdminAddress $adminAddress -AllocationType 'Random' -CatalogKind 'SingleImage' -Name $DesktopGroupName -PvsForVM @()
$adPool = New-AcctIdentityPool -AdminAddress $adminAddress -IdentityPoolName $DesktopGroupName -NamingScheme $DesktopAccNameScheme -NamingSchemeType 'Numeric' -OU $MachineObjectOU -Domain $Domain -AllowUnicode

###################################################################
#### Add the required desktop Studio metadata to the Service Group.
$uidLength = $catalog.uid.ToString().Length
If ($uidLength -lt 3){
    $ServiceGroupMetadataProperty = 'Citrix_DesktopStudio_BrokerCatalogIdentityPoolReferencePrefix_'+$catalog.uid
} Else {
    $ServiceGroupMetadataProperty = 'Citrix_DesktopStudio_CatalogIdentityPoolReference_'+$catalog.uid
}
Add-ConfigServiceGroupMetadata -AdminAddress $adminAddress -ServiceGroupUid $brokerServiceGroup.ServiceGroupUid -Property $serviceGroupMetadataProperty -Value $adPool.IdentityPoolUid

###################################################################
#create the ProvisioningScheme and wait for it to complete (reporting progress)
$provSchemeTaskID = New-ProvScheme -AdminAddress $adminAddress -ProvisioningSchemeName $DesktopGroupName -HostingUnitUID $hostingUnit.HostingUnitUID -IdentityPoolUID $adpool.IdentityPoolUid -VMCpuCount 1 -VMMemoryMB 2024 -CleanOnBoot -MasterImageVM "XDHyp:\HostingUnits\UCS-vCenter-SSD\$TargetVM_Name.vm\Ready.snapshot" -RunAsynchronously
$provTask = Get-ProvTask -AdminAddress $adminAddress -TaskID $provSchemeTaskID
$taskProgress = 0
While ($provTask.Active -eq $true) {
    If ($taskProgress -ne $provTask.TaskProgress) {
        $taskProgress = $provTask.TaskProgress
        Write-Progress -Activity "ProvScheme creation in progress" -Status $provTask.TaskState -PercentComplete $provTask.TaskProgress
        # write-host "New ProvScheme Progress is $($provTask.TaskProgress)%"
    }
    Start-Sleep 5
    $ProvTask = Get-ProvTask -TaskID $provSchemeTaskID -AdminAddress $adminAddress
}
Write-Host "New ProvScheme Creation Finished"
$provScheme = Get-ProvScheme -ProvisioningSchemeUID $provTask.ProvisioningSchemeUid
Add-ProvSchemeControllerAddress -ProvisioningSchemeUID $provScheme.ProvisioningSchemeUID -ControllerAddress @($adminAddress)

###################################################################
# add the PVSForVM information to the Catalog
$pvsForVm ="$($provScheme.ProvisioningSchemeUID):$($hostingUnit.HostingUnitUID)"
Set-BrokerCatalog -AdminAddress $adminAddress -InputObject $catalog -PvsForVM @($pvsForVm )

###################################################################
# create the AD accounts required and then create the Virtual machines (reporting progress)
$accts = New-AcctADAccount -AdminAddress $adminAddress -IdentityPoolUid $adPool.IdentityPoolUid -Count $numVMsToCreate
Start-Sleep 10
$provVMTaskID = New-ProvVM -AdminAddress $adminAddress -ProvisioningSchemeUID $provScheme.ProvisioningSchemeUID -ADAccountName $accts.SuccessfulAccounts -RunAsynchronously
Start-Sleep 10

# wait for the VMS tp finish Provisioning
$provTask = get-provTask -TaskID $provVMTaskID
$CreatedVirtualMachines = @()
While ($provTask.Active -eq $true){
    If ($CreatedVirtualMachines.Count -ne $provTask.CreatedVirtualMachines.Count) {
        $CreatedVirtualMachines = $provTask.CreatedVirtualMachines
        Write-Host "Created $($provTask.CreatedVirtualMachines.Count) Machines"
    }
    Start-Sleep 5
    $ProvTask = get-provTask -TaskID $provVMTaskID
}
Write-Host "VM Creation Finished"

# Lock the VMs and add them to the broker Catalog
$provisionedVMs = get-ProvVM -AdminAddress $adminAddress -ProvisioningSchemeUID $provScheme.ProvisioningSchemeUID
$provisionedVMs | Lock-ProvVM -AdminAddress $adminAddress -ProvisioningSchemeUID $provScheme.ProvisioningSchemeUID -Tag 'Brokered'
$provisionedVMs | ForEach-Object { New-BrokerMachine -AdminAddress $adminAddress -CatalogUid $catalog.UID -HostedMachineId $_.VMId -HypervisorConnectionUid $brokerHypConnection.UID -MachineName $_.ADAccountSid }

# Create new desktop assignment
$desktopGroup = New-BrokerDesktopGroup -AdminAddress $adminAddress -DesktopKind 'Shared' -Name $DesktopGroupName -OffPeakBufferSizePercent 10 -PeakBufferSizePercent 10 -PublishedName $PublishedDesktopName -ShutdownDesktopsAfterUse $True -TimeZone $TimeZone
# $desktopGroup = Get-BrokerDesktopGroup -PublishedName $PublishedDesktopName
Add-BrokerMachinesToDesktopGroup -AdminAddress $adminAddress -Catalog $DesktopGroupName -DesktopGroup $desktopGroup -Count $numVMsToAdd
New-BrokerUser -AdminAddress $adminAddress -Name $BrokerUsers
New-BrokerEntitlementPolicyRule -AdminAddress $adminAddress -DesktopGroupUid $desktopGroup.Uid -Enabled $True -IncludedUsers @($BrokerUsers) -Name "$($DesktopGroupName)_1"
New-BrokerAccessPolicyRule -AdminAddress $adminAddress -AllowedConnections 'NotViaAG' -AllowedProtocols @('RDP','HDX') -AllowedUsers 'AnyAuthenticated' -AllowRestart $True -Enabled $True -IncludedDesktopGroupFilterEnabled $True -IncludedDesktopGroups @($DesktopGroupName) -IncludedSmartAccessFilterEnabled $True -IncludedUserFilterEnabled $True -Name "$($DesktopGroupName)_Direct"
New-BrokerAccessPolicyRule -AdminAddress $adminAddress -AllowedConnections 'ViaAG' -AllowedProtocols @('RDP','HDX') -AllowedUsers 'AnyAuthenticated' -AllowRestart $True -Enabled $True -IncludedDesktopGroupFilterEnabled $True -IncludedDesktopGroups @($DesktopGroupName) -IncludedSmartAccessFilterEnabled $True -IncludedSmartAccessTags @() -IncludedUserFilterEnabled $True -Name "$($DesktopGroupName)_AG"
New-BrokerPowerTimeScheme -AdminAddress $adminAddress -DaysOfWeek 'Weekdays' -DesktopGroupUid $desktopGroup.Uid -DisplayName 'Weekdays' -Name "$($DesktopGroupName)_Weekdays" -PeakHours @($False,$False,$False,$False,$False,$False,$False,$True,$True,$True,$True,$True,$True,$True,$True,$True,$True,$True,$True,$False,$False,$False,$False,$False) -PoolSize @(0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0)
New-BrokerPowerTimeScheme -AdminAddress $adminAddress -DaysOfWeek 'Weekend' -DesktopGroupUid $desktopGroup.Uid -DisplayName 'Weekend' -Name "$($DesktopGroupName)_Weekend" -PeakHours @($False,$False,$False,$False,$False,$False,$False,$True,$True,$True,$True,$True,$True,$True,$True,$True,$True,$True,$True,$False,$False,$False,$False,$False) -PoolSize @(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
