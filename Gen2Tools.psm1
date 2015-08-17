#requires -version 4.0
#requires -modules Hyper-V,Storage
#requires -RunAsAdministrator

. $PSScriptRoot\New-Gen2VHD.ps1
. $PSScriptRoot\Set-Gen2Partition.ps1

Export-ModuleMember -Function *