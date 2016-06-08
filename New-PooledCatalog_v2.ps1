#---------------------------------------------------------------------------
# Author: Aaron Parker
# Desc:   Using PowerShell to create a XenDesktop 7.x machine catalog 
# Date:   Aug 19, 2014
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

# Machine catalog properties
$machineCatalogName = "Windows 8 x86"
$machineCatalogDesc = "Windows 8.1 x86 SP1 with Office 2013"
$domain = "home.stealthpuppy.com"
$orgUnit = "OU=MCS Pooled,OU=Workstations,DC=home,DC=stealthpuppy,DC=com"
$namingScheme = "W8-MCS-###" #AD machine account naming conventions
$namingSchemeType = "Numeric" #Also: Alphabetic
$allocType = "Random" #Also: Static
$persistChanges = "Discard" #Also: OnLocal, OnPvD
$provType = "MCS" #Also: Manual, PVS
$sessionSupport = "SingleSession" #Also: MultiSession
$masterImage ="WIN81*"
$vCPUs = 2
$VRAM = 2048
# ----------

# Change to SilentlyContinue to avoid verbose output
$VerbosePreference = "Continue"

# Load the Citrix PowerShell modules
Write-Verbose "Loading Citrix XenDesktop modules."
Add-PSSnapin Citrix*

# Get information from the hosting environment via the XD Controller
# Get the storage resource
Write-Verbose "Gathering storage and hypervisor connections from the XenDesktop infrastructure."
$hostingUnit = Get-ChildItem -AdminAddress $adminAddress "XDHyp:\HostingUnits" | Where-Object { $_.PSChildName -like $storageResource } | Select-Object PSChildName, PsPath
# Get the hypervisor management resources
$hostConnection = Get-ChildItem -AdminAddress $adminAddress "XDHyp:\Connections" | Where-Object { $_.PSChildName -like $hostResource }
$brokerHypConnection = Get-BrokerHypervisorConnection -AdminAddress $adminAddress -HypHypervisorConnectionUid $hostConnection.HypervisorConnectionUid
# $brokerServiceGroup = Get-ConfigServiceGroup -AdminAddress $adminAddress -ServiceType 'Broker' -MaxRecordCount 2147483647

# Create a Machine Catalog. In this case a catalog with randomly assigned desktops
Write-Verbose "Creating machine catalog. Name: $machineCatalogName; Description: $machineCatalogDesc; Allocation: $allocType"
$brokerCatalog = New-BrokerCatalog -AdminAddress $adminAddress -AllocationType $allocType -Description $machineCatalogDesc -Name $machineCatalogName -PersistUserChanges $persistChanges -ProvisioningType $provType -SessionSupport $sessionSupport
# The identity pool is used to store AD machine accounts
Write-Verbose "Creating a new identity pool for machine accounts."
$identPool = New-AcctIdentityPool -AdminAddress $adminAddress -Domain $domain -IdentityPoolName $machineCatalogName -NamingScheme $namingScheme -NamingSchemeType $namingSchemeType -OU $orgUnit

# Creates/Updates metadata key-value pairs for the catalog (no idea why).
Write-Verbose "Retrieving the newly created machine catalog."
$catalogUid = Get-BrokerCatalog | Where-Object { $_.Name -eq $machineCatalogName } | Select-Object Uid
$guid = [guid]::NewGuid()
Write-Verbose "Updating metadata key-value pairs for the catalog."
Set-BrokerCatalogMetadata -AdminAddress $adminAddress -CatalogId $catalogUid.Uid -Name 'Citrix_DesktopStudio_IdentityPoolUid' -Value $guid

