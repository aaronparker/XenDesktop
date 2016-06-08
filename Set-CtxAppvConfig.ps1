#Add-PSSnapin Citrix* -ErrorAction SilentlyContinue
#http://discussions.citrix.com/topic/351858-xendesktop-75-add-a-second-app-v-publishing-server/

# Get-BrokerMachineConfiguration -AdminAddress $AdminAddress -Name AppV* | Remove-BrokerMachineConfiguration

    #$AdminAddress = 'xd71.home.stealthpuppy.com'
    #$AppvMgmtSvr = 'http://appv1.home.stealthpuppy.com:8080'
    #$AppvPubSvr = 'http://appv1.home.stealthpuppy.com:80'


Function Set-CtxAppvConfig {
    <#
        .SYNOPSIS
            Sets new App-V publishing information in a XenDesktop site.
 
        .DESCRIPTION
            This function can be used to set or add App-V publishing information in a XenDesktop or XenApp 7.x site.
 
        .PARAMETER AdminAddress
            Specifies a remote XenDesktop controller to apply the configuration against. If omitted, the local host will be used instead.
 
        .PARAMETER AppvMgmtSvr
            Specifies a remote XenDesktop controller to apply the configuration against. If omitted, the local host will be used instead.
 
        .PARAMETER AppvPubSvr
            Specifies a remote XenDesktop controller to apply the configuration against. If omitted, the local host will be used instead.
 
        .PARAMETER Description
            Specifies a remote XenDesktop controller to apply the configuration against. If omitted, the local host will be used instead.
 
        .EXAMPLE
            Set-CtxAppvConfig -AdminAddress 'xd71.home.stealthpuppy.com' -AppvMgmtSvr 'http://appv1:8080' -AppvPubSvr 'http://appv1:80' -Description 'Created by PowerShell'
 
        .NOTES
 
        .LINK
            http://stealthpuppy.com/appv-publishing-xendesktop-powershell
 
    #>
    param(
        [Parameter(Mandatory=$false, Position=0,HelpMessage="XenDesktop Controller address.")]
        [string]$AdminAddress = 'localhost',

        [Parameter(Mandatory=$true, Position=1,HelpMessage="Microsoft App-V Management Server address.")]
        [string]$AppvMgmtSvr = $(throw = "Please specify an App-V Management Server address."),

        [Parameter(Mandatory=$true, Position=2,HelpMessage="Microsoft App-V Publishing Server address.")]
        [string]$AppvPubSvr = $(throw = "Please specify an App-V Publishing Server address."),

        [Parameter(Mandatory=$true, Position=2,HelpMessage="App-V publishing configuration description.")]
        [string]$Description = $(throw = "Specify a description to apply to the App-V publishing information. Specify 'Created by Studio' to set the App-V publishing inforamtion viewed in Citrix Studio.")
    )

    Function Add-AppvConfig {
        # Add the AppV Server settings to the new specified settings
        Write-Verbose "Setting App-V Management Server to specified URI."
        #http://support.citrix.com/proddocs/topic/citrix-appv-admin-v1-xd71/new-ctxappvserver-xd71.html
        $newAppvConfig = New-CtxAppVServer -ManagementServer $AppvMgmtSvr -PublishingServer $AppvPubSvr

        # Applying configuration to the site
        Write-Verbose "Saving configuration to the site."
        #http://support.citrix.com/proddocs/topic/citrix-broker-admin-v2-xd75/new-brokermachineconfiguration-xd75.html
        $machineConfig = New-BrokerMachineConfiguration -AdminAddress $AdminAddress -ConfigurationSlotUid 3 -LeafName 1 -Description "Created by Studio" -Policy $newAppvConfig -Verbose
    }

    # Obtain FQDN from Management server URL
    $urlGroups = [regex]::Match($AppvMgmtSvr, '^(?<protocol>(http|https))://(?<fqdn>([^:]*))((:(?<port>\d+))?)').Groups

    # Test specified Management Server.
    Write-Verbose "Testing Management Server."
    If (Test-CtxAppVServer -AppVManagementServer $urlGroups["fqdn"].Value -ErrorAction SilentlyContinue -ErrorVariable $manError) {
        Write-Verbose "Management Server tested OK."

        # Test specified Publishing Server
        Write-Verbose "Testing Publishing Server."
        If (Test-CtxAppVServer -AppVPublishingServer $AppvPubSvr -ErrorAction SilentlyContinue -ErrorVariable $pubError) {
            Write-Verbose "Publishing Server tested OK."
        
            # Get any existing AppV configuration from the broker
            #http://support.citrix.com/proddocs/topic/citrix-broker-admin-v2-xd71/get-brokermachineconfiguration-xd71.html
            If ($Config) { Remove-Variable Config }
            $Config = Get-BrokerMachineConfiguration -AdminAddress $AdminAddress -Name AppV* -ErrorAction SilentlyContinue

            $cfgMatch = $False
            If ($Config) {

                ForEach ($cfg in $Config) {

                    # Grab the AppV configuration details
                    #http://support.citrix.com/proddocs/topic/citrix-appv-admin-v1-xd71/get-ctxappvserver-xd71.html
                    $appvConfig = Get-CtxAppVServer -ByteArray $cfg.Policy

                    # If the existing Management Server matches the specified Management Server
                    If (($appvConfig.ManagementServer -eq $AppvMgmtSvr) -and ($appvConfig.PublishingServer -eq $AppvPubSvr)) {
                    
                        Write-Verbose "Specified config matches existing config."
                        $cfgMatch = $True
                    }
                }

                If (!($cfgMatch)) {

                    # Add config
                    Add-AppvConfig
                } Else {

                    Write-Verbose "App-V configuration already exists."
                }
            } Else {

               # Add config
               Add-AppvConfig 
            }
        } Else {

            Write-Error "[Aborting] App-V Publishing Server test failed with: $pubError"
        }
    } Else {

        Write-Error "[Aborting] App-V Management Server test failed with: $manError"
    }

}