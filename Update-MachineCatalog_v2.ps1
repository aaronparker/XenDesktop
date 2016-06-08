#---------------------------------------------------------------------------
# Author: Aaron Parker
# Desc:   Using PowerShell to update a XenDesktop 7.x machine catalog 
# Date:   Oct 21, 2014
# Site:   http://stealthpuppy.com
#---------------------------------------------------------------------------

# Set variables for the target infrastructure
# ----------
$adminAddress = 'xd71.home.stealthpuppy.com' #The XD Controller we're going to execute against
$xdControllers = 'xd71.home.stealthpuppy.com'

# Hypervisor and storage resources
# These need to be configured in Studio prior to running this script
# This script is hypervisor and management agnostic - just point to the right infrastructure
$storageResource = "HV1-LocalStorage" #Storage
$hostResource = "Lab SCVMM" #Hypervisor management

# Master image properties
$machineCatalogName = "Windows 8"
$masterImage ="Windows 8*"
$snapshot = "VDA 7.6.snapshot"

$messageDetail = "Your computer has been updated and will be automatically restarted in 15 minutes."
$messageTitle = "Help desk message"
# ----------

# Load the Citrix PowerShell modules
Write-Verbose "Loading Citrix XenDesktop modules."
Add-PSSnapin Citrix*

# Get information from the hosting environment via the XD Controller
# Get the storage resource
Write-Verbose "Gathering storage and hypervisor connections from the XenDesktop infrastructure."
$hostingUnit = Get-ChildItem -AdminAddress $adminAddress "XDHyp:\HostingUnits" | Where-Object { $_.PSChildName -like $storageResource } | Select-Object PSChildName, PsPath
# Get the hypervisor management resources
$hostConnection = Get-ChildItem -AdminAddress $adminAddress "XDHyp:\Connections" | Where-Object { $_.PSChildName -like $hostResource }

# http://support.citrix.com/proddocs/topic/citrix-broker-admin-v2-xd75/get-brokerhypervisorconnection-xd75.html
$brokerHypConnection = Get-BrokerHypervisorConnection -AdminAddress $adminAddress -HypHypervisorConnectionUid $hostConnection.HypervisorConnectionUid

# http://support.citrix.com/proddocs/topic/citrix-machinecreation-admin-v2-xd75/set-provschememetadata-xd75.html
$ProvScheme = Set-ProvSchemeMetadata -AdminAddress $adminAddress -Name 'ImageManagementPrep_DoImagePreparation' -ProvisioningSchemeName $machineCatalogName -Value 'True'

# Get the master VM image from the same storage resource we're going to deploy to. Could pull this from another storage resource available to the host
Write-Verbose "Getting the master image details for the new catalog: $masterImage"
$VM = Get-ChildItem -AdminAddress $adminAddress "XDHyp:\HostingUnits\$storageResource" | Where-Object { $_.ObjectType -eq "VM" -and $_.PSChildName -like $masterImage }
# Get the snapshot details. This code will assume a single snapshot exists - could add additional checking to grab last snapshot or check for no snapshots.
$VMSnapshots = Get-ChildItem -AdminAddress $adminAddress $VM.FullPath -Recurse -Include *.snapshot
$TargetSnapshot = $VMSnapshots | Where-Object { $_.FullName -eq $snapshot }

# http://support.citrix.com/proddocs/topic/citrix-machinecreation-admin-v2-xd7/publish-provmastervmimage-xd7.html
$PubTask = Publish-ProvMasterVmImage -AdminAddress $adminAddress -MasterImageVM $TargetSnapshot.FullPath -ProvisioningSchemeName $machineCatalogName -RunAsynchronously

      Write-Verbose "Tracking progress of the machine creation task."
      $totalPercent = 0
      While ( $provTask.Active -eq $True ) {
        Try { $totalPercent = If ( $provTask.TaskProgress ) { $provTask.TaskProgress } Else {0} } Catch { }

        Write-Progress -Activity "Creating Virtual Machines:" -Status "$totalPercent% Complete:" -percentcomplete $totalPercent
        Sleep 15
        $ProvTask = Get-ProvTask -AdminAddress $adminAddress -TaskID $provTaskId
      }

# http://support.citrix.com/proddocs/topic/citrix-broker-admin-v2-xd7/start-brokerrebootcycle-xd7.html
Start-BrokerRebootCycle -AdminAddress $adminAddress -InputObject @($machineCatalogName) -RebootDuration 60 -WarningDuration 15 -WarningMessage $messageDetail -WarningTitle $messageTitle