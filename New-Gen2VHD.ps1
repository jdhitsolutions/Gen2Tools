#requires -version 4.0
#requires -modules Hyper-V,Storage
#requires -RunAsAdministrator

Function New-Gen2Disk {

[cmdletbinding(SupportsShouldProcess)]
Param(
[Parameter(Position=0,Mandatory,HelpMessage="Enter the path for the new VHDX file")]
[ValidateNotNullorEmpty()]
[ValidatePattern("\.vhdx$")]
[ValidateScript({
  #get parent
  if (Split-Path $_ | Test-Path) {
    $True
  }
  else {
    Throw "Failed to find parent folder for $_."
  }

})]
[string]$Path,
[ValidateRange(25GB,64TB)]
[uint64]$Size=25GB,
[switch]$Dynamic,
[UInt32]$BlockSizeBytes=2MB,
[ValidateSet(512,4096)]
[Uint32]$LogicalSectorSizeBytes=512,
[ValidateSet(512,4096)]
[Uint32]$PhysicalSectorSizeBytes=512

)

#initialize some variables
$RESize = 300MB
$SysSize = 100MB
$MSRSize = 128MB
$RecoverySize = 15GB

Write-Verbose "Creating $path"

#verify the file doesn't already exist
if (Test-Path -Path $path) {
    Throw "Disk image at $path already exists."
    #bail out
    Return
}

#create the VHDX file
Write-Verbose "Creating the VHDX file for $path"
$vhdParams=@{
 ErrorAction= "Stop"
 Path = $Path
 SizeBytes = $Size
 Dynamic = $Dynamic
 BlockSizeBytes = $BlockSizeBytes
 LogicalSectorSizeBytes = $LogicalSectorSizeBytes
 PhysicalSectorSizeBytes = $PhysicalSectorSizeBytes
}

Try {
  Write-verbose ($vhdParams | out-string)
  $disk = New-VHD @vhdParams
  
}
Catch {
  Throw "Failed to create $path. $($_.Exception.Message)"
  #bail out
  Return
}

if ($disk) {
    #mount the disk image
    Write-Verbose "Mounting disk image"

    Mount-DiskImage -ImagePath $path
    #get the disk number
    $disknumber = (Get-DiskImage -ImagePath $path | Get-Disk).Number

    $WinPartSize = (Get-Disk -Number $disknumber).Size - ($RESize+$SysSize+$MSRSize+$RecoverySize)
    
    #initialize as GPT
    Write-Verbose "Initializing disk $DiskNumber as GPT"
    Initialize-Disk -Number $disknumber -PartitionStyle GPT 

    #clear the disk
    Write-Verbose "Clearing disk partitions to start all over"
    Get-Disk -Number $disknumber | Get-Partition | Remove-Partition -Confirm:$false

    #create the RE Tools partition
    Write-Verbose "Creating a $RESize byte Recovery tools partition on disknumber $disknumber"
    New-Partition -DiskNumber $disknumber -GptType '{de94bba4-06d1-4d40-a16a-bfd50179d6ac}' -Size $RESize |
    Format-Volume -FileSystem NTFS -NewFileSystemLabel "Windows RE Tools" -confirm:$false | Out-null

   $partitionNumber = (get-disk $disknumber | Get-Partition | where {$_.type -eq 'recovery'}).PartitionNumber

    Write-Verbose "Retrieved partition number $partitionnumber"

    #run diskpart to set GPT attribute to prevent partition removal
    #the here string must be left justified
@"
select disk $disknumber
select partition $partitionNumber
gpt attributes=0x8000000000000001
exit
"@ | diskpart | Out-Null

    #create the system partition
    Write-Verbose "Creating a $SysSize byte System partition on disknumber $disknumber"
    <#
     There is a known bug where Format-Volume cannot format an EFI partition
     so formatting will be done with Diskpart
    #>

    $sysPartition = New-Partition -DiskNumber $disknumber -GptType '{c12a7328-f81f-11d2-ba4b-00a0c93ec93bc}' -Size $SysSize
    
    $systemNumber = $sysPartition.PartitionNumber
  
    Write-Verbose "Retrieved system partition number $systemNumber"
"@
select disk $disknumber
select partition $systemNumber
format quick fs=fat32 label=System 
exit
@" | diskpart | Out-Null

    #create MSR
    write-Verbose "Creating a $MSRSize MSR partition"
    New-Partition -disknumber $disknumber -GptType '{e3c9e316-0b5c-4db8-817d-f92df00215ae}' -Size $MSRSize | Out-Null

    #create OS partition
    Write-Verbose "Creating a $WinPartSize byte OS partition on disknumber $disknumber"
    New-Partition -DiskNumber $disknumber -Size $WinPartSize | Out-Null

    #create recovery
    Write-Verbose "Creating a $RecoverySize byte Recovery partition"
    $RecoveryPartition = New-Partition -DiskNumber $disknumber -GptType '{de94bba4-06d1-4d40-a16a-bfd50179d6ac}' -UseMaximumSize | Out-Null
    $RecoveryPartitionNumber = $RecoveryPartition.PartitionNumber

    $RecoveryPartition | Format-Volume -FileSystem NTFS -NewFileSystemLabel "Windows Recovery" -confirm:$false

    #run diskpart to set GPT attribute to prevent partition removal
    #the here string must be left justified
@"
select disk $disknumber
select partition $RecoveryPartitionNumber
gpt attributes=0x8000000000000001
exit
"@ | diskpart | Out-Null

    #dismount
    Write-Verbose "Dismounting disk image"

    Dismount-DiskImage -ImagePath $path

    #write the new disk object to the pipeline
    Get-Item -Path $path

} #if $disk

} #end function
