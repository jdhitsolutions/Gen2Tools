#requires -version 4.0
#requires -modules DISM,Storage
#requires -RunAsAdministrator


Function Set-Gen2Partition {

[cmdletbinding(ConfirmImpact="High")]
Param(
[parameter(
Position=0,
Mandatory,
HelpMessage="Enter the path to the VHDX file",
ValueFromPipeline=$True,
ValueFromPipelineByPropertyName=$True
)]
[Alias("FullName","pspath")]
[ValidateScript({Test-Path $_})]
[string]$Path,
[parameter(Position=1,Mandatory=$True,
HelpMessage="Enter the path to the WIM file")]
[ValidateScript({Test-Path $_})]
[string]$WIMPath,
[ValidateScript({, 
 $last = (Get-WindowsImage -ImagePath $PSBoundParameters.WIMPath | 
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

Begin {
    Write-Verbose "[BEGIN  ] Starting: $($MyInvocation.Mycommand)"  
} #begin


Process {
Write-Verbose "[PROCESS] Processing $path"

if ($PSCmdlet.ShouldContinue("Are you sure you want to process $path`? Any existing data will be lost!","WARNING!")) {
  
    #mount the VHDX file
    Mount-DiskImage -ImagePath $Path

    #get the disk number
    $disknumber = (Get-DiskImage -ImagePath $path | Get-Disk).Number

    #pre-processing
    Write-Verbose "[PROCESS] $(Get-Partition -DiskNumber $disknumber | out-string) "
  
    #prepare Recovery Image partition
    Write-Verbose "[PROCESS] Processing disknumber $disknumber"

    Write-Verbose "[PROCESS] Formatting Recovery Image"
    Get-Partition -DiskNumber $disknumber -PartitionNumber 5   |
    Format-Volume -FileSystem NTFS -NewFileSystemLabel "RecoveryImage" -confirm:$false |
    Out-Null

    #mount the Recovery image partition with a drive letter
    if (-Not (Get-Partition -DiskNumber $disknumber -PartitionNumber 5).DriveLetter) {
     Write-Verbose "[PROCESS] Assigning drive letter to Recovery Image partition"
     Get-Partition -DiskNumber $disknumber -PartitionNumber 5 |
     Add-PartitionAccessPath -AssignDriveLetter
    }

    $recoveryPartition = Get-Partition -DiskNumber $disknumber -PartitionNumber 5  

    #copy the WIM to recovery image partition as Install.wim
    $recoverfolder = Join-Path "$($recoveryPartition.DriveLetter):" "Recovery"
    
    mkdir $recoverFolder | Out-Null
    $recoveryPath = Join-Path $recoverfolder "install.wim"

    Write-Verbose "[PROCESS] Copying $WIMpath to $recoverypath"
    Copy-Item -Path $WIMPath -Destination $recoverypath 
    
    #mount the OS partition with a drive letter
    Write-Verbose "[PROCESS] Formatting Windows partition"
    Get-Partition -DiskNumber $disknumber -PartitionNumber 4 |
    Format-Volume -FileSystem NTFS -NewFileSystemLabel "Windows" -confirm:$false |
    Out-Null

    if (-Not (Get-Partition -DiskNumber $disknumber -PartitionNumber 4).DriveLetter) {
    Write-Verbose "[PROCESS] Assigning drive letter to Windows partition"
    Get-Partition -DiskNumber $disknumber -PartitionNumber 4 |
    Add-PartitionAccessPath -AssignDriveLetter
    }

    $windowsPartition = Get-Partition -DiskNumber $disknumber -PartitionNumber 4

    #apply the image from recovery to the OS partition
    $WinPath = Join-Path "$($windowsPartition.DriveLetter):" "\"
    $windir = Join-Path $winpath Windows

    Write-Verbose "[PROCESS] Applying image from $recoveryPath to $winpath using Index $index"
    Expand-WindowsImage -ImagePath $recoveryPath -Index $Index -ApplyPath $WinPath

    #copy XML file if specified 
    if ($Unattend) {
        $unattendpath = Join-Path $winpath "Unattend.xml"
        Write-Verbose "[PROCESS] Copying $unattend to $unattendpath"
        Copy-item $Unattend -Destination $unattendpath 
    }
    
    #mount the recovery tools partition with a drive letter  
    Write-Verbose "[PROCESS] Formatting Windows RE Tools partition"
    Get-Partition -DiskNumber $disknumber -PartitionNumber 1 |
    Format-Volume -FileSystem NTFS -NewFileSystemLabel "Windows RE Tools" -confirm:$false |
    Out-Null

    if (-Not (Get-Partition -DiskNumber $disknumber -PartitionNumber 1).DriveLetter) {
      Write-Verbose "[PROCESS] Assigning drive letter to Windows RE Tools partition"
      Get-Partition -DiskNumber $disknumber -PartitionNumber 1 |
      Add-PartitionAccessPath -AssignDriveLetter
    }
    
    $retools =  Get-Partition -disknumber $disknumber -partitionNumber 1

    #create \Recovery\WindowsRE
    Write-Verbose "[PROCESS] Creating Recovery\WindowsRE folder"
    $repath = mkdir "$($retools.driveletter):\Recovery\WindowsRE"

    Write-Verbose "[PROCESS] Copying $($windowsPartition.DriveLetter):\Windows\System32\recovery\winre.wim to $($repath.fullname)"

    #the winre.wim file is hidden
    dir "$($windowsPartition.DriveLetter):\Windows\System32\recovery\winre.wim" -hidden |
    Copy -Destination $repath.FullName 
    
    #assign a letter to the System partition  
    Write-Verbose "[PROCESS] Assigning drive letter to System partition"
    Get-Partition -DiskNumber $disknumber -PartitionNumber 2 |
    Add-PartitionAccessPath -AssignDriveLetter
    
    $systemPartition = Get-Partition -DiskNumber $disknumber -PartitionNumber 2 
    $sysDrive = "$($systemPartition.driveletter):"
    #bcdboot $windir /s $sysDrive /f UEFI | out-null
   
    Write-Verbose "[PROCESS] Running bcdboot-> $windir /s $sysDrive /f UEFI"    
    $cmd = "$windir\System32\bcdboot.exe $windir /s $sysDrive /F UEFI"
    Invoke-Expression $cmd
   
    $cmd = "$windir\System32\reagentc.exe /setosimage /path $recoverfolder /index $index /target $windir"
    Write-Verbose "[PROCESS] Running $cmd"
  
    Invoke-Expression $cmd
  
    #this doesn't appear to be necessary. I get a message this is already enabled
    # $cmd = "$windir\System32\reagentc.exe /setreimage /path $($repath.fullname) /target $windir"
    # Write-Verbose $cmd
    # invoke-expression $cmd
 
    #post processing
    Write-Verbose "[PROCESS]  $(Get-Partition -DiskNumber $disknumber | Out-String) "

    #clean up
    Write-Verbose "[PROCESS] Removing access paths"
    Get-Partition -DiskNumber $disknumber | where {$_.driveletter}  | foreach {
     $dl = "$($_.DriveLetter):"
     $_ | Remove-PartitionAccessPath -accesspath $dl
    }
    
    #dismount
    Write-Verbose "[PROCESS] Dismounting $path"
    Dismount-DiskImage -ImagePath $path

    Write-Verbose "[PROCESS] Finished"

} #confirm
else {
    Write-Verbose "[PROCESS] Process aborted."
}

} #process

End {
    Write-Verbose "[END    ] Ending: $($MyInvocation.Mycommand)"
} #end

} #end function
