# 
# Update Image on Machine Catalog 'Windows 7 x86 v2'
# 
# 21/07/2014 1:39 PM
# 
Get-ConfigServiceStatus  -AdminAddress 'xd71.home.stealthpuppy.com:80'

Get-LogSite  -AdminAddress 'xd71.home.stealthpuppy.com:80'

Start-LogHighLevelOperation  -AdminAddress 'xd71.home.stealthpuppy.com:80' -Source 'Studio' -StartTime 21/07/2014 3:28:17 AM -Text 'Update Image on Machine Catalog `'Windows 7 x86 v2`''

Set-ProvSchemeMetadata  -AdminAddress 'xd71.home.stealthpuppy.com:80' -LoggingId 37b094c9-5477-4fce-b908-1a55c2078a4d -Name 'ImageManagementPrep_DoImagePreparation' -ProvisioningSchemeName 'Windows 7 x86 v2' -Value 'True'

Publish-ProvMasterVmImage  -AdminAddress 'xd71.home.stealthpuppy.com:80' -LoggingId 37b094c9-5477-4fce-b908-1a55c2078a4d -MasterImageVM 'XDHyp:\HostingUnits\HV1-LocalStorage\WIN71.vm\MasterImage v1.snapshot\Update 02.snapshot' -ProvisioningSchemeName 'Windows 7 x86 v2' -RunAsynchronously

Start-BrokerRebootCycle  -AdminAddress 'xd71.home.stealthpuppy.com:80' -InputObject @('Windows 7 x86 v2') -LoggingId 37b094c9-5477-4fce-b908-1a55c2078a4d -RebootDuration 0

Stop-LogHighLevelOperation  -AdminAddress 'xd71.home.stealthpuppy.com:80' -EndTime 21/07/2014 3:39:13 AM -HighLevelOperationId '37b094c9-5477-4fce-b908-1a55c2078a4d' -IsSuccessful $True
# Script completed successfully

