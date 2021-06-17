####################################################################################
## 	© 2020,2021 Hewlett Packard Enterprise Development LP
##
## 	Permission is hereby granted, free of charge, to any person obtaining a
## 	copy of this software and associated documentation files (the "Software"),
## 	to deal in the Software without restriction, including without limitation
## 	the rights to use, copy, modify, merge, publish, distribute, sublicense,
## 	and/or sell copies of the Software, and to permit persons to whom the
## 	Software is furnished to do so, subject to the following conditions:
##
## 	The above copyright notice and this permission notice shall be included
## 	in all copies or substantial portions of the Software.
##
## 	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
## 	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
## 	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
## 	THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
## 	OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
## 	ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
## 	OTHER DEALINGS IN THE SOFTWARE.
##
##	File Name:		Sparing.psm1
##	Description: 	Sparing cmdlets 
##		
##	Created:		December 2019
##	Last Modified:	December 2019
##	History:		v3.0 - Created	
#####################################################################################

$Info = "INFO:"
$Debug = "DEBUG:"
$global:VSLibraries = Split-Path $MyInvocation.MyCommand.Path
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

############################################################################################################################################
## FUNCTION Test-CLIObject
############################################################################################################################################
Function Test-CLIObject 
{
Param( 	
    [string]$ObjectType, 
	[string]$ObjectName ,
	[string]$ObjectMsg = $ObjectType, 
	$SANConnection = $global:SANConnection
	)

	$IsObjectExisted = $True
	$ObjCmd = $ObjectType -replace ' ', '' 
	$Cmds = "show$ObjCmd $ObjectName"
	
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmds
	if ($Result -like "no $ObjectMsg listed")
	{
		$IsObjectExisted = $false
	}
	return $IsObjectExisted
	
} # End FUNCTION Test-CLIObject

####################################################################
############################# FUNCTION Get-Spare ###################
####################################################################
Function Get-Spare
{
<#
  .SYNOPSIS
    Displays information about chunklets in the system that are reserved for spares
  
  .DESCRIPTION
    Displays information about chunklets in the system that are reserved for spares and previously free chunklets selected for spares by the system. 
        
  .EXAMPLE
    Get-Spare 
	Displays information about chunklets in the system that are reserved for spares
 	
  .PARAMETER used 
    Display only used spare chunklets
	
  .PARAMETER count
	Number of loop iteration
	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  Get-Spare
    LASTEDIT: December 2019
    KEYWORDS: Get-Spare
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0
 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$used,
		
		[Parameter(Position=1, Mandatory=$false)]
		[Switch]
		$count,
		
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)
	Write-DebugLog "Start: In Get-Spare - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{				
		#check if connection object contents are null/empty
		$Validate1 = Test-CLIConnection $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-CLIConnection $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or the array address (FQDN/IP Address) or user credentials in the connection object are either null or incorrect.  Create a valid connection object using New-CLIConnection or New-PoshSshConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Get-Spare since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Get-Spare since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$cliresult1 = Test-PARCli -SANConnection $SANConnection
	if(($cliresult1 -match "FAILURE :"))
	{
		write-debuglog "$cliresult1" "ERR:" 
		return $cliresult1
	}
	$spareinfocmd = "showspare "
	if($used)
	{
		$spareinfocmd+= " -used "
	}
	write-debuglog "Get list of spare information cmd is => $spareinfocmd " "INFO:"
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $spareinfocmd
	$tempFile = [IO.Path]::GetTempFileName()
	$range1 = $Result.count - 3 
	$range = $Result.count	
	if($count)
	{		
		foreach ($s in  $Result[0..$range] )
		{
			if ($s -match "Total chunklets")
			{
				del $tempFile
				return $s
			}
		}
	}	
	if($Result.count -eq 3)
	{
		del $tempFile
		return "No data available"			
	}	
	foreach ($s in  $Result[0..$range1] )
	{
		if (-not $s)
		{
			write-host "No data available"
			write-debuglog "No data available" "INFO:"\
			del $tempFile
			return
		}
		$s= [regex]::Replace($s,"^ +","")
		$s= [regex]::Replace($s," +"," ")
		$s= [regex]::Replace($s," ",",")
		#write-host "s is $s="
		Add-Content -Path $tempFile -Value $s
	}
	Import-Csv $tempFile
	del $tempFile
}
### End Get-Spare