# Check to see whether a provisioning scheme is already available
Write-Verbose "Checking whether the provisioning scheme name is unused."
If (Test-ProvSchemeNameAvailable -AdminAddress $adminAddress -ProvisioningSchemeName @($machineCatalogName))
{
  Write-Verbose "Success."

  # Get the master VM image from the same storage resource we're going to deploy to. Could pull this from another storage resource available to the host
  Write-Verbose "Getting the master image details for the new catalog: $masterImage"
  $VM = Get-ChildItem -AdminAddress $adminAddress "XDHyp:\HostingUnits\$storageResource" | Where-Object { $_.ObjectType -eq "VM" -and $_.PSChildName -like $masterImage }
  # Get the snapshot details. This code will assume a single snapshot exists - could add additional checking to grab last snapshot or check for no snapshots.
  $VMDetails = Get-ChildItem -AdminAddress $adminAddress $VM.FullPath
  
  # Create a new provisioning scheme - the configuration of VMs to deploy. This will copy the master image to the target datastore.
  Write-Verbose "Creating new provisioning scheme using $VMDetails.FullPath"
  # Provision VMs based on the selected snapshot.
  $provTaskId = New-ProvScheme -AdminAddress $adminAddress -ProvisioningSchemeName $machineCatalogName -HostingUnitName $storageResource -MasterImageVM $VMDetails.FullPath -CleanOnBoot -IdentityPoolName $identPool.IdentityPoolName -VMCpuCount $vCPUs -VMMemoryMB $vRAM -RunAsynchronously
  $provTask = Get-ProvTask -AdminAddress $adminAddress -TaskId $provTaskId

  # Track the progress of copying the master image
  Write-Verbose "Tracking progress of provisioning scheme creation task."
  $totalPercent = 0
  While ( $provTask.Active -eq $True ) {
    Try { $totalPercent = If ( $provTask.TaskProgress ) { $provTask.TaskProgress } Else {0} } Catch { }

    Write-Progress -Activity "Creating Provisioning Scheme (copying and composing master image):" -Status "$totalPercent% Complete:" -percentcomplete $totalPercent
    Sleep 15
    $provTask = Get-ProvTask -AdminAddress $adminAddress -TaskID $provTaskId
  }

  # If provisioning task fails, there's no point in continuing further.
  If ( $provTask.WorkflowStatus -eq "Completed" )
  { 
      # Apply the provisioning scheme to the machine catalog
      Write-Verbose "Binding provisioning scheme to the new machine catalog"
      $provScheme = Get-ProvScheme | Where-Object { $_.ProvisioningSchemeName -eq $machineCatalogName }
      Set-BrokerCatalog -AdminAddress $adminAddress -Name $provScheme.ProvisioningSchemeName -ProvisioningSchemeId $provScheme.ProvisioningSchemeUid

      # Associate a specific set of controllers to the provisioning scheme. This steps appears to be optional.
      Write-Verbose "Associating controllers $xdControllers to the provisioning scheme."
      Add-ProvSchemeControllerAddress -AdminAddress $adminAddress -ControllerAddress @($xdControllers) -ProvisioningSchemeName $provScheme.ProvisioningSchemeName

      # Provisiong the actual machines and map them to AD accounts, track the progress while this is happening
      Write-Verbose "Creating the machine accounts in AD."
      $adAccounts = New-AcctADAccount -AdminAddress $adminAddress -Count 5 -IdentityPoolUid $identPool.IdentityPoolUid
      Write-Verbose "Creating the virtual machines."
      $provTaskId = New-ProvVM -AdminAddress $adminAddress -ADAccountName @($adAccounts.SuccessfulAccounts) -ProvisioningSchemeName $provScheme.ProvisioningSchemeName -RunAsynchronously
      $provTask = Get-ProvTask -AdminAddress $adminAddress -TaskId $provTaskId

      Write-Verbose "Tracking progress of the machine creation task."
      $totalPercent = 0
      While ( $provTask.Active -eq $True ) {
        Try { $totalPercent = If ( $provTask.TaskProgress ) { $provTask.TaskProgress } Else {0} } Catch { }

        Write-Progress -Activity "Creating Virtual Machines:" -Status "$totalPercent% Complete:" -percentcomplete $totalPercent
        Sleep 15
        $ProvTask = Get-ProvTask -AdminAddress $adminAddress -TaskID $provTaskId
      }

      # Assign the newly created virtual machines to the machine catalog
      $provVMs = Get-ProvVM -AdminAddress $adminAddress -ProvisioningSchemeUid $provScheme.ProvisioningSchemeUid
      Write-Verbose "Assigning the virtual machines to the new machine catalog."
      ForEach ( $provVM in $provVMs ) {
        Write-Verbose "Locking VM $provVM.ADAccountName"
        Lock-ProvVM -AdminAddress $adminAddress -ProvisioningSchemeName $provScheme.ProvisioningSchemeName -Tag 'Brokered' -VMID @($provVM.VMId)
        Write-Verbose "Adding VM $provVM.ADAccountName"
        New-BrokerMachine -AdminAddress $adminAddress -CatalogUid $catalogUid.Uid -MachineName $provVM.ADAccountName
      }
      Write-Verbose "Machine catalog creation complete."

   } Else {
    # If provisioning task fails, provide error
    # Check that the hypervisor management and storage resources do no have errors. Run 'Test Connection', 'Test Resources' in Citrix Studio
    Write-Error "Provisioning task failed with error: [$provTask.TaskState] $provTask.TerminatingError"
   }
}
