---
external help file: Gen2Tools-help.xml
online version: 
schema: 2.0.0
---

# New-Gen2Disk
## SYNOPSIS
Create a Generation 2 VHDX

## SYNTAX

```
New-Gen2Disk [-Path] <String> [-Size <UInt64>] [-Dynamic] [-BlockSizeBytes <UInt32>]
 [-LogicalSectorSizeBytes <UInt32>] [-PhysicalSectorSizeBytes <UInt32>] [-WhatIf] [-Confirm]
```

## DESCRIPTION
This command will create a generation 2 VHDX file.
Many of the parameters are
from the New-VHD cmdlet.
The disk name must end in .vhdx. 

The disk will be created with these partitions in this order:

* 300MB Recovery Tools
* 100MB System 
* 128MB MSR
* Windows
* 15GB Recovery Image

The size of the windows partition will be whatever is left over give or take a few KB.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
PS C:\> New-Gen2Disk d:\disks\disk001.vhdx -dynamic -size 50GB
```

## PARAMETERS

### -Path
The path to the disk file.

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Size
The size of the new virtual disk in bytes.

```yaml
Type: UInt64
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: 26843545600
Accept pipeline input: False
Accept wildcard characters: False
```

### -Dynamic
Indicate whether the disk should be configured as a dynamically expanding disk.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -BlockSizeBytes
The block size of the new virtual disk in bytes.

```yaml
Type: UInt32
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: 2097152
Accept pipeline input: False
Accept wildcard characters: False
```

### -LogicalSectorSizeBytes
The logical sector size fo the new virtual disk in bytes.

```yaml
Type: UInt32
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: 512
Accept pipeline input: False
Accept wildcard characters: False
```

### -PhysicalSectorSizeBytes
The physical sector size of the new virtual disk in bytes.

```yaml
Type: UInt32
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: 512
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf


```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm


```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: False
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

[New-Partition]()

[Get-DiskImage]()

[Get-Disk]()