#####################################################
################### FUNCTION New-Spare ##############
#####################################################
Function New-Spare
{
<#
  .SYNOPSIS
    Allocates chunklet resources as spares. Chunklets marked as spare are not used for logical disk creation and are reserved explicitly for spares, thereby guaranteeing a minimum amount of spare space.
  
  .DESCRIPTION
    Allocates chunklet resources as spares. Chunklets marked as spare are not used for logical disk creation and are reserved explicitly for spares, thereby guaranteeing a minimum amount of spare space. 
        
  .EXAMPLE
    New-Spare -Pdid_chunkNumber "15:1"
	This example marks chunklet 1 as spare for physical disk 15
	
  .EXAMPLE
	New-Spare –pos "1:0.2:3:121"
	This example specifies the position in a drive cage, drive magazine, physical disk,and chunklet number. –pos 1:0.2:3:121, where 1 is the drive cage, 0.2 is the drive magazine, 3 is the physical disk, and 121 is the chunklet number.
 	
  .PARAMETER Pdid_chunkNumber
    Specifies the identification of the physical disk and the chunklet number on the disk.
	
  .PARAMETER pos
    Specifies the position of a specific chunklet identified by its position in a drive cage, drive magazine, physical disk, and chunklet number.
  
  .PARAMETER Partial
   Specifies that partial completion of the command is acceptable.
        
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  New-Spare
    LASTEDIT: December 2019
    KEYWORDS: New-Spare
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$Pdid_chunkNumber,
		
		[Parameter(Position=1, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$pos,
		
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$Partial,
		
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)
	Write-DebugLog "Start: In New-Spare - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{				
		#check if connection object contents are null/empty
		$Validate1 = Test-CLIConnection $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-CLIConnection $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or the array address (FQDN/IP Address) or user credentials in the connection object are either null or incorrect.  Create a valid connection object using New-CLIConnection or New-PoshSshConnection" "ERR:"
				Write-DebugLog "Stop: Exiting New-Spare since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet New-Spare since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$cliresult1 = Test-PARCli -SANConnection $SANConnection
	if(($cliresult1 -match "FAILURE :"))
	{
		write-debuglog "$cliresult1" "ERR:" 
		return $cliresult1
	}
	
	$newsparecmd = "createspare "
	
	if($Partial)
	{
		$newsparecmd +=" -p "
	}
	if(!(($pos) -or ($Pdid_chunkNumber)))
	{
		return "FAILURE : Please specify any one of the params , specify either -PDID_chunknumber or -pos"
	}
	if($Pdid_chunkNumber)
	{
		$newsparecmd += " -f $Pdid_chunkNumber"
		if($pos)
		{
			return "FAILURE : Do not specify both the params , specify either -PDID_chunknumber or -pos"
		}
	}
	if($pos)
	{
		$newsparecmd += " -f -pos $pos"
		if($Pdid_chunkNumber)
		{
			return "FAILURE : Do not specify both the params , specify either -PDID_chunknumber or -pos"
		}
	}
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $newsparecmd
	write-debuglog "Spare  cmd -> $newsparecmd " "INFO:"
	#write-host "Result = $Result"
	if(-not $Result)
	{
		write-host "Success : Create spare chunklet "
	}
	else
	{
		return "$Result"
	}
}
## End New-Spare

##########################################################################
########################### FUNCTION Move-Chunklet #######################
##########################################################################
Function Move-Chunklet
{
<#
  .SYNOPSIS
   Moves a list of chunklets from one physical disk to another.
  
  .DESCRIPTION
   Moves a list of chunklets from one physical disk to another.
        
  .EXAMPLE
    Move-Chunklet -SourcePD_Id 24 -SourceChunk_Position 0  -TargetPD_Id	64 -TargetChunk_Position 50 
	This example moves the chunklet in position 0 on disk 24, to position 50 on disk 64 and chunklet in position 0 on disk 25, to position 1 on disk 27
	
  .PARAMETER SourcePD_Id
    Specifies that the chunklet located at the specified PD
	
  .PARAMETER SourceChunk_Position
    Specifies that the the chunklet’s position on that disk
	
  .PARAMETER TargetPD_Id	
	specified target destination disk
	
  .PARAMETER TargetChunk_Position	
	Specify target chunklet position
	
  .PARAMETER nowait
   Specifies that the command returns before the operation is completed.
   
  .PARAMETER Devtype
	Permits the moves to happen to different device types.

  .PARAMETER Perm
	Specifies that chunklets are permanently moved and the chunklets'
	original locations are not remembered.
		
  .PARAMETER Ovrd
	Permits the moves to happen to a destination even when there will be
	a loss of quality because of the move. 
	
  .PARAMETER DryRun
	Specifies that the operation is a dry run
   
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  Move-Chunklet
    LASTEDIT: December 2019
    KEYWORDS: Move-Chunklet
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$true,ValueFromPipeline=$true)]
		[System.String]
		$SourcePD_Id,
		
		[Parameter(Position=1, Mandatory=$true,ValueFromPipeline=$true)]
		[System.String]
		$SourceChunk_Position,
		
		[Parameter(Position=2, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$TargetPD_Id,
		
		[Parameter(Position=3, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$TargetChunk_Position,
		
		[Parameter(Position=5, Mandatory=$false)]
		[Switch]
		$DryRun,
		
		[Parameter(Position=6, Mandatory=$false)]
		[Switch]
		$NoWait,
		
		[Parameter(Position=7, Mandatory=$false)]
		[Switch]
		$Devtype,
		
		[Parameter(Position=8, Mandatory=$false)]
		[Switch]
		$Perm,
		
		[Parameter(Position=9, Mandatory=$false)]
		[Switch]
		$Ovrd,
		
		[Parameter(Position=10, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)
	Write-DebugLog "Start: In Move-Chunklet - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{		
		#check if connection object contents are null/empty
		$Validate1 = Test-CLIConnection $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-CLIConnection $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or the array address (FQDN/IP Address) or user credentials in the connection object are either null or incorrect.  Create a valid connection object using New-CLIConnection or New-PoshSshConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Move-Chunklet since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Move-Chunklet since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$cliresult1 = Test-PARCli -SANConnection $SANConnection
	if(($cliresult1 -match "FAILURE :"))
	{
		write-debuglog "$cliresult1" "ERR:" 
		return $cliresult1
	}
	$movechcmd = "movech -f"
		
	if($DryRun)
	{
		$movechcmd += " -dr "
	}
	if($NoWait)
	{
		$movechcmd += " -nowait "
	}
	if($Devtype)
	{
		$movechcmd += " -devtype "
	}
	if($Perm)
	{
		$movechcmd += " -perm "
	}
	if($Ovrd)
	{
		$movechcmd += " -ovrd "
	}
	if(($SourcePD_Id)-and ($SourceChunk_Position))
	{
		$params = $SourcePD_Id+":"+$SourceChunk_Position
		$movechcmd += " $params"
		if(($TargetPD_Id) -and ($TargetChunk_Position))
		{
			$movechcmd += "-"+$TargetPD_Id+":"+$TargetChunk_Position
		}
	}
	else
	{
		return "FAILURE :  No parameters specified "
	}
	
	write-debuglog "move chunklet cmd -> $movechcmd " "INFO:"	
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $movechcmd	
	if([string]::IsNullOrEmpty($Result))
	{
		return "FAILURE : Disk $SourcePD_Id chunklet $SourceChunk_Position is not in use. "
	}
	if($Result -match "Move")
	{
		$range = $Result.count
		$tempFile = [IO.Path]::GetTempFileName()
		foreach ($s in  $Result[0..$range] )
		{			
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s," +"," ")
			$s= [regex]::Replace($s," ",",")
			$s= $s.Trim() -replace 'Move,-State-,-Detailed_State-','Move,State,Detailed_State'			
			Add-Content -Path $tempFile -Value $s
		}
		Import-Csv $tempFile
		del $tempFile
	}
	else
	{
		return $Result
	}
}
## End Move-Chunklet

##########################################################################
######################## FUNCTION Move-ChunkletToSpare ###################
##########################################################################

Function Move-ChunkletToSpare
{
<#
  .SYNOPSIS
   Moves data from specified Physical Disks (PDs) to a temporary location selected by the system
  
  .DESCRIPTION
   Moves data from specified Physical Disks (PDs) to a temporary location selected by the system
        
  .EXAMPLE
    Move-ChunkletToSpare -SourcePD_Id 66 -SourceChunk_Position 0  -force 
	Examples shows chunklet 0 from physical disk 66 is moved to spare

  .EXAMPLE	
	Move-ChunkletToSpare -SourcePD_Id 3 -SourceChunk_Position 0

  .EXAMPLE	
	Move-ChunkletToSpare -SourcePD_Id 4 -SourceChunk_Position 0 -nowait
	
  .EXAMPLE
    Move-ChunkletToSpare -SourcePD_Id 5 -SourceChunk_Position 0 -Devtype
	
  .PARAMETER SourcePD_Id
    Indicates that the move takes place from the specified PD
	
  .PARAMETER SourceChunk_Position
    Indicates that the move takes place from  chunklet position
	
  .PARAMETER force
    Specifies that the command is forced. If this option is not used,it will do dry run,No chunklets are actually moved.
	
  .PARAMETER nowait
   Specifies that the command returns before the operation is completed.
   
   .PARAMETER Devtype
	Permits the moves to happen to different device types.
	
  .PARAMETER DryRun
	Specifies that the operation is a dry run
   
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  Move-ChunkletToSpare
    LASTEDIT: December 2019
    KEYWORDS: Move-ChunkletToSpare
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
		[System.String]
		$SourcePD_Id,
		
		[Parameter(Position=1, Mandatory=$true, ValueFromPipeline=$true)]
		[System.String]
		$SourceChunk_Position,

		[Parameter(Position=2, Mandatory=$false)]
		[Switch]
		$DryRun,
		
		[Parameter(Position=3, Mandatory=$false)]
		[Switch]
		$nowait,
		
		[Parameter(Position=4, Mandatory=$false)]
		[Switch]
		$Devtype,
		
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)
	Write-DebugLog "Start: In Move-ChunkletToSpare - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{				
		#check if connection object contents are null/empty
		$Validate1 = Test-CLIConnection $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-CLIConnection $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or the array address (FQDN/IP Address) or user credentials in the connection object are either null or incorrect.  Create a valid connection object using New-CLIConnection or New-PoshSshConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Move-ChunkletToSpare since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Move-ChunkletToSpare since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$cliresult1 = Test-PARCli -SANConnection $SANConnection
	if(($cliresult1 -match "FAILURE :"))
	{
		write-debuglog "$cliresult1" "ERR:" 
		return $cliresult1
	}
	
	$movechcmd = "movechtospare -f"
	
	if($DryRun)
	{
		$movechcmd += " -dr "
	}
	
	if($nowait)
	{
		$movechcmd += " -nowait "
	}
	if($Devtype)
	{
		$movechcmd += " -devtype "
	}
	if(($SourcePD_Id) -and ($SourceChunk_Position))
	{
		$params = $SourcePD_Id+":"+$SourceChunk_Position
		$movechcmd += " $params"
	}
	else
	{
		return "FAILURE : No parameters specified"
	}
	
	write-debuglog "cmd is -> $movechcmd " "INFO:"
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $movechcmd
	
	if([string]::IsNullOrEmpty($Result))
	{		
		return "FAILURE : "
	}
	elseif($Result -match "does not exist")
	{		
		return $Result
	}
	elseif($Result.count -gt 1)
	{
		$range = $Result.count
		$tempFile = [IO.Path]::GetTempFileName()
		foreach ($s in  $Result[0..$range] )
		{
			#write-host "s = $s"
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s," +"," ")
			$s= [regex]::Replace($s," ",",")
			$s= $s.Trim() -replace 'Move,-State-,-Detailed_State-','Move,State,Detailed_State'
			
			Add-Content -Path $tempFile -Value $s
		}
		Import-Csv $tempFile
		del $tempFile
	}
	else
	{
		return $Result
	}
}
## End Move-ChunkletToSpare

################################################################################
################################### FUNCTION Move-PD ###########################
################################################################################
Function Move-PD
{
<#
  .SYNOPSIS
   Moves data from specified Physical Disks (PDs) to a temporary location selected by the system
  
  .DESCRIPTION
   Moves data from specified Physical Disks (PDs) to a temporary location selected by the system
        
  .EXAMPLE
    Move-PD -PD_Id 0 -force
	Example shows moves data from Physical Disks 0  to a temporary location
	
  .EXAMPLE	
	Move-PD -PD_Id 0  
	Example displays a dry run of moving the data on physical disk 0 to free or sparespace
	
  .PARAMETER PD_Id
    Specifies the physical disk ID. This specifier can be repeated to move multiple physical disks.

  .PARAMETER force
    Specifies that the command is forced. If this option is not used,it will do dry run,No chunklets are actually moved.
	
  .PARAMETER DryRun
	Specifies that the operation is a dry run, and no physical disks are
	actually moved.

  .PARAMETER Nowait
	Specifies that the command returns before the operation is completed.

  .PARAMETER Devtype
	Permits the moves to happen to different device types.

  .PARAMETER Perm
	Makes the moves permanent, removes source tags after relocation
   
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  Move-PD
    LASTEDIT: December 2019
    KEYWORDS: Move-PD
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(		
		[Parameter(Position=1, Mandatory=$false)]
		[Switch]
		$DryRun,
				
		[Parameter(Position=2, Mandatory=$false)]
		[Switch]
		$nowait,
		
		[Parameter(Position=3, Mandatory=$false)]
		[Switch]
		$Devtype,
		
		[Parameter(Position=4, Mandatory=$true, ValueFromPipeline=$true)]
		[System.String]
		$PD_Id,		
		
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)
	Write-DebugLog "Start: In Move-PD - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{				
		#check if connection object contents are null/empty
		$Validate1 = Test-CLIConnection $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-CLIConnection $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or the array address (FQDN/IP Address) or user credentials in the connection object are either null or incorrect.  Create a valid connection object using New-CLIConnection or New-PoshSshConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Move-PD since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Move-PD since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$cliresult1 = Test-PARCli -SANConnection $SANConnection
	if(($cliresult1 -match "FAILURE :"))
	{
		write-debuglog "$cliresult1" "ERR:" 
		return $cliresult1
	}
	$movechcmd = "movepd -f"
	
	if($DryRun)
	{
		$movechcmd += " -dr "
	}
	if($nowait)
	{
		$movechcmd += " -nowait "
	}
	if($Devtype)
	{
		$movechcmd += " -devtype "
	}
	if($PD_Id)
	{
		$params = $PD_Id
		$movechcmd += " $params"
	}
	else
	{
		return "FAILURE : No parameters specified"		
	}
	write-debuglog "Push physical disk command => $movechcmd " "INFO:"
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $movechcmd
	
	if([string]::IsNullOrEmpty($Result))
	{
		return "FAILURE : $Result"
	}
	if($Result -match "FAILURE")
	{
		return $Result
	}
	if($Result -match "-Detailed_State-")
	{		
		$range = $Result.count
		$tempFile = [IO.Path]::GetTempFileName()
		foreach ($s in  $Result[0..$range] )
		{			
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s," +"," ")
			$s= [regex]::Replace($s," ",",")
			
			$s= $s.Trim() -replace 'Move,-State-,-Detailed_State-','Move,State,Detailed_State'
			Add-Content -Path $tempFile -Value $s
		}
		Import-Csv $tempFile
		del $tempFile
	}
	else
	{		
		return $Result
	}
}
## End Move-PD 

