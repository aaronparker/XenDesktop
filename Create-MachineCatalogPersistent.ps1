# Create desktop catalog and desktop group for persistent machines
Add-PSSnapin *Citrix*

$MachineObjectOU = "OU=Desktops,OU=Desktop Virtualization,DC=UCS-POC,DC=CO,DC=UK"
$Domain = $env:USERDNSDOMAIN.ToLower()
$adminAddress = "ctx-xd56-ddc1.ucs-poc.co.uk"
$VIServer = "k-poc-vcenter5.ucs-poc.co.uk"

$DesktopCatalogName = "Windows 8 x86 Persistent"
$DesktopGroupName = "Windows 8 Persistent"
$PublishedDesktopName = "Windows 8 Desktop"
$TimeZone = "GMT Standard Time"

$TargetVMs = @{}
$TargetVMs["Win8-Persistent1"] = @("UCS-POC\W8PERS1", "UCS-POC\aaron")
$TargetVMs["Win8-Persistent2"] = @("UCS-POC\W8PERS2", "UCS-POC\aaron")


# Connect to VMware vCenter
Write-Host "Importing and configuring PowerCLI." -ForegroundColor Green
Add-PSSnapin "vmware.VimAutomation.core" -ErrorAction SilentlyContinue
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Scope Session -Confirm:$False
Write-Host "Getting credentials..." -ForegroundColor Green
$MyCredentials = Get-Credential -Credential "$Domain\$env:USERNAME"
Write-Host "Connecting to vSphere..." -ForegroundColor Green
Connect-VIServer -Server $VIServer -Credential $MyCredentials -Verbose

# Get XenDesktop hypervisor connection/host details
$hostingUnit = Get-Item -AdminAddress $adminAddress -Path @("XDHyp:\HostingUnits\UCS-vCenter-SSD")
$hostConnection = Get-Item -AdminAddress $adminAddress -Path @("XDHyp:\Connections\UCS-vCenter")
$brokerHypConnection = Get-BrokerHypervisorConnection -AdminAddress $adminAddress -HypHypervisorConnectionUid $hostConnection.HypervisorConnectionUid
$brokerServiceGroup = Get-ConfigServiceGroup  -AdminAddress $adminAddress -ServiceType 'Broker' -MaxRecordCount 2147483647

# Create a new Desktop Catalog of type Existing
$brokerCatalog = New-BrokerCatalog -AdminAddress $adminAddress -AllocationType 'Permanent' -CatalogKind 'PowerManaged' -Name $DesktopCatalogName
# $brokerCatalog = Get-BrokerCatalog -AdminAddress $adminAddress -Name $DesktopCatalogName

# Add machines to the catalog contained in the $TargetVMs hashtable
$machineIDs = @()
ForEach ( $key in $TargetVMs.Keys ) { 
    # Get target VM details from vSphere
    $targetVM = Get-ChildItem -Recurse -Path $hostConnection.PSPath | Where-Object { $_.Name -eq $key }

    # Create the machine in the target XD desktop catalog
    New-BrokerMachine -AdminAddress $adminAddress -CatalogUid $brokerCatalog.Uid -HostedMachineId $targetVM.Id -HypervisorConnectionUid $brokerHypConnection.Uid -MachineName $TargetVMs[$key][0]
    $brokerMachine = Get-BrokerMachine -AdminAddress $adminAddress -MachineName $TargetVMs[$key][0]
    Add-BrokerUser -AdminAddress $adminAddress -Name $TargetVMs[$key][1] -Machine $brokerMachine.Uid
    $machineIDs += $brokerMachine.Uid
}


# Create Desktop Group
$desktopGroup = New-BrokerDesktopGroup -AdminAddress $adminAddress -DesktopKind 'Private' -Name $DesktopGroupName -OffPeakBufferSizePercent 10 -PeakBufferSizePercent 10 -PublishedName $PublishedDesktopName -ShutdownDesktopsAfterUse $False -TimeZone $TimeZone
Add-BrokerMachine -AdminAddress $adminAddress -InputObject @($machineIDs) -DesktopGroup $DesktopGroupName
New-BrokerAccessPolicyRule -AdminAddress $adminAddress -AllowedConnections 'NotViaAG' -AllowedProtocols @('RDP','HDX') -AllowedUsers 'AnyAuthenticated' -AllowRestart $True -Enabled $True -IncludedDesktopGroupFilterEnabled $True -IncludedDesktopGroups @($DesktopGroupName) -IncludedSmartAccessFilterEnabled $True -IncludedUserFilterEnabled $True -Name "$($DesktopGroupName)_Direct"
New-BrokerAccessPolicyRule -AdminAddress $adminAddress -AllowedConnections 'ViaAG' -AllowedProtocols @('RDP','HDX') -AllowedUsers 'AnyAuthenticated' -AllowRestart $True -Enabled $True -IncludedDesktopGroupFilterEnabled $True -IncludedDesktopGroups @($DesktopGroupName) -IncludedSmartAccessFilterEnabled $True -IncludedSmartAccessTags @() -IncludedUserFilterEnabled $True -Name "$($DesktopGroupName)_AG"
New-BrokerPowerTimeScheme -AdminAddress $adminAddress -DaysOfWeek 'Weekdays' -DesktopGroupUid $desktopGroup.Uid -DisplayName 'Weekdays' -Name "$($DesktopGroupName)_Weekdays" -PeakHours @($False,$False,$False,$False,$False,$False,$False,$True,$True,$True,$True,$True,$True,$True,$True,$True,$True,$True,$True,$False,$False,$False,$False,$False) -PoolSize @(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
New-BrokerPowerTimeScheme -AdminAddress $adminAddress -DaysOfWeek 'Weekend' -DesktopGroupUid $desktopGroup.Uid -DisplayName 'Weekend' -Name "$($DesktopGroupName)_Weekend" -PeakHours @($False,$False,$False,$False,$False,$False,$False,$True,$True,$True,$True,$True,$True,$True,$True,$True,$True,$True,$True,$False,$False,$False,$False,$False) -PoolSize @(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
