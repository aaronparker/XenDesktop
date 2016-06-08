http://blogs.citrix.com/2011/04/04/xendesktop-5-powershell-sdk-primer-part-4-creating-pooled-physical-catalogs/

$config = Get-BrokerMachineConfiguration -Name appv*
Get-CtxAppVServer -ByteArray $config[0].Policy

New-CtxAppVServer -PublishingServer 'http://appv1.home.stealthpuppy.com:80' -ManagementServer 'http://appv1.home.stealthpuppy.com:8080'

Test-CtxAppVServer -AppVPublishingServer 'http://appv1.home.stealthpuppy.com:80'
Test-CtxAppVServer -AppVManagementServer 'http://appv1.home.stealthpuppy.com:8080'