################################################################################
############################ FUNCTION Move-PDToSpare ###########################
################################################################################
Function Move-PDToSpare
{
<#
  .SYNOPSIS
   Moves data from specified Physical Disks (PDs) to a temporary location selected by the system.
  
  .DESCRIPTION
   Moves data from specified Physical Disks (PDs) to a temporary location selected by the system.
        
  .EXAMPLE
    Move-PDToSpare -PD_Id 0 -force  
	Displays  moving the data on PD 0 to free or spare space
	
  .EXAMPLE
    Move-PDToSpare -PD_Id 0 
	Displays a dry run of moving the data on PD 0 to free or spare space

  .EXAMPLE
    Move-PDToSpare -PD_Id 0 -DryRun
	
  .EXAMPLE
    Move-PDToSpare -PD_Id 0 -Vacate
	
  .EXAMPLE
    Move-PDToSpare -PD_Id 0 -Permanent
	
  .PARAMETER PD_Id
    Specifies the physical disk ID.

  .PARAMETER force
    Specifies that the command is forced. If this option is not used,it will do dry run,No chunklets are actually moved.
	
  .PARAMETER nowait
   Specifies that the command returns before the operation is completed.
   
   .PARAMETER Devtype
	Permits the moves to happen to different device types.

   .PARAMETER DryRun	
	Specifies that the operation is a dry run. No physical disks are actually moved.

   .PARAMETER Vacate
    Deprecated, use -perm instead.
	
   .PARAMETER Permanent
	 Makes the moves permanent, removes source tags after relocation.

   .PARAMETER Ovrd
	Permits the moves to happen to a destination even when there will be
	a loss of quality because of the move. This option is only necessary
	when the target of the move is not specified and the -perm flag is
	used.
	 
   .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
   .Notes
    NAME:  Move-PDToSpare
    LASTEDIT: December 2019
    KEYWORDS: Move-PDToSpare
   
   .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
		[System.String]
		$PD_Id,
		
		[Parameter(Position=1, Mandatory=$false)]
		[Switch]
		$DryRun,
		
		[Parameter(Position=2, Mandatory=$false)]
		[Switch]
		$nowait,
		
		[Parameter(Position=3, Mandatory=$false)]
		[Switch]
		$DevType,
		
		[Parameter(Position=4, Mandatory=$false)]
		[Switch]
		$Vacate,
		
		[Parameter(Position=5, Mandatory=$false)]
		[Switch]
		$Permanent, 
		
		[Parameter(Position=6, Mandatory=$false)]
		[Switch]
		$Ovrd,
		
		[Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)
	Write-DebugLog "Start: In Move-PDToSpare - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{	
		#check if connection object contents are null/empty
		$Validate1 = Test-CLIConnection $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-CLIConnection $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or the array address (FQDN/IP Address) or user credentials in the connection object are either null or incorrect.  Create a valid connection object using New-CLIConnection or New-PoshSshConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Move-PDToSpare since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Move-PDToSpare since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$cliresult1 = Test-PARCli -SANConnection $SANConnection
	if(($cliresult1 -match "FAILURE :"))
	{
		write-debuglog "$cliresult1" "ERR:" 
		return $cliresult1
	}
	
	$movechcmd = "movepdtospare -f"
	
	if($DryRun)
	{
		$movechcmd += " -dr "
	}	
	if($nowait)
	{
		$movechcmd += " -nowait "
	}
	if($DevType)
	{
		$movechcmd += " -devtype "
	}
	if($Vacate)
	{
		$movechcmd += " -vacate "
	}
	if($Permanent)
	{
		$movechcmd += " -perm "
	}
	if($Ovrd)
	{
		$movechcmd += " -ovrd "
	}
	if($PD_Id)
	{
		$params = $PD_Id
		$movechcmd += " $params"
	}
	else
	{
		return "FAILURE : No parameters specified"		
	}
	
	write-debuglog "push physical disk to spare cmd is  => $movechcmd " "INFO:"
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $movechcmd
	if([string]::IsNullOrEmpty($Result))
	{
		return "FAILURE : "
	}
	if($Result -match "Error:")
	{
		return $Result
	}
	if($Result -match "Move")
	{
		$range = $Result.count
		$tempFile = [IO.Path]::GetTempFileName()
		foreach ($s in  $Result[0..$range] )
		{
			#write-host "s = $s"
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s," +"," ")
			$s= [regex]::Replace($s," ",",")
			$s= $s.Trim() -replace 'Move,-State-,-Detailed_State-','Move,State,Detailed_State'
			Add-Content -Path $tempFile -Value $s
		}
		Import-Csv $tempFile
		del $tempFile
	}
	else
	{
		return $Result
	}
}
## End Move-PDToSpare

