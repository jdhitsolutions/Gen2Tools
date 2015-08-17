#requires -version 4.0
#requires -modules DISM,Storage
#requires -RunAsAdministrator


Function Set-Gen2Partition {

<#
.SYNOPSIS
Configure Windows image and recovery partitions
.DESCRIPTION
This command will update partitions for a Generate 2 VHDX file, configured for
UEFI. It is assumed you used the New-Gen2Disk to create the VHDX file and that
the partitions are in this order

  1 = Recovery Tools
  2 = System                       
  3 = Reserved (MSR)                     
  4 = Basic (Windows)                       
  5 = Recovery Image                    

You must supply the path to the VHDX file and a valid WIM. You should also
include the index number for the Windows Edition to install. The WIM will be
copied to the recovery partition.

Optionally, you can also specify an XML file to be inserted into the OS
partition as unattend.xml

CAUTION: This command will reformat partitions.

.EXAMPLE
PS C:\> Set-Gen2Partition -Path D:\vhd\demo3.vhdx -WIMPath D:\wim\Win2012R2-Install.wim -verbose

VERBOSE: Processing D:\vhd\demo3.vhdx
VERBOSE: 

   Disk Number: 3

PartitionNumber  DriveLetter Offset                               Size Type                         
---------------  ----------- ------                               ---- ----                         
1                            1048576                            300 MB Recovery                     
2                            315621376                          100 MB System                       
3                            420478976                          128 MB Reserved                     
4                            554696704                        14.48 GB Basic                        
5                            16107175936                         15 GB Recovery                     



VERBOSE: Processing disknumber 3
VERBOSE: Formatting Recovery Image
VERBOSE: Assigning drive letter to Recovery Image partition
VERBOSE: copying D:\wim\Win2012R2-Install.wim to G:\Recovery\install.wim
VERBOSE: Formatting Windows partition
VERBOSE: Assigning drive letter to Windows partition
VERBOSE: Applying image from G:\Recovery\install.wim to H:\ using Index 1
VERBOSE: Dism PowerShell Cmdlets Version 6.3.0.0


LogPath : C:\windows\Logs\DISM\dism.log

VERBOSE: Formatting Windows RE Tools partition
VERBOSE: Assigning drive letter to Windows RE Tools partition
VERBOSE: Creating Recovery\WindowsRE folder
VERBOSE: Copying H:\Windows\System32\recovery\winre.wim to J:\Recovery\WindowsRE
VERBOSE: Assigning drive letter to System partition
VERBOSE: Running bcdboot-> H:\Windows /s K: /f UEFI
VERBOSE: H:\Windows\System32\reagentc.exe /setosimage /path G:\Recovery /index 1 /target H:\Windows
Directory set to: \\?\GLOBALROOT\device\harddisk3\partition5\Recovery

H:\Windows\System32\reagentc.exe : REAGENTC.EXE: Operation Successful.
At line:1 char:1
+ H:\Windows\System32\reagentc.exe /setosimage /path G:\Recovery /index 1 /target  ...
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (REAGENTC.EXE: Operation Successful.:String) [], Remote 
   Exception
    + FullyQualifiedErrorId : NativeCommandError
 
    
VERBOSE: 

   Disk Number: 3

PartitionNumber  DriveLetter Offset                               Size Type                         
---------------  ----------- ------                               ---- ----                         
1                J           1048576                            300 MB Recovery                     
2                K           315621376                          100 MB System                       
3                            420478976                          128 MB Reserved                     
4                H           554696704                        14.48 GB Basic                        
5                G           16107175936                         15 GB Recovery                     



VERBOSE: Removing access paths
VERBOSE: Dismounting D:\vhd\demo3.vhdx
VERBOSE: Finished

.EXAMPLE
PS C:\> Set-Gen2Partition -Path D:\vhd\test3.vhdx -WIMPath D:\wim\Win2012R2-Install.wim -Unattend C:\scripts\unattend.xml

#>


[cmdletbinding(ConfirmImpact="High")]
Param(
[parameter(Position=0,Mandatory=$True,
HelpMessage="Enter the path to the VHDX file",
ValueFromPipeline=$True,
ValueFromPipelineByPropertyName=$True)]
[Alias("FullName","pspath")]
[ValidateScript({Test-Path $_})]
[string]$Path,
[parameter(Position=1,Mandatory=$True,
HelpMessage="Enter the path to the WIM file")]
[ValidateScript({Test-Path $_})]
[string]$WIMPath,
[ValidateScript({, 
 $last = (get-windowsimage -ImagePath $PSBoundParameters.WIMPath | 
         sort ImageIndex | select -last 1).ImageIndex
 If ($_ -gt $last -OR $_ -lt 1) {
    Throw "enter a valid index between 1 and $last"
 }
 else {
    #index is valid
    $True
 }
})]
[int]$Index = 1,
[ValidateScript({Test-Path $_})]
[string]$Unattend
)


Process {
Write-Verbose "Processing $path"

if ($PSCmdlet.ShouldContinue("Are you sure you want to process $path`? Any existing data will be lost!","WARNING!")) {
  
    #mount the VHDX file
    Mount-DiskImage -ImagePath $Path

    #get the disk number
    $disknumber = (Get-DiskImage -ImagePath $path | Get-Disk).Number

    #pre-processing
    Write-Verbose (Get-Partition -DiskNumber $disknumber | out-string) 
  
    #prepare Recovery Image partition
    Write-Verbose "Processing disknumber $disknumber"

    Write-Verbose "Formatting Recovery Image"
    Get-Partition -DiskNumber $disknumber -PartitionNumber 5   |
    Format-Volume -FileSystem NTFS -NewFileSystemLabel "RecoveryImage" -confirm:$false |
    Out-Null

    #mount the Recovery image partition with a drive letter
    if (-Not (Get-Partition -DiskNumber $disknumber -PartitionNumber 5).DriveLetter) {
     Write-Verbose "Assigning drive letter to Recovery Image partition"
     Get-Partition -DiskNumber $disknumber -PartitionNumber 5 |
     Add-PartitionAccessPath -AssignDriveLetter
    }

    $recoveryPartition = get-partition -DiskNumber $disknumber -PartitionNumber 5  

    #copy the WIM to recovery image partition as Install.wim
    $recoverfolder = Join-path "$($recoveryPartition.DriveLetter):" "Recovery"
    
    mkdir $recoverFolder | Out-Null
    $recoveryPath = Join-Path $recoverfolder "install.wim"

    Write-Verbose "copying $WIMpath to $recoverypath"
    Copy-Item -Path $WIMPath -Destination $recoverypath 
    
    #mount the OS partition with a drive letter
    Write-Verbose "Formatting Windows partition"
    Get-Partition -DiskNumber $disknumber -PartitionNumber 4 |
    Format-Volume -FileSystem NTFS -NewFileSystemLabel "Windows" -confirm:$false |
    Out-Null

    if (-Not (Get-Partition -DiskNumber $disknumber -PartitionNumber 4).DriveLetter) {
    Write-Verbose "Assigning drive letter to Windows partition"
    Get-Partition -DiskNumber $disknumber -PartitionNumber 4 |
    Add-PartitionAccessPath -AssignDriveLetter
    }

    $windowsPartition = Get-Partition -DiskNumber $disknumber -PartitionNumber 4

    #apply the image from recovery to the OS partition
    $WinPath = Join-Path "$($windowsPartition.DriveLetter):" "\"
    $windir = Join-path $winpath Windows

    Write-Verbose "Applying image from $recoveryPath to $winpath using Index $index"
    Expand-WindowsImage -ImagePath $recoveryPath -Index $Index -ApplyPath $WinPath

    #copy XML file if specified 
    if ($Unattend) {
        $unattendpath = Join-Path $winpath "Unattend.xml"
        Write-Verbose "Copying $unattend to $unattendpath"
        Copy-item $Unattend -Destination $unattendpath 
    }
    
    #mount the recovery tools partition with a drive letter  
    Write-Verbose "Formatting Windows RE Tools partition"
    Get-Partition -DiskNumber $disknumber -PartitionNumber 1 |
    Format-Volume -FileSystem NTFS -NewFileSystemLabel "Windows RE Tools" -confirm:$false |
    Out-Null

    if (-Not (Get-Partition -DiskNumber $disknumber -PartitionNumber 1).DriveLetter) {
      Write-Verbose "Assigning drive letter to Windows RE Tools partition"
      Get-Partition -DiskNumber $disknumber -PartitionNumber 1 |
      Add-PartitionAccessPath -AssignDriveLetter
    }
    
    $retools =  Get-Partition -disknumber $disknumber -partitionNumber 1

    #create \Recovery\WindowsRE
    Write-Verbose "Creating Recovery\WindowsRE folder"
    $repath = mkdir "$($retools.driveletter):\Recovery\WindowsRE"

    Write-Verbose "Copying $($windowsPartition.DriveLetter):\Windows\System32\recovery\winre.wim to $($repath.fullname)"

    #the winre.wim file is hidden
    dir "$($windowsPartition.DriveLetter):\Windows\System32\recovery\winre.wim" -hidden |
    Copy -Destination $repath.FullName 
    
    #assign a letter to the System partition  
    Write-Verbose "Assigning drive letter to System partition"
    Get-Partition -DiskNumber $disknumber -PartitionNumber 2 |
    Add-PartitionAccessPath -AssignDriveLetter
    
    $systemPartition = Get-Partition -DiskNumber $disknumber -PartitionNumber 2 
    $sysDrive = "$($systemPartition.driveletter):"
    #bcdboot $windir /s $sysDrive /f UEFI | out-null
   
    Write-Verbose "Running bcdboot-> $windir /s $sysDrive /f UEFI"    
    $cmd = "$windir\System32\bcdboot.exe $windir /s $sysDrive /F UEFI"
    Invoke-Expression $cmd
   
    $cmd = "$windir\System32\reagentc.exe /setosimage /path $recoverfolder /index $index /target $windir"
    Write-Verbose $cmd
  
    Invoke-Expression $cmd
  
    #this doesn't appear to be necessary. I get a message this is already enabled
    # $cmd = "$windir\System32\reagentc.exe /setreimage /path $($repath.fullname) /target $windir"
    # Write-Verbose $cmd
    # invoke-expression $cmd
 
    #post processing
    Write-Verbose (Get-Partition -DiskNumber $disknumber | out-string) 

    #clean up
    Write-Verbose "Removing access paths"
    get-partition -DiskNumber $disknumber | where {$_.driveletter}  | foreach {
     $dl = "$($_.DriveLetter):"
     $_ | Remove-PartitionAccessPath -accesspath $dl
    }
    
    #dismount
    Write-Verbose "Dismounting $path"
    Dismount-DiskImage -ImagePath $path

    Write-Verbose "Finished"

} #confirm
else {
  Write-Verbose "Process aborted."
}

} #process

} #end function
