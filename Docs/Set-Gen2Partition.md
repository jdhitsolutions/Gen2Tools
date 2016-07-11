---
external help file: Gen2Tools-help.xml
online version: 
schema: 2.0.0
---

# Set-Gen2Partition
## SYNOPSIS
Configure Windows image and recovery partitions

## SYNTAX

```
Set-Gen2Partition [-Path] <String> [-WIMPath] <String> [-Index <Int32>] [-Unattend <String>]
```

## DESCRIPTION
This command will update partitions for a Generate 2 VHDX file, configured for UEFI.
It is assumed you used the New-Gen2Disk to create the VHDX file and that the partitions are in this order

  1 = Recovery Tools
  2 = System                       
  3 = Reserved (MSR)                     
  4 = Basic (Windows)                       
  5 = Recovery Image                    


You must supply the path to the VHDX file and a valid WIM.
You should also include the index number for the Windows Edition to install.
The WIM will be copied to the recovery partition.

Optionally, you can also specify an XML file to be inserted into the OS partition as unattend.xml

CAUTION: This command will reformat partitions.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
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
VERBOSE: Running bcdboot-\> H:\Windows /s K: /f UEFI
VERBOSE: H:\Windows\System32\reagentc.exe /setosimage /path G:\Recovery /index 1 /target H:\Windows
Directory set to: \\\\?\GLOBALROOT\device\harddisk3\partition5\Recovery

H:\Windows\System32\reagentc.exe : REAGENTC.EXE: Operation Successful.
At line:1 char:1
+ H:\Windows\System32\reagentc.exe /setosimage /path G:\Recovery /index 1 /target  ...
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (REAGENTC.EXE: Operation Successful.:String) \[\], Remote 
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
```
### -------------------------- EXAMPLE 2 --------------------------
```
PS C:\> Set-Gen2Partition -Path D:\vhd\test3.vhdx -WIMPath D:\wim\Win2012R2-Install.wim -Unattend C:\scripts\unattend.xml
```

## PARAMETERS

### -Path
Enter the path to the VHDX file

```yaml
Type: String
Parameter Sets: (All)
Aliases: FullName, pspath

Required: True
Position: 1
Default value: none
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -WIMPath
Enter the path to the WIM file

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: True
Position: 2
Default value: none
Accept pipeline input: False
Accept wildcard characters: False
```

### -Index
The image index from Get-WindowsImage.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: 1
Accept pipeline input: False
Accept wildcard characters: False
```

### -Unattend
Specify the path to an unattend.xml file to insert.

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

## OUTPUTS

## NOTES
Learn more about PowerShell:
http://jdhitsolutions.com/blog/essential-powershell-resources/

## RELATED LINKS
[Mount-DiskImage]()

[Get-Partition]()

[Format-Volume]()

[Get-WindowsImage]()

[Expand-WindowsImage]()


