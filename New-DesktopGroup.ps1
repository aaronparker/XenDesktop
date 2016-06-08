#---------------------------------------------------------------------------
# Author: Aaron Parker
# Desc:   Using PowerShell to create a XenDesktop 7.x desktop group 
# Date:   Aug 23, 2014
# Site:   http://stealthpuppy.com
#---------------------------------------------------------------------------
# 

# Set variables for the target infrastructure
# ----------
$adminAddress = 'xd71.home.stealthpuppy.com' #The XD Controller we're going to execute against
$xdControllers = 'xd71.home.stealthpuppy.com'

# Desktop Group properties
$desktopGroupName = "Windows 8 desktops"
$desktopGroupPublishedName = "Windows 8 desktops"
$desktopGroupDesc = "Windows 8 x86 with Office 2013, Pooled desktops"
$colorDepth = 'TwentyFourBit'
$deliveryType = 'DesktopsOnly'
$desktopKind = 'Shared'
$sessionSupport = "SingleSession" #Also: MultiSession
$functionalLevel = 'L7'
$timeZone = 'AUS Eastern Standard Time'
$offPeakBuffer = 10
$peakBuffer = 10
$assignedGroup = "HOME\Domain Users"

#Machine Catalog
$machineCatalogName = "Windows 8 x86"
# ----------

# Change to SilentlyContinue to avoid verbose output
$VerbosePreference = "Continue"

# Create the Desktop Group
# http://support.citrix.com/proddocs/topic/citrix-broker-admin-v2-xd75/new-brokerdesktopgroup-xd75.html
If (!(Get-BrokerDesktopGroup -Name $desktopGroupName -ErrorAction SilentlyContinue)) {
    Write-Verbose "Creating new Desktop Group: $desktopGroupName"
    $desktopGroup = New-BrokerDesktopGroup -ErrorAction SilentlyContinue -AdminAddress $adminAddress -Name $desktopGroupName -DesktopKind $desktopKind -DeliveryType $deliveryType -Description $desktopGroupPublishedName -PublishedName $desktopGroupPublishedName  -MinimumFunctionalLevel $functionalLevel -ColorDepth $colorDepth -SessionSupport $sessionSupport -ShutdownDesktopsAfterUse $True -TimeZone $timeZone -InMaintenanceMode $False -IsRemotePC $False -OffPeakBufferSizePercent $offPeakBuffer -PeakBufferSizePercent $peakBuffer -SecureIcaRequired $False -TurnOnAddedMachine $False -OffPeakDisconnectAction Suspend -OffPeakDisconnectTimeout 15 -Scope @() 
}

# At this point, we have a Desktop Group, but no users or desktops assigned to it, no power management etc.
# Open the properties of the new Desktop Group to see what's missing.

