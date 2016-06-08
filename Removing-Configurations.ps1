http://support.citrix.com/article/CTX138318

Add-PSSnapin Citrix.Host.Admin.V2
Add-PSSnapin Citrix.MachineCreation.Admin.V2
Cd XDHyp:\HostingUnits
$hostingUnits = Get-ChildItem
$hostingUnits.HostingUnitUid

Get-ProvTask | Where-Object { $_.ImagesToDelete | Where-Object { $_.HostingUnit -eq "255e2376-072c-4ea6-b00e-c2d66a29448e" } } | Remove-ProvTask