################################################################################
############################ FUNCTION Move-RelocPD #############################
################################################################################
Function Move-RelocPD
{
<#
  .SYNOPSIS
   Command moves chunklets that were on a physical disk to the target of relocation.
  
  .DESCRIPTION
   Command moves chunklets that were on a physical disk to the target of relocation.
        
  .EXAMPLE
    Move-RelocPD -diskID 8 -DryRun
	moves chunklets that were on physical disk 8 that were relocated to another position, back to physical disk 8
	
  .PARAMETER diskID    
	Specifies that the chunklets that were relocated from specified disk (<fd>), are moved to the specified destination disk (<td>). If destination disk (<td>) is not specified then the chunklets are moved back
    to original disk (<fd>). The <fd> specifier is not needed if -p option is used, otherwise it must be used at least once on the command line. If this specifier is repeated then the operation is performed on multiple disks.

  .PARAMETER DryRun	
	Specifies that the operation is a dry run. No physical disks are actually moved.  
	
  .PARAMETER nowait
   Specifies that the command returns before the operation is completed.
   
  .PARAMETER partial
    Move as many chunklets as possible. If this option is not specified, the command fails if not all specified chunklets can be moved.
	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  Move-RelocPD
    LASTEDIT: December 2019
    KEYWORDS: Move-RelocPD
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$true,ValueFromPipeline=$true)]
		[System.String]
		$diskID,
		
		[Parameter(Position=1, Mandatory=$false)]
		[Switch]
		$DryRun,
		
		[Parameter(Position=2, Mandatory=$false)]
		[Switch]
		$nowait,
		
		[Parameter(Position=3, Mandatory=$false)]
		[Switch]
		$partial,
		
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)
	Write-DebugLog "Start: In Move-RelocPD - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{				
		#check if connection object contents are null/empty
		$Validate1 = Test-CLIConnection $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-CLIConnection $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or the array address (FQDN/IP Address) or user credentials in the connection object are either null or incorrect.  Create a valid connection object using New-CLIConnection or New-PoshSshConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Move-RelocPD since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Move-RelocPD since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$cliresult1 = Test-PARCli -SANConnection $SANConnection
	if(($cliresult1 -match "FAILURE :"))
	{
		write-debuglog "$cliresult1" "ERR:" 
		return $cliresult1
	}
	$movechcmd = "moverelocpd -f "
	if($DryRun)
	{
		$movechcmd += " -dr "
	}	
	if($nowait)
	{
		$movechcmd += " -nowait "
	}
	if($partial)
	{
		$movechcmd += " -partial "
	}
	if($diskID)
	{
		$movechcmd += " $diskID"
	}
	else
	{
		return "FAILURE : No parameters specified"		
	}
	
	write-debuglog "move relocation pd cmd is => $movechcmd " "INFO:"
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $movechcmd
	if([string]::IsNullOrEmpty($Result))
	{
		return "FAILURE : "
	}
	if($Result -match "Error:")
	{
		return $Result
	}	
	if($Result -match "There are no chunklets to move")
	{
		return "There are no chunklets to move"
	}	
	if($Result -match " Move -State- -Detailed_State-")
	{
		$range = $Result.count
		$tempFile = [IO.Path]::GetTempFileName()
		foreach ($s in  $Result[0..$range] )
		{			
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s," +"," ")
			$s= [regex]::Replace($s," ",",")
			$s= $s.Trim() -replace 'Move,-State-,-Detailed_State-','Move,State,Detailed_State'
			Add-Content -Path $tempFile -Value $s			
		}
		Import-Csv $tempFile
		del $tempFile
	}
	else
	{
		return $Result
	}
}
## End Move-RelocPD

