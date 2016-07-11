# Gen2Tools Module
## Description
The functions in this PowerShell module are designed to make it easier to create and work with Generation 2 VHDX drives and partitions in Hyper-V.

## Gen2Tools Commands
### [New-Gen2Disk](./Docs/New-Gen2Disk.md)
This command will create a generation 2 VHDX file. Many of the parameters are from the New-VHD cmdlet.

### [Set-Gen2Partition](./Docs/Set-Gen2Partition.md)
This command will update partitions for a Generate 2 VHDX file, configured for UEFI.

Some of these functions were first published and described at: http://www.altaro.com/hyper-v/creating-generation-2-disk-powershell/