# If creation of the desktop group was successful, continue modifying its properties
If ($desktopGroup) {

    # Add a machine configuration to the new desktop group; This line adds an existing StoreFront server to the desktop group
    # Where does Input Object 1005 come from?
    # http://support.citrix.com/proddocs/topic/citrix-broker-admin-v2-xd75/add-brokermachineconfiguration-xd75.html
    # Write-Verbose "Adding machine configuration to the Desktop Group: $desktopGroupName"
    # Add-BrokerMachineConfiguration -AdminAddress $adminAddress -DesktopGroup $desktopGroup -InputObject @(1005)

    # Add machines to the new desktop group. Uses the number of machines available in the target machine catalog
    # http://support.citrix.com/proddocs/topic/citrix-broker-admin-v2-xd75/add-brokermachinestodesktopgroup-xd75.html
    Write-Verbose "Getting details for the Machine Catalog: $machineCatalogName"
    $machineCatalog = Get-BrokerCatalog -AdminAddress $adminAddress -Name $machineCatalogName
    Write-Verbose "Adding $machineCatalog.UnassignedCount machines to the Desktop Group: $desktopGroupName"
    $machinesCount = Add-BrokerMachinesToDesktopGroup -AdminAddress $adminAddress -Catalog $machineCatalog -Count $machineCatalog.UnassignedCount -DesktopGroup $desktopGroup

    # Create a new broker user/group object if it doesn't already exist
    # http://support.citrix.com/proddocs/topic/citrix-broker-admin-v2-xd75/new-brokeruser-xd75.html
    Write-Verbose "Creating user/group object in the broker for $assignedGroup"
    If (!(Get-BrokerUser -AdminAddress $adminAddress -Name $assignedGroup -ErrorAction SilentlyContinue)) {
        $brokerUsers = New-BrokerUser -AdminAddress $adminAddress -Name $assignedGroup
    } Else {
        $brokerUsers = Get-BrokerUser -AdminAddress $adminAddress -Name $assignedGroup
    }

    # Create an entitlement policy for the new desktop group. Assigned users to the desktop group
    # First check that we have an entitlement name available. Increment until we do.
    $Num = 1
    Do {
        # http://support.citrix.com/proddocs/topic/citrix-broker-admin-v2-xd75/test-brokerentitlementpolicyrulenameavailable-xd75.html
        $Test = Test-BrokerEntitlementPolicyRuleNameAvailable -AdminAddress $adminAddress -Name @($desktopGroupName + "_" + $Num.ToString()) -ErrorAction SilentlyContinue
        If ($Test.Available -eq $False) { $Num = $Num + 1 }
    } While ($Test.Available -eq $False)
    #http://support.citrix.com/proddocs/topic/citrix-broker-admin-v2-xd75/new-brokerentitlementpolicyrule-xd75.html
    Write-Verbose "Assigning $brokerUsers.Name to Desktop Catalog: $machineCatalogName"
    $EntPolicyRule = New-BrokerEntitlementPolicyRule -AdminAddress $adminAddress  -Name ($desktopGroupName + "_" + $Num.ToString()) -IncludedUsers $brokerUsers -DesktopGroupUid $desktopGroup.Uid -Enabled $True -IncludedUserFilterEnabled $False

    # Check whether access rules exist and then create rules for direct access and via Access Gateway
    # http://support.citrix.com/proddocs/topic/citrix-broker-admin-v2-xd75/new-brokeraccesspolicyrule-xd75.html
    $accessPolicyRule = $desktopGroupName + "_Direct"
    If (Test-BrokerAccessPolicyRuleNameAvailable -AdminAddress $adminAddress -Name @($accessPolicyRule) -ErrorAction SilentlyContinue) {
        Write-Verbose "Allowing direct access rule to the Desktop Catalog: $machineCatalogName"
        New-BrokerAccessPolicyRule -AdminAddress $adminAddress -Name $accessPolicyRule  -IncludedUsers @($brokerUsers.Name) -AllowedConnections 'NotViaAG' -AllowedProtocols @('HDX','RDP') -AllowRestart $True -DesktopGroupUid $desktopGroup.Uid -Enabled $True -IncludedSmartAccessFilterEnabled $True -IncludedUserFilterEnabled $True
    } Else {
        Write-Error "Failed to add direct access rule $accessPolicyRule. It already exists."
    }
    $accessPolicyRule = $desktopGroupName + "_AG"
    If (Test-BrokerAccessPolicyRuleNameAvailable -AdminAddress $adminAddress -Name @($accessPolicyRule) -ErrorAction SilentlyContinue) {
        Write-Verbose "Allowing access via Access Gateway rule to the Desktop Catalog: $machineCatalogName"
        New-BrokerAccessPolicyRule -AdminAddress $adminAddress -Name $accessPolicyRule -IncludedUsers @($brokerUsers.Name) -AllowedConnections 'ViaAG' -AllowedProtocols @('HDX','RDP') -AllowRestart $True -DesktopGroupUid $desktopGroup.Uid -Enabled $True -IncludedSmartAccessFilterEnabled $True -IncludedSmartAccessTags @() -IncludedUserFilterEnabled $True
    } Else {
        Write-Error "Failed to add Access Gateway rule $accessPolicyRule. It already exists."
    }

    # Create weekday and weekend access rules
    # http://support.citrix.com/proddocs/topic/citrix-broker-admin-v2-xd75/new-brokerpowertimescheme-xd75.html
    $powerTimeScheme = "Windows 8 Pooled Desktop_Weekdays"
    If (Test-BrokerPowerTimeSchemeNameAvailable -AdminAddress $adminAddress -Name @($powerTimeScheme) -ErrorAction SilentlyContinue) {
        Write-Verbose "Adding new power scheme $powerTimeScheme"
        New-BrokerPowerTimeScheme -AdminAddress $adminAddress -DisplayName 'Weekdays' -Name $powerTimeScheme -DaysOfWeek 'Weekdays' -DesktopGroupUid $desktopGroup.Uid -PeakHours @($False,$False,$False,$False,$False,$False,$False,$True,$True,$True,$True,$True,$True,$True,$True,$True,$True,$True,$True,$False,$False,$False,$False,$False) -PoolSize @(0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0)
    } Else {
        Write-Error "Failed to add power scheme rule $powerTimeScheme. It already exists."
    }
    $powerTimeScheme = "Windows 8 Pooled Desktop_Weekend"
    If (Test-BrokerPowerTimeSchemeNameAvailable -AdminAddress $adminAddress -Name @($powerTimeScheme) -ErrorAction SilentlyContinue) {
        Write-Verbose "Adding new power scheme $powerTimeScheme"
        New-BrokerPowerTimeScheme -AdminAddress $adminAddress -DisplayName 'Weekend' -Name $powerTimeScheme -DaysOfWeek 'Weekend' -DesktopGroupUid $desktopGroup.Uid -PeakHours @($False,$False,$False,$False,$False,$False,$False,$True,$True,$True,$True,$True,$True,$True,$True,$True,$True,$True,$True,$False,$False,$False,$False,$False) -PoolSize @(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
    } Else {
        Write-Error "Failed to add power scheme rule $powerTimeScheme. It already exists."
    }

} #End If DesktopGroup