################################################################################
############################ FUNCTION Remove-Spare #############################
################################################################################
Function Remove-Spare
{
<#
  .SYNOPSIS
    Command removes chunklets from the spare chunklet list.
  
  .DESCRIPTION
    Command removes chunklets from the spare chunklet list.
	
  .EXAMPLE
    Remove-Spare -Pdid_chunkNumber "1:3"
	Example removes a spare chunklet from position 3 on physical disk 1:
	
  .EXAMPLE
	Remove-Spare –pos "1:0.2:3:121"
	Example removes a spare chuklet from  the position in a drive cage, drive magazine, physical disk,and chunklet number. –pos 1:0.2:3:121, where 1 is the drive cage, 0.2 is the drive magazine, 3 is the physical disk, and 121 is the chunklet number. 	
	
  .PARAMETER Pdid_chunkNumber
    Specifies the identification of the physical disk and the chunklet number on the disk.
	
  .PARAMETER pos
    Specifies the position of a specific chunklet identified by its position in a drive cage, drive magazine, physical disk, and chunklet number.
 
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  Remove-Spare
    LASTEDIT: December 2019
    KEYWORDS: Remove-Spare
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$Pdid_chunkNumber,
		
		[Parameter(Position=1, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$pos,
		
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)
	Write-DebugLog "Start: In Remove-Spare - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{				
		#check if connection object contents are null/empty
		$Validate1 = Test-CLIConnection $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-CLIConnection $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or the array address (FQDN/IP Address) or user credentials in the connection object are either null or incorrect.  Create a valid connection object using New-CLIConnection or New-PoshSshConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Remove-Spare since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Remove-Spare since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	
	$cliresult1 = Test-PARCli -SANConnection $SANConnection
	if(($cliresult1 -match "FAILURE :"))
	{
		write-debuglog "$cliresult1" "ERR:" 
		return $cliresult1
	}
	
	$newsparecmd = "removespare "
	
	if(!(($Pdid_chunkNumber) -or ($pos)))
	{
		return "FAILURE: No parameters specified"
	}
	if($Pdid_chunkNumber)
	{
		$newsparecmd += " -f $Pdid_chunkNumber"
		if($pos)
		{
			return "FAILURE: Please select only one params, either -Pdid_chunkNumber or -pos "
		}
	}
	if($pos)
	{
		$newsparecmd += " -f -pos $pos"
	}
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $newsparecmd
	write-debuglog "Remove spare command -> newsparecmd " "INFO:"
	
	if($Result -match "removed")
	{
		write-debuglog "Success : Removed spare chunklet "  "INFO:"
		return "Success : $Result"
	}
	else
	{
		return "$Result"
	}
}
## End Remove-Spare

Export-ModuleMember Get-Spare , New-Spare , Move-Chunklet , Move-ChunkletToSpare , Move-PD , Move-PDToSpare , Move-RelocPD , Remove-Spare