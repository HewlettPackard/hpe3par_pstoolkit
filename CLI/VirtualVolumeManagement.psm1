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
##	File Name:		VirtualVolumeManagement.psm1
##	Description: 	Virtual Volume Management cmdlets 
##		
##	Created:		January 2020
##	Last Modified:	January 2020
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

######################################################################################################################
## FUNCTION Add-Vv
######################################################################################################################
Function Add-Vv
{
<#
  .SYNOPSIS
   The Add-Vv command creates and admits remotely exported virtual volume definitions to enable the migration of these volumes. The newly created
   volume will have the WWN of the underlying remote volume.
   
  .DESCRIPTION
   The Add-Vv command creates and admits remotely exported virtual volume definitions to enable the migration of these volumes. The newly created
   volume will have the WWN of the underlying remote volume.
   
  .EXAMPLE
	Add-Vv -VV_WWN  migvv.0:50002AC00037001A
	Specifies the local name that should be given to the volume being admitted and Specifies the World Wide Name (WWN) of the remote volumes to be admitted.

  .EXAMPLE
	Add-Vv -VV_WWN  "migvv.0:50002AC00037001A migvv.1:50002AC00047001A"

  .EXAMPLE
	Add-Vv -DomainName XYZ -VV_WWN X:Y
	Create the admitted volume in the specified domain. The default is to create it in the current domain, or no domain if the current domain is not set.
	
  .PARAMETER DomainName
	Create the admitted volume in the specified domain   

  .PARAMETER VV_WWN
	Specifies the World Wide Name (WWN) of the remote volumes to be admitted.

  .PARAMETER VV_WWN_NewWWN 
	 Specifies the World Wide Name (WWN) for the local copy of the remote volume. If the keyword "auto" is specified the system automatically generates a WWN for the virtual volume
	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  Add-Vv
    LASTEDIT: January 2020
    KEYWORDS: Add-Vv
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0
 #>
[CmdletBinding()]
	param(
		
		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$DomainName ,
		
		[Parameter(Position=2, Mandatory=$false)]
		[System.String]
		$VV_WWN ,

		[Parameter(Position=3, Mandatory=$false)]
		[System.String]
		$VV_WWN_NewWWN ,
				
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)		
	
	Write-DebugLog "Start: In Add-Vv - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting Add-Vv since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Add-Vv since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli -SANConnection $SANConnection
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}
	if($VV_WWN -Or $VV_WWN_NewWWN)
	{		
		$cmd = "admitvv"
		
		if($DomainName)
		{
			$Cmd+= " -domain $DomainName"						
		}		
		
		if($VV_WWN)	
		{
			$cmd += " $VV_WWN"
			$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $cmd
			write-debuglog "  Executing Add-Vv Command.-->  " "INFO:" 
			return  "$Result"
		}
		if($VV_WWN_NewWWN)	
		{
			$cmd += " $VV_WWN_NewWWN"
			$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $cmd
			write-debuglog "  Executing Add-Vv Command.--> " "INFO:" 
			return  $Result
		}		
	}
	else
	{
		write-debugLog "No VV_WWN Name specified ." "ERR:" 
		return "FAILURE : No VV_WWN name specified"
	}
} ##  End-of  Add-Vv 

##########################################################################
########################### FUNCTION Compress-LD #########################
##########################################################################
Function Compress-LD()
{
<#
  .SYNOPSIS
   Compress-LD - Consolidate space in logical disks (LD).

  .DESCRIPTION
   The Compress-LD command consolidates space on the LDs.

  .EXAMPLE

  .PARAMETER Pat
   Compacts the LDs that match any of the specified patterns.

  .PARAMETER Cons
   This option consolidates regions into the fewest possible LDs.
   When this option is not specified, the regions of each LD will be compacted
   within the same LD.

  .PARAMETER Waittask
   Waits for any created tasks to complete.

  .PARAMETER Taskname
   Specifies a name for the task. When not specified, a default name is
   chosen.

  .PARAMETER Dr
   Specifies that the operation is a dry run, and the tasks will not
   actually be performed.

  .PARAMETER Trimonly
   Only unused LD space is removed. Regions are not moved.

  .PARAMETER LD_Name
   Specifies the name of the LD to be compacted. Multiple LDs can be specified.
   
  .Notes
    NAME: Compress-LD
    LASTEDIT January 2020
    KEYWORDS: Compress-LD
  
  .Link
    http://www.hpe.com

 #Requires PS -Version 3.0
#>
[CmdletBinding()]
 param(
	[Parameter(Position=0, Mandatory=$false)]
	[switch]
	$Pat,

	[Parameter(Position=1, Mandatory=$false)]
	[switch]
	$Cons,

	[Parameter(Position=2, Mandatory=$false)]
	[switch]
	$Waittask,

	[Parameter(Position=3, Mandatory=$false)]
	[System.String]
	$Taskname,

	[Parameter(Position=4, Mandatory=$false)]
	[switch]
	$Dr,

	[Parameter(Position=5, Mandatory=$false)]
	[switch]
	$Trimonly,

	[Parameter(Position=6, Mandatory=$True)]
	[System.String]
	$LD_Name,

	[Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
	$SANConnection = $global:SANConnection
 )

 Write-DebugLog "Start: In Compress-LD - validating input values" $Debug 
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
			Write-DebugLog "Connection object is null/empty or the array address (FQDN/IP Address) or user credentials in the connection object are either null or incorrect.  Create a valid connection object using New-CLIConnection or New-PoshSshConnection" " ERR: "
			Write-DebugLog "Stop: Exiting Compress-LD since SAN connection object values are null/empty" $Debug 
			Return "Unable to execute the cmdlet Compress-LD since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
		}
	}
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
	write-debuglog "$plinkresult"
	Return $plinkresult
 }

	$Cmd = " compactld -f "

 if($Pat)
 {
	$Cmd += " -pat "
 }

 if($Cons)
 {
	$Cmd += " -cons "
 }

 if($Waittask)
 {
	$Cmd += " -waittask "
 }

 if($Taskname)
 {
	$Cmd += " -taskname $Taskname "
 }

 if($Dr)
 {
	$Cmd += " -dr "
 }

 if($Trimonly)
 {
	$Cmd += " -trimonly "
 }

 if($LD_Name)
 {
  $Cmd += " $LD_Name "
 }

 $Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd
 Write-DebugLog "Executing function : Compress-LD command -->" INFO: 

 Return $Result
} ##  End-of Compress-LD

##########################################################################
#########################  FUNCTION Find-LD  #########################
##########################################################################
Function Find-LD()
{
<#
  .SYNOPSIS
   Find-LD - Perform validity checks of data on logical disks (LD).

  .DESCRIPTION
   The Find-LD command executes consistency checks of data on LDs
   in the event of an uncontrolled system shutdown and optionally repairs
   inconsistent LDs.

  .EXAMPLE

  .PARAMETER Y
   Specifies that if errors are found they are either modified so they are
   valid (-y) or left unmodified (-n). If not specified, errors are left
   unmodified (-n).
   
  .PARAMETER N
   Specifies that if errors are found they are either modified so they are
   valid (-y) or left unmodified (-n). If not specified, errors are left
   unmodified (-n).

  .PARAMETER Progress
   Poll sysmgr to get ldck report.

  .PARAMETER Recover
   Attempt to recover the chunklet specified by giving physical disk (<pdid>)
   and the chunklet's position on that disk (<pdch>). If this options is
   specified, -y must be specified as well.

  .PARAMETER Rs
   Check only the specified RAID set.
   
  .PARAMETER LD_Name
   Requests that the integrity of a specified LD is checked. This specifier can be repeated to execute validity checks on multiple LDs.

  .Notes
    NAME: Find-LD
    LASTEDIT January 2020
    KEYWORDS: Find-LD
  
  .Link
    http://www.hpe.com

 #Requires PS -Version 3.0
#>
[CmdletBinding()]
 param(
	[Parameter(Position=0, Mandatory=$false)]
	[switch]
	$Y,

	[Parameter(Position=1, Mandatory=$false)]
	[switch]
	$N,

	[Parameter(Position=2, Mandatory=$false)]
	[switch]
	$Progress,

	[Parameter(Position=3, Mandatory=$false)]
	[System.String]
	$Recover,

	[Parameter(Position=4, Mandatory=$false)]
	[System.String]
	$Rs,

	[Parameter(Position=5, Mandatory=$True)]
	[System.String]
	$LD_Name,

	[Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
	$SANConnection = $global:SANConnection
 )

 Write-DebugLog "Start: In Find-LD - validating input values" $Debug 
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
			Write-DebugLog "Connection object is null/empty or the array address (FQDN/IP Address) or user credentials in the connection object are either null or incorrect.  Create a valid connection object using New-CLIConnection or New-PoshSshConnection" " ERR: "
			Write-DebugLog "Stop: Exiting Find-LD since SAN connection object values are null/empty" $Debug 
			Return "Unable to execute the cmdlet Find-LD since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
		}
	}
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
	write-debuglog "$plinkresult"
	Return $plinkresult
 }

	$Cmd = " checkld "

 if($Y)
 {
	$Cmd += " -y "
 }
 
 if($N)
 {
	$Cmd += " -n "
 }

 if($Progress)
 {
	$Cmd += " -progress "
 }

 if($Recover)
 {
	$Cmd += " -recover $Recover "
 }

 if($Rs)
 {
	$Cmd += " -rs $Rs "
 }

 if($LD_Name)
 {
	$Cmd += " $LD_Name "
 }

 $Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd
 Write-DebugLog "Executing function : Find-LD command -->" INFO: 
 
 Return $Result
} ##  End-of Find-LD

##########################################################################
######################### FUNCTION Get-LD ############################
##########################################################################
Function Get-LD()
{
<#
  .SYNOPSIS
   Get-LD - Show information about logical disks (LDs) in the system.

  .DESCRIPTION
   The Get-LD command displays configuration information about the system's
   LDs.

  .EXAMPLE

  .PARAMETER Cpg
   Requests that only LDs in common provisioning groups (CPGs) that match
   the specified CPG names or patterns be displayed. Multiple CPG names or
   patterns can be repeated using a comma-separated list .

  .PARAMETER Vv
   Requests that only LDs mapped to virtual volumes that match and of the
   specified names or patterns be displayed. Multiple volume names or
   patterns can be repeated using a comma-separated list .

  .PARAMETER Domain
   Only shows LDs that are in domains with names that match any of the
   names or specified patterns. Multiple domain names or patterns can be
   repeated using a comma separated list .

  .PARAMETER Degraded
   Only shows LDs with degraded availability.

  .PARAMETER Sortcol
   Sorts command output based on column number (<col>). Columns are
   numbered from left to right, beginning with 0. At least one column must
   be specified. In addition, the direction of sorting (<dir>) can be
   specified as follows:
	   inc
	   Sort in increasing order (default).
	   dec
	   Sort in decreasing order.
   Multiple columns can be specified and separated by a colon (:). Rows
   with the same information in them as earlier columns will be sorted
   by values in later columns.

  .PARAMETER D
   Requests that more detailed layout information is displayed.

  .PARAMETER Ck
   Requests that checkld information is displayed.

  .PARAMETER P
   Requests that policy information about the LD is displayed.

  .PARAMETER State
   Requests that the detailed state information is displayed.
   This is the same as s.

  .Notes
    NAME: Get-LD
    LASTEDIT January 2020
    KEYWORDS: Get-LD
  
  .Link
    http://www.hpe.com

 #Requires PS -Version 3.0
#>
[CmdletBinding()]
 param(
	[Parameter(Position=0, Mandatory=$false)]
	[System.String]
	$Cpg,

	[Parameter(Position=1, Mandatory=$false)]
	[System.String]
	$Vv,

	[Parameter(Position=2, Mandatory=$false)]
	[System.String]
	$Domain,

	[Parameter(Position=3, Mandatory=$false)]
	[switch]
	$Degraded,

	[Parameter(Position=4, Mandatory=$false)]
	[System.String]
	$Sortcol,

	[Parameter(Position=5, Mandatory=$false)]
	[switch]
	$D,

	[Parameter(Position=6, Mandatory=$false)]
	[switch]
	$Ck,

	[Parameter(Position=7, Mandatory=$false)]
	[switch]
	$P,

	[Parameter(Position=8, Mandatory=$false)]
	[switch]
	$State,

	[Parameter(Position=9, Mandatory=$false)]
	[System.String]
	$LD_Name,

	[Parameter(Position=10, Mandatory=$false, ValueFromPipeline=$true)]
	$SANConnection = $global:SANConnection
 )

 Write-DebugLog "Start: In Get-LD - validating input values" $Debug 
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
			Write-DebugLog "Connection object is null/empty or the array address (FQDN/IP Address) or user credentials in the connection object are either null or incorrect.  Create a valid connection object using New-CLIConnection or New-PoshSshConnection" " ERR: "
			Write-DebugLog "Stop: Exiting Get-LD since SAN connection object values are null/empty" $Debug 
			Return "Unable to execute the cmdlet Get-LD since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
		}
	}
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
	write-debuglog "$plinkresult"
	Return $plinkresult
 }

	$Cmd = " showld "

 if($Cpg)
 {
	$Cmd += " -cpg $Cpg "
 }

 if($Vv)
 {
	$Cmd += " -vv $Vv "
 }

 if($Domain)
 {
	$Cmd += " -domain $Domain "
 }

 if($Degraded)
 {
	$Cmd += " -degraded "
 }

 if($Sortcol)
 {
	$Cmd += " -sortcol $Sortcol "
 }

 if($D)
 {
	$Cmd += " -d "
 }

 if($Ck)
 {
	$Cmd += " -ck "
 }

 if($P)
 {
	$Cmd += " -p "
 }

 if($State)
 {
	$Cmd += " -state "
 }

 if($LD_Name)
 {
  $Cmd += " $LD_Name "
 }

$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd
 Write-DebugLog "Executing function : Get-LD command -->" INFO: 

 if($Result.count -gt 1)
 {			
	if($Cpg)
	{	
		Return  $Result	
	}
	else
	{
		$tempFile = [IO.Path]::GetTempFileName()
		$LastItem = $Result.Count - 3   
		
		foreach ($S in  $Result[0..$LastItem] )
		{
			$s= [regex]::Replace($s,"^ ","")			
			$s= [regex]::Replace($s,"^ ","")
			$s= [regex]::Replace($s,"^ ","")			
			$s= [regex]::Replace($s,"^ ","")		
			$s= [regex]::Replace($s," +",",")			
			$s= [regex]::Replace($s,"-","")			
			$s= $s.Trim()			
			
			Add-Content -Path $tempfile -Value $s				
		}
		Import-Csv $tempFile 
		del $tempFile
	}
 }
 else
 {			
	Return  $Result
 }
 
} ##  End-of Get-LD

##########################################################################
####################### FUNCTION Get-LDChunklet ######################
##########################################################################
Function Get-LDChunklet()
{
<#
  .SYNOPSIS
   Get-LDChunklet - Show chunklet mapping for a logical disk.

  .DESCRIPTION
   The Get-LDChunklet command displays configuration information about the chunklet
   mapping for one logical disk (LD).

  .EXAMPLE

  .PARAMETER Degraded
   Shows only the chunklets in sets that cause the logical disk
   availability to be degraded. For example, if the logical disk normally
   has cage level availability, but one set has two chunklets in the same
   cage, then the chunklets in that set are shown. This option cannot be
   specified with option -lformat or -linfo.

  .PARAMETER Lformat
   Shows the logical disk's row and set layout on the physical disk, where
   the line format <form> is one of:
   row - One line per logical disk row.
   set - One line per logical disk set.

  .PARAMETER Linfo
   Specifies the information shown for each logical disk chunklet, where
   <info> can be one of:
   pdpos - Shows the physical disk position (default).
   pdid  - Shows the physical disk ID.
   pdch  - Shows the physical disk chunklet.
   If multiple <info> fields are specified, each corresponding field will
   be shown separately by a dash (-).

  .Notes
    NAME: Get-LDChunklet
    LASTEDIT January 2020
    KEYWORDS: Get-LDChunklet
  
  .Link
    http://www.hpe.com

 #Requires PS -Version 3.0
#>
[CmdletBinding()]
 param(
	[Parameter(Position=0, Mandatory=$false)]
	[switch]
	$Degraded,

	[Parameter(Position=1, Mandatory=$false)]
	[System.String]
	$Lformat,

	[Parameter(Position=2, Mandatory=$false)]
	[System.String]
	$Linfo,

	[Parameter(Position=4, Mandatory=$false)]
	[System.String]
	$LD_Name,

	[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
	$SANConnection = $global:SANConnection
 )

 Write-DebugLog "Start: In Get-LDChunklet - validating input values" $Debug 
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
			Write-DebugLog "Connection object is null/empty or the array address (FQDN/IP Address) or user credentials in the connection object are either null or incorrect.  Create a valid connection object using New-CLIConnection or New-PoshSshConnection" " ERR: "
			Write-DebugLog "Stop: Exiting Get-LDChunklet since SAN connection object values are null/empty" $Debug 
			Return "Unable to execute the cmdlet Get-LDChunklet since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
		}
	}
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
	write-debuglog "$plinkresult"
	Return $plinkresult
 }

	$Cmd = " showldch "

 if($Degraded)
 {
	$Cmd += " -degraded "
 }

 if($Lformat)
 {
	$Cmd += " -lformat $Lformat "
 }

 if($Linfo)
 {
	$Cmd += " -linfo $Linfo "
 }

 if($LD_Name)
 {
	$Cmd += " $LD_Name "
 }

 $Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd
 Write-DebugLog "Executing function : Get-LDChunklet command -->" INFO: 
 
 if($Result.count -gt 1)
 {	
	$tempFile = [IO.Path]::GetTempFileName()
	$LastItem = $Result.Count - 3 
	$FristCount = 0
	if($Lformat -Or $Linfo)
	{
		$FristCount = 1
	}
	
	foreach ($S in  $Result[$FristCount..$LastItem] )
	{
		$s= [regex]::Replace($s,"^ ","")			
		$s= [regex]::Replace($s,"^ ","")
		$s= [regex]::Replace($s,"^ ","")			
		$s= [regex]::Replace($s,"^ ","")		
		$s= [regex]::Replace($s," +",",")			
		#$s= [regex]::Replace($s,"-","")			
		$s= $s.Trim()			
		
		Add-Content -Path $tempfile -Value $s				
	}
	Import-Csv $tempFile 
	del $tempFile	
 }
 else
 {			
	Return  $Result
 }
} ##  End-of Get-LDChunklet

##################################################################################
################################ Start Get-Space #################################
##################################################################################
Function Get-Space
{
<#
  .SYNOPSIS
    Displays estimated free space for logical disk creation.
  
  .DESCRIPTION
    Displays estimated free space for logical disk creation.
        
  .EXAMPLE
    Get-Space 
	Displays estimated free space for logical disk creation.
	
  .EXAMPLE
    Get-Space -RaidType r1
	 Example displays the estimated free space for a RAID-1 logical disk:
	 
  .PARAMETER cpgName
    Specifies that logical disk creation parameters are taken from CPGs that match the specified CPG
	name or pattern,Multiple CPG names or patterns can be specified using a comma separated list, for
	example cpg1,cpg2,cpg3.

  .PARAMETER RaidType
	Specifies the RAID type of the logical disk: r0 for RAID-0, r1 for RAID-1, r5 for RAID-5, or r6 for
	RAID-6. If no RAID type is specified, the default is r1 for FC and SSD device types and r6 is for
	the NL device types
	
  .PARAMETER Cage 
	Specifies one or more drive cages. Drive cages are identified by one or more integers (item).
	Multiple drive cages are separated with a single comma (1,2,3). A range of drive cages is
	separated with a hyphen (0–3). The specified drive cage(s) must contain disks.
	
  .PARAMETER Disk
	Specifies one or more disks. Disks are identified by one or more integers (item). Multiple disks
	are separated with a single comma (1,2,3). A range of disks is separated with a hyphen (0–3).
	Disks must match the specified ID(s).
	
  .PARAMETER History
	 Specifies that free space history over time for CPGs specified

  .PARAMETER SSZ
	Specifies the set size in terms of chunklets.
	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  Get-Space
    LASTEDIT: January 2020
    KEYWORDS: Get-Space
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$cpgName,
		
		[Parameter(Position=1, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$RaidType,
		
		[Parameter(Position=2, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$Cage,
		
		[Parameter(Position=3, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$Disk,
		
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$History,
		
		[Parameter(Position=5, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$SSZ,
		
		[Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)	
	Write-DebugLog "Start: In Get-Space - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting Get-Space since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Get-Space since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$cliresult1 = Test-PARCli -SANConnection $SANConnection
	if(($cliresult1 -match "FAILURE :"))
	{
		write-debuglog "$cliresult1" "ERR:" 
		return $cliresult1
	}
	$sysspacecmd = "showspace "
	$sysinfo = @{}	
	if($cpgName)
	{		
		if(($RaidType) -or ($Cage) -or($Disk))
		{
			return "FAILURE : Use only One parameter at a time."
		}		
		$sysspacecmd += " -cpg $cpgName"
		$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $sysspacecmd
		write-debuglog "Get system space cmd -> $sysspacecmd " "INFO:"
		if ($Result -match "FAILURE :")
		{
			write-debuglog "no CPGs found or matched" "Info:"
			return "FAILURE : no CPGs found or matched"			
		}
		if( $Result -match "There is no free space information")
		{
			write-debuglog "FAILURE : There is no free space information" "Info:"
			return "FAILURE : There is no free space information"			
		}
		if( $Result.Count -lt 4 )
		{
			return "$Result"		
		}
		$tempFile = [IO.Path]::GetTempFileName()
		$3parosver = Get-Version -S -SANConnection  $SANConnection 
		$incre = "true" 
		foreach ($s in  $Result[2..$Result.Count] )
		{
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s," +"," ")
			$s= [regex]::Replace($s," ",",")
			
			if($3parosver -eq "3.1.1")
			{
				$s= $s.Trim() -replace 'Name,RawFree,LDFree,Total,Used,Total,Used,Total,Used','CPG_Name,EstFree_RawFree(MB),EstFree_LDFree(MB),Usr_Total(MB),Usr_Used(MB),Snp_Total(MB),Snp_Used(MB),Adm_Total(MB),Adm_Used(MB)'
			}
			if($3parosver -eq "3.1.2")
			{
				$s= $s.Trim() -replace 'Name,RawFree,LDFree,Total,Used,Total,Used,Total,Used','CPG_Name,EstFree_RawFree(MB),EstFree_LDFree(MB),Usr_Total(MB),Usr_Used(MB),Snp_Total(MB),Snp_Used(MB),Adm_Total(MB),Adm_Used(MB)' 
			}
			else
			{
				$s= $s.Trim() -replace 'Name,RawFree,LDFree,Total,Used,Total,Used,Total,Used,Compaction,Dedup','CPG_Name,EstFree_RawFree(MB),EstFree_LDFree(MB),Usr_Total(MB),Usr_Used(MB),Snp_Total(MB),Snp_Used(MB),Adm_Total(MB),Adm_Used(MB),Compaction,Dedup'
			}
			
			if($incre -eq "true")
			{				
				$sTemp = $s.Split(',')							
				$sTemp[1]="RawFree(MiB)"				
				$sTemp[2]="LDFree(MiB)"
				$sTemp[3]="OPFree(MiB)"				
				$sTemp[4]="Base(MiB)"
				$sTemp[5]="Snp(MiB)"				
				$sTemp[6]="Free(MiB)"
				$sTemp[7]="Total(MiB)"		
				
				$newTemp= [regex]::Replace($sTemp,"^ ","")			
				$newTemp= [regex]::Replace($sTemp," ",",")				
				$newTemp= $newTemp.Trim()
				$s=$newTemp							
			}			
			Add-Content -Path $tempFile -Value $s
			$incre="false"
		}		
		Import-Csv $tempFile
		del $tempFile
		return
	}		
	if($RaidType)
	{
		if(($cpgName) -or ($Cage) -or($Disk))
		{
			return "FAILURE : Use only One parameter at a time."
		}
		$RaidType = $RaidType.toLower()
		$sysspacecmd += " -t $RaidType"
		write-debuglog "Get system space cmd -> $sysspacecmd " "INFO:"
		$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $sysspacecmd
		if ($Result -match "Illegal raid type")
		{
			write-debuglog "FAILURE : Illegal raid type $RaidType, specify r0, r1, r5, or r6" "Info:"
			return "FAILURE : Illegal raid type $RaidType, specify r0, r1, r5, or r6"
		}
		
		foreach ($s in $Result[2..$Result.count])
		{
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s," +",",")
			$s = $s.split(",")
			$sysinfo.add("RawFree(MB)",$s[0])
			$sysinfo.add("UsableFree(MB)",$s[1])
			$sysinfo
		}
		return
	}
	if($Cage)
	{
		if(($RaidType) -or ($cpgName) -or($Disk))
		{
			return "FAILURE : Use only One parameter at a time."
		}
		$sysspacecmd += " -p -cg $Cage"
		write-debuglog "Get system space cmd -> $sysspacecmd " "INFO:"
		$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $sysspacecmd
		if ($Result -match "Illegal pattern integer or range")
		{
			write-debuglog "FAILURE : Illegal pattern integer or range: $Cage" "ERR:"
			return "FAILURE : $Result "
		}
		foreach ($s in $Result[2..$Result.count])
		{
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s," +",",")
			$s = $s.split(",")
			$sysinfo.add("RawFree(MB)",$s[0])
			$sysinfo.add("UsableFree(MB)",$s[1])
			$sysinfo
		}
		return
	}
	if($Disk)
	{
		if(($RaidType) -or ($Cage) -or($cpgName)){
			return "FAILURE : Use only One parameter at a time."
		}
		$sysspacecmd += "-p -dk $Disk"
		write-debuglog "Get system space cmd -> $sysspacecmd " "INFO:"
		$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $sysspacecmd
		if ($Result -match "Illegal pattern integer or range")
		{
			write-debuglog "FAILURE : Illegal pattern integer or range: $Disk" "ERR:"
			return "FAILURE : Illegal pattern integer or range: $Disk"
		}
		foreach ($s in $Result[2..$Result.count])
		{
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s," +",",")
			$s = $s.split(",")
			$sysinfo.add("RawFree(MB)",$s[0])
			$sysinfo.add("UsableFree(MB)",$s[1])
			$sysinfo
		}
	}
	if($History)
	{
		if(($RaidType) -or ($Cage) -or($cpgName) -or($Disk))
		{
			return "FAILURE : Use only One parameter at a time."
		}
		$sysspacecmd += " -hist "
	}
	if($SSZ)
	{
		if(($RaidType) -or ($Cage) -or($cpgName) -or($Disk) -or($History))
		{
			return "FAILURE : Use only One parameter at a time."
		}
		$sysspacecmd += " -ssz $SSZ "
		write-debuglog "Get system space cmd -> $sysspacecmd " "INFO:"
		$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $sysspacecmd
		if ($Result -match "Invalid setsize" -Or $Result -match "Expecting a non-negative integer")
		{
			write-debuglog "FAILURE : Illegal raid type $RaidType, specify r0, r1, r5, or r6" "Info:"
			return "FAILURE : $Result"
		}
		
		foreach ($s in $Result[2..$Result.count])
		{
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s," +",",")
			$s = $s.split(",")
			$sysinfo.add("RawFree(MB)",$s[0])
			$sysinfo.add("UsableFree(MB)",$s[1])
			$sysinfo
		}
		return
	}
	if(-not(( ($Disk) -or ($Cage)) -or (($RaidType) -or ($cpg))))
	{		
		$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $sysspacecmd
		write-debuglog "Get system space cmd -> $sysspacecmd " "INFO:"
		if ($Result -match "Illegal pattern integer or range")
		{
			write-debuglog "FAILURE : Illegal pattern integer or range: $Disk" "ERR:"
			return "FAILURE : Illegal pattern integer or range: $Disk"
		}
		foreach ($s in $Result[2..$Result.count])
		{
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s," +",",")
			$s = $s.split(",")
			$sysinfo.add("RawFree(MB)",$s[0])
			$sysinfo.add("UsableFree(MB)",$s[1])
			$sysinfo
		}
	}
}
#### End-Of Get-Space

##################################################################################################
####################################### FUNCTION Get-Vv #########################################
##################################################################################################

Function Get-Vv
{
<#
  .SYNOPSIS
    Get list of virtual volumes per Domain and CPG
  
  .DESCRIPTION
    Get list of virtual volumes per Domain and CPG
        
  .EXAMPLE
    Get-Vv
	List all virtual volumes
	
  .EXAMPLE	
	Get-Vv -vvName PassThru-Disk 
	List virtual volume PassThru-Disk
	
  .EXAMPLE	
	Get-Vv -vvName PassThru-Disk -Domain mydom
	List volumes in the domain specified DomainName	
	
  .PARAMETER vvName 
    Specify name of the volume. 
	If prefixed with 'set:', the name is a volume set name.	

  .PARAMETER DomainName 
    Queries volumes in the domain specified DomainName.
	
  .PARAMETER CPGName
    Queries volumes that belongs to a given CPG.	

  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  Get-Vv
    LASTEDIT: January 2020
    KEYWORDS: Get-Vv
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$vvName,

		[Parameter(Position=1, Mandatory=$false)]
		[System.String[]]
		$DomainName,
		
		[Parameter(Position=2, Mandatory=$false)]
		[System.String[]]
		$CPGName,
		
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)		
	
	Write-DebugLog "Start: In Get-Vv - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting Get-Vv since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Get-Vv since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli -SANConnection $SANConnection
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}
	
	$GetvVolumeCmd = "showvvcpg"

	if ($DomainName)
	{
		$GetvVolumeCmd += " -domain $DomainName"
	}	
	if ($vvName)
	{
		$GetvVolumeCmd += " $vvName"
	}

	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $GetvVolumeCmd
	write-debuglog "Get list of Virtual Volumes" "INFO:" 
	if($Result -match "no vv listed")
	{
		return "FAILURE: No vv $vvName found"
	}

	#$tempFile = [IO.Path]::GetTempFileName()
	$Result = $Result | where { ($_ -notlike '*total*') -and ($_ -notlike '*---*')} ## Eliminate summary lines
	
	if ( $Result.Count -gt 1)
	{
		$tempFile = [IO.Path]::GetTempFileName()
		$LastItem = $Result.Count -2  
		foreach ($s in  $Result[0..$LastItem] )
		{
			$s= [regex]::Replace($s," +",",")			# Replace one or more spaces with comma to build CSV line
			$s= $s.Trim() -replace ',Adm,Snp,Usr,Adm,Snp,Usr',',Adm(MB),Snp(MB),Usr(MB),New_Adm(MB),New_Snp(MB),New_Usr(MB)' 	

			Add-Content -Path $tempFile -Value $s
		}

		if($CPGName) { Import-Csv $tempFile | where  {$_.CPG -like $CPGName} }
		else { Import-Csv $tempFile }
				
		del $tempFile
	}	
	else
	{
		Write-DebugLog $result "INFO:"
		return "FAILURE: No vv $vvName found error:$result "
	}	

} # END Get-Vv

########################################################################################################
################################################ FUNCTION Get-VvList ###################################
########################################################################################################
Function Get-VvList
{
<#
  .SYNOPSIS
    The Get-VvList command displays information about all Virtual Volumes (VVs) or a specific VV in a system. 
  
  .DESCRIPTION
    The Get-VvList command displays information about all Virtual Volumes (VVs) or a specific VV in a system.
        
  .EXAMPLE
    Get-VvList
	List all virtual volumes
	
  .EXAMPLE	
	Get-VvList -vvName xyz 
	List virtual volume xyz
	
  .EXAMPLE	
	Get-VvList -Space -vvName xyz 
	
  .EXAMPLE	
	Get-VvList -Pattern -Prov full
	List virtual volume  provision type as "tpvv"
	
  .EXAMPLE	
	Get-VvList -Pattern -Type base
	List snapshot(vitual copy) volumes 
	
  .EXAMPLE	
	Get-VvList -R -Pattern -Prov tp* -Host TTest -Baseid 50
	
  .EXAMPLE	
	Get-VvList -Showcols "Id,Name"
	
  .PARAMETER Listcols
	List the columns available to be shown in the -showcols option
	described below

  .PARAMETER D
	Displays detailed information about the VVs.  The following columns
	are shown:
	Id Name Rd Mstr Prnt Roch Rwch PPrnt PBlkRemain VV_WWN CreationTime Udid

  .PARAMETER Pol
	Displays policy information about the VVs. The following columns
	are shown: Id Name Policies

  .PARAMETER Space
	Displays Logical Disk (LD) space use by the VVs.  The following columns
	are shown:
	Id Name Prov Compr Dedup Type Adm_Rsvd_MB Adm_Used_MB Snp_Rsvd_MB
	Snp_Used_MB Snp_Used_Perc Warn_Snp_Perc Limit_Snp_Perc Usr_Rsvd_MB
	Usr_Used_MB Usr_Used_Perc Warn_Usr_Perc Limit_Usr_Perc Tot_Rsvd_MB
	Tot_Used_MB VSize_MB Host_Wrt_MB Compaction Compression

	Note: For snapshot (vcopy) VVs, the Adm_Used_MB, Snp_Used_MB,
	Usr_Used_MB and the corresponding _Perc columns have a '*' before
	the number for two reasons: to indicate that the number is an estimate
	that must be updated using the updatesnapspace command, and to indicate
	that the number is not included in the total for the column since the
	corresponding number for the snapshot's base VV already includes that
	number.

  .PARAMETER R
	Displays raw space use by the VVs.  The following columns are shown:
	Id Name Prov Compr Dedup Type Adm_RawRsvd_MB Adm_Rsvd_MB Snp_RawRsvd_MB
	Snp_Rsvd_MB Usr_RawRsvd_MB Usr_Rsvd_MB Tot_RawRsvd_MB Tot_Rsvd_MB
	VSize_MB

  .PARAMETER Zone
	Displays mapping zone information for VVs.
	The following columns are shown:
	Id Name Prov Compr Dedup Type VSize_MB Adm_Zn Adm_Free_Zn Snp_Zn
	Snp_Free_Zn Usr_Zn Usr_Free_Zn

  .PARAMETER G
	Displays the SCSI geometry settings for the VVs.  The following
	columns are shown: Id Name SPT HPC SctSz

  .PARAMETER Alert
	Indicates whether alerts are posted on behalf of the VVs.
	The following columns are shown:
	Id Name Prov Compr Dedup Type VSize_MB Snp_Used_Perc Warn_Snp_Perc
	Limit_Snp_Perc Usr_Used_Perc Warn_Usr_Perc Limit_Usr_Perc
	Alert_Adm_Fail_Y Alert_Snp_Fail_Y Alert_Snp_Wrn_Y Alert_Snp_Lim_Y
	Alert_Usr_Fail_Y Alert_Usr_Wrn_Y Alert_Usr_Lim_Y

  .PARAMETER AlertTime
	Shows times when alerts were posted (when applicable).
	The following columns are shown:
	Id Name Alert_Adm_Fail Alert_Snp_Fail Alert_Snp_Wrn Alert_Snp_Lim
	Alert_Usr_Fail Alert_Usr_Wrn Alert_Usr_Lim

  .PARAMETER CPProg
	Shows the physical copy and promote progress.
	The following columns are shown:
	Id Name Prov Compr Dedup Type CopyOf VSize_MB Copied_MB Copied_Perc

  .PARAMETER CpgAlloc
	Shows CPGs associated with each VV.  The following columns are
	shown: Id Name Prov Compr Dedup Type UsrCPG SnpCPG

  .PARAMETER State
	Shows the detailed state information for the VVs.  The following
	columns are shown: Id Name Prov Compr Dedup Type State Detailed_State SedState

  .PARAMETER Hist
	Shows the history information of the VVs.
	The following columns are shown:
	Id Name Prov Compr Dedup Type CreationTime RetentionEndTime ExpirationTime SpaceCalcTime Comment

  .PARAMETER RCopy
	This option appends two columns, RcopyStatus and RcopyGroup, to
	any of the display options above.

  .PARAMETER NoTree
	Do not display VV names in tree format.
	Unless either the -notree or the -sortcol option described below
	are specified, the VVs are ordered and the  names are indented in
	tree format to indicate the virtual copy snapshot hierarchy.
	
  .PARAMETER Expired
	Show only VVs that have expired.

  .PARAMETER Retained
	Shows only VVs that have a retention time.

  .PARAMETER Failed
	Shows only failed VVs.
	
  .PARAMETER Domain
    Shows only VVs that are in domains with names matching one or more of
	the specified domain_name or patterns. This option does not allow
	listing objects within a domain of which the user is not a member.
	
  .PARAMETER Pattern
	Pattern for matching VVs to show (see below for description
	of <pattern>) If the -p option is specified multiple times, each
	instance of <pattern> adds additional candidate VVs that match that
	pattern.        

  .PARAMETER CPG
    Show only VVs whose UsrCPG or SnpCPG matches the one or more of
    the cpgname_or_patterns.
	  
  .PARAMETER Prov
    Show only VVs with Prov (provisioning) values that match the
    prov_or_pattern.
	  
  .PARAMETER Type
   Show only VVs of types that match the type_or_pattern.
	  
  .PARAMETER Host
    Show only VVs that are exported as VLUNs to hosts with names that
    match one or more of the hostname_or_patterns.
	  
  .PARAMETER Baseid
    Show only VVs whose BsId column matches one more of the
    baseid_or_patterns.
  
  .PARAMETER Copyof
    Show only VVs whose CopyOf column matches one more of the
    vvname_or_patterns.
	
  .PARAMETER Rcopygroup
	Show only VVs that are in Remote Copy groups that match
	one or more of the groupname_or_patterns.
	
  .PARAMETER Policy
	Show only VVs whose policy matches the one or more of the
	policy_or_pattern.
	
  .PARAMETER vmName
	Show only VVs whose vmname matches one or more of the
	vvname_or_patterns.
	
  .PARAMETER vmId
	Show only VVs whose vmid matches one or more of the
	vmids.
	
  .PARAMETER vmHost
	Show only VVs whose vmhost matches one or more of the
	vmhost_or_patterns.
	
  .PARAMETER vvolState
	Show only VVs whose vvolstate matches the specified
	state - bound or unbound.
	
  .PARAMETER vvolsc
	Show only VVs whose storage container (vvset) name matches one
	or more of the vvset_name_or_patterns.
	
  .PARAMETER vvName 
    Specify name of the volume. 
	If prefixed with 'set:', the name is a volume set name.	

  .PARAMETER Prov 
    Specify name of the Prov type (full | tpvv |tdvv |snp |cpvv ). 
	
  .PARAMETER Type 
    Specify name of the Prov type ( base | vcopy ).
	
  .PARAMETER ShowCols 
        Explicitly select the columns to be shown using a comma-separated list
        of column names.  For this option the full column names are shown in
        the header.
        Run 'showvv -listcols' to list the available columns.
        Run 'clihelp -col showvv' for a description of each column.
	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  Get-VvList
    LASTEDIT: January 2020
    KEYWORDS: Get-VvList
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[switch]
		$Listcols,
		
		[Parameter(Position=1, Mandatory=$false)]
		[switch]
		$D,
		
		[Parameter(Position=2, Mandatory=$false)]
		[switch]
		$Pol,
		
		[Parameter(Position=3, Mandatory=$false)]
		[switch]
		$Space,
		
		[Parameter(Position=4, Mandatory=$false)]
		[switch]
		$R,
		
		[Parameter(Position=5, Mandatory=$false)]
		[switch]
		$Zone,
		
		[Parameter(Position=6, Mandatory=$false)]
		[switch]
		$G,
		
		[Parameter(Position=7, Mandatory=$false)]
		[switch]
		$Alert,
		
		[Parameter(Position=8, Mandatory=$false)]
		[switch]
		$AlertTime,
		
		[Parameter(Position=9, Mandatory=$false)]
		[switch]
		$CPProg,
		
		[Parameter(Position=10, Mandatory=$false)]
		[switch]
		$CpgAlloc,
		
		[Parameter(Position=11, Mandatory=$false)]
		[switch]
		$State,
		
		[Parameter(Position=12, Mandatory=$false)]
		[switch]
		$Hist,
		
		[Parameter(Position=13, Mandatory=$false)]
		[switch]
		$RCopy,
		
		[Parameter(Position=14, Mandatory=$false)]
		[switch]
		$NoTree,
		
		[Parameter(Position=15, Mandatory=$false)]
		[System.String]
		$Domain,
		
		[Parameter(Position=16, Mandatory=$false)]
		[switch]
		$Expired,
		
		[Parameter(Position=17, Mandatory=$false)]
		[switch]
		$Retained,
		
		[Parameter(Position=18, Mandatory=$false)]
		[switch]
		$Failed,	
		
		[Parameter(Position=19, Mandatory=$false)]
		[System.String]
		$vvName,
	
		[Parameter(Position=20, Mandatory=$false)]
		[System.String]
		$Type,
		
		[Parameter(Position=21, Mandatory=$false)]
		[System.String]
		$Prov,
		
		[Parameter(Position=22, Mandatory=$false)]
		[switch]
		$Pattern,
		
		[Parameter(Position=23, Mandatory=$false)]
		[System.String]
		$CPG,
		
		[Parameter(Position=24, Mandatory=$false)]
		[System.String]
		$Host,
		
		[Parameter(Position=25, Mandatory=$false)]
		[System.String]
		$Baseid,
		
		[Parameter(Position=26, Mandatory=$false)]
		[System.String]
		$Copyof,
		
		[Parameter(Position=27, Mandatory=$false)]
		[System.String]
		$Rcopygroup,
		
		[Parameter(Position=28, Mandatory=$false)]
		[System.String]
		$Policy,
		
		[Parameter(Position=29, Mandatory=$false)]
		[System.String]
		$vmName,
		
		[Parameter(Position=30, Mandatory=$false)]
		[System.String]
		$vmId,
		
		[Parameter(Position=31, Mandatory=$false)]
		[System.String]
		$vmHost,
		
		[Parameter(Position=32, Mandatory=$false)]
		[System.String]
		$vvolState,
		
		[Parameter(Position=33, Mandatory=$false)]
		[System.String]
		$vvolsc,
		
		[Parameter(Position=34, Mandatory=$false)]
		[System.String]
		$ShowCols,
		
		[Parameter(Position=35, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)		
	
	Write-DebugLog "Start: In Get-VV - validating input values" $Debug 

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
				Write-DebugLog "Stop: Exiting Get-VvList since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Get-VvList since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$cliresult1 = Test-PARCli -SANConnection $SANConnection

	if(($cliresult1 -match "FAILURE :"))
	{
		write-debuglog "$cliresult1" "ERR:" 
		return $cliresult1
	}
	
	$GetvVolumeCmd = "showvv "
	$cnt=1
	
	if ($Listcols)
	{
		$GetvVolumeCmd += "-listcols "
		$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $GetvVolumeCmd
		return $Result				
	}
	
	if($D)
	{
		$GetvVolumeCmd += "-d "
		$cnt=0
	}	
	if($Pol)
	{
		$GetvVolumeCmd += "-pol "
		$cnt=0
	}
	if($Space)
	{
		$GetvVolumeCmd += "-space "
		$cnt=2
	}	
	if($R)
	{
		$GetvVolumeCmd += "-r "
		$cnt=2
	}
	if($Zone)
	{
		$GetvVolumeCmd += "-zone "
		$cnt=1
	}
	if($G)
	{
		$GetvVolumeCmd += "-g "
		$cnt=0
	}
	if($Alert)
	{
		$GetvVolumeCmd += "-alert "
		$cnt=2
	}
	if($AlertTime)
	{
		$GetvVolumeCmd += "-alerttime "
		$cnt=2
	}
	if($CPProg)
	{
		$GetvVolumeCmd += "-cpprog "
		$cnt=0
	}
	if($CpgAlloc)
	{
		$GetvVolumeCmd += "-cpgalloc "
		$cnt=0
	}
	if($State)
	{
		$GetvVolumeCmd += "-state "
		$cnt=0
	}
	if($Hist)
	{
		$GetvVolumeCmd += "-hist "
		$cnt=0
	}
	if($RCopy)
	{
		$GetvVolumeCmd += "-rcopy "
		$cnt=1
	}
	if($NoTree)
	{
		$GetvVolumeCmd += "-notree "
		$cnt=1
	}
	if($Domain)
	{
		$GetvVolumeCmd += "-domain $Domain "
		$cnt=0
	}
	if($Expired)
	{
		$GetvVolumeCmd += "-expired "
		$cnt=1
	}
	if($Retained)
	{
		$GetvVolumeCmd += "-retained "
		$cnt=0
	}
	if($Failed)
	{
		$GetvVolumeCmd += "-failed "
		$cnt=1
	}
	if($pattern)
	{
		if($CPG)
		{
			$GetvVolumeCmd += "-p -cpg $CPG "
		}
		if($Prov)
		{
			$GetvVolumeCmd += "-p -prov $Prov "
		}
		if($Type)
		{
			$GetvVolumeCmd += "-p -type $Type "
		}
		if($Host)
		{
			$GetvVolumeCmd += "-p -host $Host "
		}
		if($Baseid)
		{
			$GetvVolumeCmd += "-p -baseid $Baseid "
		}
		if($Copyof)
		{
			$GetvVolumeCmd += "-p -copyof $Copyof "
		}
		if($Rcopygroup)
		{
			$GetvVolumeCmd += "-p -rcopygroup $Rcopygroup "
		}
		if($Policy)
		{
			$GetvVolumeCmd += "-p -policy $Policy "
		}
		if($vmName)
		{
			$GetvVolumeCmd += "-p -vmname $vmName "
		}
		if($vmId)
		{
			$GetvVolumeCmd += "-p -vmid $vmId "
		}
		if($vmHost)
		{
			$GetvVolumeCmd += "-p -vmhost $vmHost "
		}
		if($vvolState)
		{
			$GetvVolumeCmd += "-p -vvolstate $vvolState "
		}		
		if($vvolsc)
		{
			$GetvVolumeCmd += "-p -vvolsc $vvolsc "
		}
	}
	
	if($ShowCols)
	{
		$GetvVolumeCmd += "-showcols $ShowCols "
		$cnt=0
	}
	
	if ($vvName)
	{
		$GetvVolumeCmd += " $vvName"
	}
		
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $GetvVolumeCmd
	write-debuglog "Get list of Virtual Volumes" "INFO:" 
	
	if($Result -match "no vv listed")
	{
		return "FAILURE : No vv $vvName found"
	}
		
	if ( $Result.Count -gt 1)
	{		
		$incre = "true"
		$tempFile = [IO.Path]::GetTempFileName()
		$LastItem = $Result.Count -3  
		foreach ($s in  $Result[$cnt..$LastItem] )
		{
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s,"-+","-")
			$s= [regex]::Replace($s," +",",")		
			$s= $s.Trim()
			$temp1 = $s -replace 'Adm,Snp,Usr,VSize','Adm(MB),Snp(MB),Usr(MB),VSize(MB)' 
			$s = $temp1			
			$temp2 = $s -replace '-CreationTime-','Date(Creation),Time(Creation),Zone(Creation)'
			$s = $temp2	
			$temp3 = $s -replace '-SpaceCalcTime-','Date,Time,Zone'
			$s = $temp3	
			if($Space)
			{			
				if($incre -eq "true")
				{								
					$sTemp1=$s				
					$sTemp = $sTemp1.Split(',')	
					$sTemp[6]="Rsvd(MiB/Snp)"					
					$sTemp[7]="Used(MiB/Snp)"				
					$sTemp[8]="Used(VSize/Snp)"
					$sTemp[9]="Wrn(VSize/Snp)"
					$sTemp[10]="Lim(VSize/Snp)"  
					$sTemp[11]="Rsvd(MiB/Usr)"					
					$sTemp[12]="Used(MiB/Usr)"				
					$sTemp[13]="Used(VSize/Usr)"
					$sTemp[14]="Wrn(VSize/Usr)"
					$sTemp[15]="Lim(VSize/Usr)"
					$sTemp[16]="Rsvd(MiB/Total)"					
					$sTemp[17]="Used(MiB/Total)"
					$newTemp= [regex]::Replace($sTemp,"^ ","")			
					$newTemp= [regex]::Replace($sTemp," ",",")				
					$newTemp= $newTemp.Trim()
					$s=$newTemp							
				}
			}
			if($R)
			{			
				if($incre -eq "true")
				{					
					$sTemp1=$s				
					$sTemp = $sTemp1.Split(',')	
					$sTemp[6]="RawRsvd(Snp)"					
					$sTemp[7]="Rsvd(Snp)"				
					$sTemp[8]="RawRsvd(Usr)"
					$sTemp[9]="Rsvd(Usr)"
					$sTemp[10]="RawRsvd(Tot)"  
					$sTemp[11]="Rsvd(Tot)"					
					$newTemp= [regex]::Replace($sTemp,"^ ","")			
					$newTemp= [regex]::Replace($sTemp," ",",")				
					$newTemp= $newTemp.Trim()
					$s=$newTemp							
				}
			}
			if($Zone)
			{
				if($incre -eq "true")
				{				
					$sTemp1=$s				
					$sTemp = $sTemp1.Split(',')											
					$sTemp[7]="Zn(Adm)"				
					$sTemp[8]="Free_Zn(Adm)"
					$sTemp[9]="Zn(Snp)"	
					$sTemp[10]="Free_Zn(Snp)"
					$sTemp[11]="Zn(Usr)"		
					$sTemp[12]="Free_Zn(Usr)"					
					$newTemp= [regex]::Replace($sTemp,"^ ","")			
					$newTemp= [regex]::Replace($sTemp," ",",")				
					$newTemp= $newTemp.Trim()
					$s=$newTemp				
				}
			}
			if($Alert)
			{
				if($incre -eq "true")
				{				
					$sTemp1=$s				
					$sTemp = $sTemp1.Split(',')											
					$sTemp[7]="Used(Snp(%VSize))"				
					$sTemp[8]="Wrn(Snp(%VSize))"
					$sTemp[9]="Lim(Snp(%VSize))"	
					$sTemp[10]="Used(Usr(%VSize))"				
					$sTemp[11]="Wrn(Usr(%VSize))"
					$sTemp[12]="Lim(Usr(%VSize))"	
					$sTemp[13]="Fail(Adm)"	
					$sTemp[14]="Fail(Snp)"	
					$sTemp[15]="Wrn(Snp)"	
					$sTemp[16]="Lim(Snp)"	
					$sTemp[17]="Fail(Usr)"	
					$sTemp[18]="Wrn(Usr)"	
					$sTemp[19]="Lim(Usr)"					
					$newTemp= [regex]::Replace($sTemp,"^ ","")			
					$newTemp= [regex]::Replace($sTemp," ",",")				
					$newTemp= $newTemp.Trim()
					$s=$newTemp							
				}
			}
			if($AlertTime)
			{
				if($incre -eq "true")
				{				
					$sTemp1=$s				
					$sTemp = $sTemp1.Split(',')											
					$sTemp[2]="Fail(Adm))"				
					$sTemp[3]="Fail(Snp)"
					$sTemp[4]="Wrn(Snp)"	
					$sTemp[5]="Lim(Snp)"				
					$sTemp[6]="Fail(Usr)"
					$sTemp[7]="Wrn(Usr)"	
					$sTemp[8]="Lim(Usr)"										
					$newTemp= [regex]::Replace($sTemp,"^ ","")			
					$newTemp= [regex]::Replace($sTemp," ",",")				
					$newTemp= $newTemp.Trim()
					$s=$newTemp							
				}
			}
			Add-Content -Path $tempFile -Value $s
			$incre="false"
		}
		Import-Csv $tempFile
		del $tempFile
	}	
	else
	{
		Write-DebugLog $result "INFO:"
		return "FAILURE : No vv $vvName found Error : $Result"
	}
	

} # END Get-VvList

#####################################################################################################################
############################################### FUNCTION Get-VvSet ##################################################
#####################################################################################################################

Function Get-VvSet
{
<#
  .SYNOPSIS
    Get list of Virtual Volume(VV) sets defined on the storage system and their members
  
  .DESCRIPTION
    Get lists of Virtual Volume(VV) sets defined on the storage system and their members
        
  .EXAMPLE
    Get-VvSet
	 List all virtual volume set(s)

  .EXAMPLE  
	Get-VvSet -vvSetName "MyVVSet" 
	List Specific VVSet name "MyVVSet"
	
  .EXAMPLE  
	Get-VvSet -vvName "MyVV" 
	List VV sets containing VVs matching vvname "MyVV"

  .EXAMPLE	
	Get-VvSet -VV -vvName AIX_PERF_VV_SET
	
  .PARAMETER vvSetName 
    Specify name of the vvset to be listed.

  .PARAMETER Detailed
	Show a more detailed listing of each set.
	
  .PARAMETER VV
	Show VV sets that contain the supplied vvnames or patterns
	
  .PARAMETER Summary
	Shows VV sets with summarized output with VV sets names and number of VVs in those sets
	
  .PARAMETER vvName 
     Specifies that the sets containing virtual volumes	

  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  Get-VvSet  
    LASTEDIT: January 2020
    KEYWORDS: Get-VvSet
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[switch]
		$Detailed,
		
		[Parameter(Position=1, Mandatory=$false)]
		[switch]
		$VV,
		
		[Parameter(Position=2, Mandatory=$false)]
		[switch]
		$Summary,
		
		[Parameter(Position=3, Mandatory=$false)]
		[System.String]
		$vvSetName,
		
		[Parameter(Position=4, Mandatory=$false)]
		[System.String]
		$vvName,
		
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)		
	
	Write-DebugLog "Start: In Get-VvSet - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting Get-VvSet since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Get-VvSet since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli -SANConnection $SANConnection
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}
	$GetVVSetCmd = "showvvset "
	
	if ($Detailed)
	{
		$GetVVSetCmd += " -d "
	}
	if ($VV)
	{
		$GetVVSetCmd += " -vv "
	}
	if ($Summary)
	{
		$GetVVSetCmd += " -summary "
	}
	
	if ($vvSetName)
	{
		$GetVVSetCmd += " $vvSetName"
	}
	elseif($vvName)
	{
		$GetVVSetCmd += " $vvName"
	}
	else
	{
		write-debuglog "VVSet parameter $vvSetName is empty. Simply return all existing vvset " "INFO:"		
	}	
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $GetVVSetCmd
	#write-host ""
	#return $Result	
	
	if($Result -match "No vv set listed")
	{
		return "FAILURE : No vv set listed"
	}
	if($Result -match "total")
	{		
		$tempFile = [IO.Path]::GetTempFileName()
		$LastItem = $Result.Count -3		
		foreach ($s in  $Result[0..$LastItem] )
		{		
			$s= [regex]::Replace($s,"^ ","")			
			$s= [regex]::Replace($s," +",",")	
			#$s= [regex]::Replace($s,"-","")
			$s= $s.Trim()			
			Add-Content -Path $tempFile -Value $s
			#Write-Host	" First if statement $s"		
		}
		Import-Csv $tempFile 
		del $tempFile
	}
	else
	{
		return $Result
	}
		
} # End Get-VvSet

######################################################################################################################
################################################## FUNCTION Import-Vv ################################################
######################################################################################################################
Function Import-Vv
{
<#
  .SYNOPSIS
	The Import-Vv command starts migrating the data from a remote LUN to the local Storage System. The remote LUN should have been prepared using the
	admitvv command.

  .DESCRIPTION  
	The Import-Vv command starts migrating the data from a remote LUN to the local Storage System. The remote LUN should have been prepared using the
	admitvv command.

  .EXAMPLE
	Import-Vv -Usrcpg asCpg

  .EXAMPLE
	Import-Vv -Usrcpg asCpg -VVName as4
	
  .EXAMPLE
	Import-Vv -Usrcpg asCpg -Snapname asTest -VVName as4
	
  .EXAMPLE
	Import-Vv -Usrcpg asCpg -Snp_cpg asCpg -VVName as4

  .EXAMPLE
	Import-Vv -Usrcpg asCpg -Priority high -VVName as4
	
  .EXAMPLE
	Import-Vv -Usrcpg asCpg -NoTask -VVName as4
	
  .PARAMETER NoCons
	Any VV sets specified will not be imported as consistent groups.
	Allows multiple VV sets to be specified.

	If the VV set contains any VV members that in a previous import
	attempt were imported consistently, they will continue to get
	imported consistently.

  .PARAMETER Priority 
	Specifies the priority of migration of a volume or a volume set. If
	this option is not specified, the default priority will be medium.
	The volumes with priority set to high will migrate faster than other
	volumes with medium and low priority.

  .PARAMETER Job_ID
	Specifies the Job ID up to 511 characters for the volume. The Job ID
	will be tagged in the events that are posted during volume migration.
	Use -jobid "" to remove the Job ID.

  .PARAMETER NoTask
	Performs import related pre-processing which results in transitioning
	the volume to exclusive state and setting up of the "consistent" flag
	on the volume if importing consistently. The import task will not be
	created, and hence volume migration will not happen. The "importvv"
	command should be rerun on the volume at a later point of time without
	specifying the -notask option to initiate the actual migration of the
	volume. With the -notask option, other options namely -tpvv, -dedup,
	-compr, -snp_cpg, -snap, -clrsrc, -jobid and -pri cannot be specified.

  .PARAMETER Cleanup
	Performs cleanup on source array after successful migration of the
	volume. As part of the cleanup, any exports of the source volume will be
	removed, the source volume will be removed from all of the VV sets it
	is member of, the VV sets will be removed if the source volume is their
	only member, all of the snapshots of source volume will be removed,
	and finally the source volume itself will be removed. The -clrsrc
	option is valid only when the source array is running HPE 3PAR OS release
	3.2.2 or higher. The cleanup will not be performed if the source volume
	has any snapshots that have VLUN exports.

  .PARAMETER TpVV
	Import the VV into a thinly provisioned space in the CPG specified
	in the command line. The import will enable zero detect for the duration
	of import so that the data blocks containing zero do not occupy
	space on the new array.

  .PARAMETER TdVV
	This option is deprecated, see -dedup.

  .PARAMETER DeDup
	Import the VV into a thinly provisioned space in the CPG specified in
	the command line. This volume will share logical disk space with other
	instances of this volume type created from the same CPG to store
	identical data blocks for space saving.

  .PARAMETER Compr
	Import the VV into a compressed virtual volume in the CPG specified
	in the command line.

  .PARAMETER MinAlloc
	This option specifies the default allocation size (in MB) to be set for TPVVs and TDVVs.


  .PARAMETER Snapname
	 Create a snapshot of the volume at the end of the import phase

  .PARAMETER Snp_cpg
	 Specifies the name of the CPG from which the snapshot space will be allocated.
	 
  .PARAMETER Usrcpg
	 Specifies the name of the CPG from which the volume user space will be allocated.
	
  .PARAMETER VVName
	 Specifies the VVs with the specified name 
	 
  .PARAMETER SANConnection 
	Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection

  .Notes
	NAME: Import-Vv  
	LASTEDIT: January 2020
	KEYWORDS: Import-Vv 

  .Link
	http://www.hpe.com
 
 #Requires PS -Version 3.0
 #>
[CmdletBinding()]
	param(
	
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$Usrcpg ,
	
		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$Snapname ,
		
		[Parameter(Position=2, Mandatory=$false)]
		[System.String]
		$Snp_cpg ,
		
		[Parameter(Position=3, Mandatory=$false)]
		[switch]
		$NoCons ,
		
		[Parameter(Position=4, Mandatory=$false)]
		[System.String]
		$Priority ,
		
		[Parameter(Position=5, Mandatory=$false)]
		[System.String]
		$Job_ID ,
		
		[Parameter(Position=6, Mandatory=$false)]
		[switch]
		$NoTask ,
		
		[Parameter(Position=7, Mandatory=$false)]
		[switch]
		$Cleanup ,
		
		[Parameter(Position=8, Mandatory=$false)]
		[switch]
		$TpVV ,
		
		[Parameter(Position=9, Mandatory=$false)]
		[switch]
		$TdVV ,
		
		[Parameter(Position=10, Mandatory=$false)]
		[switch]
		$DeDup ,
		
		[Parameter(Position=11, Mandatory=$false)]
		[switch]
		$Compr ,
		
		[Parameter(Position=12, Mandatory=$false)]
		[System.String]
		$MinAlloc ,
		
		[Parameter(Position=13, Mandatory=$false)]
		[System.String]
		$VVName ,
				
		[Parameter(Position=14, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)		
	
	Write-DebugLog "Start: In Import-Vv - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting Import-Vv  since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Import-Vv since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli -SANConnection $SANConnection
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}
	$Cmd = "importvv -f"			

	if($Snapname)
	{
		$Cmd+= " -snap $Snapname"
	}
	if($Snp_cpg)
	{
		$Cmd+= " -snp_cpg $Snp_cpg"
	}
	if($NoCons)
	{
		$Cmd+= " -nocons "
	}
	if($Priority)
	{
		$opt="high","med","low"		
		if ($opt -eq $Priority)
		{
			$Cmd+= " -pri $Priority"
		}
		else
		{
			return " FAILURE : Invalid Priority $Priority ,Please use [high | med | low]."
		}
	}
	if ($Job_ID)
	{
		$Cmd+= " -jobid $Job_ID"
	}
	if($NoTask)
	{
		$Cmd+= " -notask "
	}
	if($Cleanup)
	{
		$Cmd+= " -clrsrc "
	}
	if($TpVV)
	{
		$Cmd+= " -tpvv "
	}
	if($TdVV)
	{
		$Cmd+= " -tdvv "
	}
	if($DeDup)
	{
		$Cmd+= " -dedup "
	}
	if($Compr)
	{
		$Cmd+= " -compr "
	}
	if($MinAlloc)
	{
		$Cmd+= " -minalloc $MinAlloc"
	}
	
	if($Usrcpg)
	{
		$Cmd += " $Usrcpg "
	}
	else
	{
		write-debugLog "No CPG Name specified ." "ERR:" 
		return "FAILURE : No CPG Name specified ."
	}
	
	if($VVName)
	{
		$Cmd += " $VVName"
	}	
	#write-host "$Cmd"
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd
	write-debuglog "  Executing Import-Vv Command.--> " "INFO:" 
	return  "$Result"	

} ##  End-of Import-Vv 

##########################################################################################################
############################################ FUNCTION New-Vv ##########################################
##########################################################################################################
Function New-Vv
{
<#
  .SYNOPSIS
    Creates a vitual volume.
  
  .DESCRIPTION
	Creates a vitual volume.
	
  .EXAMPLE	
	New-Vv

  .EXAMPLE
	New-Vv -vvName AVV

  .EXAMPLE
	New-Vv -vvName AVV -CPGName ACPG

  .EXAMPLE
	New-Vv -vvName XX -CPGName ZZ

  .EXAMPLE
	New-Vv -vvName AVV -CPGName ZZ

  .EXAMPLE
	New-Vv -vvName AVV1 -CPGName ZZ -Force

  .EXAMPLE
	New-Vv -vvName AVV -CPGName ZZ -Force -tpvv

  .EXAMPLE
	New-Vv -vvName AVV -CPGName ZZ -Force -Template Test_Template
        
  .EXAMPLE
    New-Vv -vvName PassThru-Disk -Size 100g -CPGName HV -vvSetName MyVolumeSet
	The command creates a new volume named PassThru-disk of size 100GB.
	The volume is created under the HV CPG group and will be contained inside the MyvolumeSet volume set.
	If MyvolumeSet does not exist, the command creates a new volume set.	

  .EXAMPLE
    New-Vv -vvName PassThru-Disk1 -Size 100g -CPGName MyCPG -tpvv -minalloc 2048 -vvSetName MyVolumeSet
	The command creates a new thin provision volume named PassThru-disk1 of size 100GB.
	The volume is created under the MyCPG CPG group and will be contained inside the MyvolumeSet volume set.
	If MyvolumeSet does not exist, the command creates a new volume set and allocates minimum 2048MB.
	
  .PARAMETER vvName 
    Specify new name of the virtual volume
	
  .PARAMETER Force
	Force to execute
	
  .PARAMETER Size 
    Specify the size of the new virtual volume. Valid input is: 1 for 1 MB , 1g or 1G for 1GB , 1t or 1T for 1TB
	
  .PARAMETER CPGName
    Specify the name of CPG
	
  .PARAMETER Template
	Use the options defined in template <tname>.  
		
  .PARAMETER Volume_ID
	Specifies the ID of the volume. By default, the next available ID is chosen.

  .PARAMETER Count
	Specifies the number of identical VVs to create. 

  .PARAMETER Shared
	Specifies that the system will try to share the logical disks among the VVs. 

  .PARAMETER Wait
	If the command would fail due to the lack of clean space, the -wait
            
  .PARAMETER vvSetName
    Specify the name of a volume set. If it does not exist, the command will also create new volume set.
	
  .PARAMETER minalloc	
	This option specifies the default allocation size (in MB) to be set
	
  .PARAMETER Snp_aw
	Enables a snapshot space allocation warning. A warning alert is
	generated when the reserved snapshot space of the VV
	exceeds the indicated percentage of the VV size.

  .PARAMETER Snp_al
	Sets a snapshot space allocation limit. The snapshot space of the
	VV is prevented from growing beyond the indicated
	percentage of the virtual volume size.
	
  .PARAMETER Comment
	Specifies any additional information up to 511 characters for the
	volume.
		
  .PARAMETER tdvv
	Deprecated. Should use -dedup.

  .PARAMETER tpvv
	Specifies that the volume should be a thinly provisioned volume.
		
  .PARAMETER snp_cpg 
	Specifies the name of the CPG from which the snapshot space will be
	allocated.
		
  .PARAMETER sectors_per_track
	Defines the virtual volume geometry sectors per track value that is
	reported to the hosts through the SCSI mode pages. The valid range is
	between 4 to 8192 and the default value is 304.
		
  .PARAMETER minalloc 
	This option specifies the default allocation size (in MB) to be set.
	Allocation size specified should be at least (number-of-nodes * 256) and
	less than the CPG grow size.

  .PARAMETER heads_per_cylinder
	Allows you to define the virtual volume geometry heads per cylinder
	value that is reported to the hosts though the SCSI mode pages. The
	valid range is between 1 to 255 and the default value is 8.
		
  .PARAMETER snp_aw
	Enables a snapshot space allocation warning. A warning alert is
	generated when the reserved snapshot space of the VV
	exceeds the indicated percentage of the VV size.

  .PARAMETER snp_al
	Sets a snapshot space allocation limit. The snapshot space of the
	VV is prevented from growing beyond the indicated
	percentage of the virtual volume size.

  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  New-Vv  
    LASTEDIT: January 2020
    KEYWORDS: New-Vv
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$vvName,
		
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$Size="1G", 	# Default is 1GB
		
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
        $CPGName,		
	
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
        $vvSetName,
		
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$Force,
		
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
        $Template,
		
		[Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
        $Volume_ID,
		
		[Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
        $Count,
		
		[Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
        $Wait,
		
		[Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
        $Comment,
		
		[Parameter(Position=10, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$Shared,
		
		[Parameter(Position=11, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$tpvv,
		
		[Parameter(Position=11, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$tdvv,
		
		[Parameter(Position=12, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$Snp_Cpg,
		
		[Parameter(Position=13, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
        $Sectors_per_track,
		
		[Parameter(Position=14, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
        $Heads_per_cylinder,
		
		[Parameter(Position=15, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
        $minAlloc,
		
		[Parameter(Position=16, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
        $Snp_aw,
		
		[Parameter(Position=17, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
        $Snp_al,
		
		[Parameter(Position=18, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)		
	
	Write-DebugLog "Start: In New-Vv - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting New-Vv since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet New-Vv since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli -SANConnection $SANConnection
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}
         
	if ($vvName)
	{
		if ($CPGName)
		{
			## Check CPG Name 
			##
			if ( !( Test-CLIObject -objectType 'cpg' -objectName $CPGName -SANConnection $SANConnection))
			{
				write-debuglog " CPG $CPGName does not exist. Please use New-CPG to create a CPG before creating vv" "INFO:" 
				return "FAILURE : No cpg $cpgName found"
			}		

			## Check vv Name . Create if necessary
			##
			if (Test-CLIObject -objectType 'vv' -objectName $vvName -SANConnection $SANConnection)
			{
				write-debuglog " virtual Volume $vvName already exists. No action is required" "INFO:" 
				return "FAILURE : vv $vvName already exists"
			}
			
			$CreateVVCmd = "createvv"
			
			if($Force)
			{
				$CreateVVCmd +=" -f "
			}
			 
			if ($minAlloc)
			{
				if(!($tpvv))
				{
					return "FAILURE : -minalloc optiong should not use without -tpvv"
				}
			}					
			if ($tpvv)
			{
				$CreateVVCmd += " -tpvv "
				if ($minAlloc)
				{
					$ps3parbuild = Get-Version -S -SANConnection $SANConnection
					if($ps3parbuild -ge "3.2.1" -Or $ps3parbuild -ge "3.1.1")
					{
						$CreateVVCmd += " -minalloc $minAlloc"
					}
					else
					{
						return "FAILURE : -minalloc option not supported in the OS version: $ps3parbuild"
					}
				}
			}
			if($tdvv)
			{
				$CreateVVCmd +=" -tdvv "
			}
			
			if($Template)
			{
				$CreateVVCmd +=" -templ $Template "
			}
			if($Volume_ID)
			{
				$CreateVVCmd +=" -i $Volume_ID "
			}
			if($Count)
			{
				$CreateVVCmd +=" -cnt $Count "
				if($Shared)
				{
					if(!($tpvv))
					{
						$CreateVVCmd +=" -shared "
					}
				}
			}
			if($Wait)
			{
				if(!($tpvv))
				{
					$CreateVVCmd +=" -wait $Wait "
				}
			}
			if($Comment)
			{
				$CreateVVCmd +=" -comment $Comment "
			}
			if($Sectors_per_track)
			{
				$CreateVVCmd +=" -spt $Sectors_per_track "
			}
			if($Heads_per_cylinder)
			{
				$CreateVVCmd +=" -hpc $Heads_per_cylinder "
			}
			if($Snp_Cpg)
			{
				$CreateVVCmd +=" -snp_cpg $CPGName "
			}
			if($Snp_aw)
			{
				$CreateVVCmd +=" -snp_aw $Snp_aw "
			}
			if($Snp_al)
			{
				$CreateVVCmd +=" -snp_al $Snp_al "
			}
			
			$CreateVVCmd +=" $CPGName $vvName $Size"
			
			$Result1 = $Result2 = $Result3 = ""
			$Result1 = Invoke-CLICommand -Connection $SANConnection -cmds  $CreateVVCmd
			#write-host "Result = ",$Result1
			if([string]::IsNullOrEmpty($Result1))
			{
				$successmsg += "Success : Created vv $vvName"
			}
			else
			{
				$failuremsg += "FAILURE : While creating vv $vvName"
			}
			write-debuglog " Creating Virtual Name with the command --> $CreatevvCmd" "INFO:" 

			# If VolumeSet is specified then add vv to existing Volume Set
			if ($vvSetName)
			{
				## Check vvSet Name 
				##
				if ( !( Test-CLIObject -objectType 'vv set' -objectName $vvSetName -SANConnection $SANConnection))
				{
					write-debuglog " Volume Set $vvSetName does not exist. Use New-vVolumeSet to create a Volume set before creating vLUN" "INFO:" 
					$CreatevvSetCmd = "createvvset $vvSetName"
					$Result2 =Invoke-CLICommand -Connection $SANConnection -cmds  $CreatevvSetCmd
					if([string]::IsNullOrEmpty($Result2))
					{
						$successmsg += "Success : Created vvset $vvSetName"
					}
					else
					{
						$failuremsg += "FAILURE : While creating vvset $vvSetName"					
					}
					write-debuglog " Creating Volume set with the command --> $CreatevvSetCmd" "INFO:"
				}
				
				$AddVVCmd = "createvvset -add $vvSetName $vvName" 	## Add vv to existing Volume set
				$Result3 = Invoke-CLICommand -Connection $SANConnection -cmds  $AddVVCmd
				if([string]::IsNullOrEmpty($Result3))
				{
					$successmsg += "Success : vv $vvName added to vvset $vvSetName"
				}
				else
				{
					$failuremsg += "FAILURE : While adding vv $vvName to vvset $vvSetName"					
				}					
				write-debuglog " Adding vv to Volume set with the command --> $AddvvCmd" "INFO:"
			}
			if(([string]::IsNullOrEmpty($Result1)) -and ([string]::IsNullOrEmpty($Result2)) -and ([string]::IsNullOrEmpty($Result3)))
			{
				return $successmsg 
			}
			else
			{
				return $failuremsg
			}			
		}
		else
		{
			write-debugLog "No CPG Name specified for new virtual volume. Skip creating virtual volume" "ERR:" 
			return "FAILURE : No CPG name specified"
		}		
	}
	else
	{
		write-debugLog "No name specified for new virtual volume. Skip creating virtual volume" "ERR:"
		Get-help New-Vv
		return	
	}		 
} # End New-Vv

###################################################################################################
############################################# FUNCTION New-VvSet ##################################
###################################################################################################
Function New-VvSet
{
<#
  .SYNOPSIS
    Creates a new VolumeSet 
  
  .DESCRIPTION
	 Creates a new VolumeSet
        
  .EXAMPLE
    New-VvSet -vvSetName "MyVolumeSet"  
	Creates a VolumeSet named MyVolumeSet
		
  .EXAMPLE	
	New-VvSet -vvSetName "MYVolumeSet" -Domain MyDomain
	Creates a VolumeSet named MyVolumeSet in the domain MyDomain
	
  .EXAMPLE
 	New-VvSet -vvSetName "MYVolumeSet" -Domain MyDomain -vvName "MyVV"
	Creates a VolumeSet named MyVolumeSet in the domain MyDomain and adds VV "MyVV" to that vvset
	
  .EXAMPLE
	New-VvSet -vvSetName "MYVolumeSet" -vvName "MyVV"
	adds vv "MyVV"  to existing vvset "MyVolumeSet" if vvset exist, if not it will create vvset and adds vv to vvset
	
  .EXAMPLE
	New-VvSet -vvSetName asVVset2 -vvName "as4 as5 as6"
	
  .EXAMPLE
	New-VvSet -vvSetName set:asVVset3 -Add -vvName as3
	
  .PARAMETER vvSetName 
    Specify new name of the VolumeSet
	
  .PARAMETER Domain 
    Specify the domain where the Volume set will reside
  
  .PARAMETER vvName 
    Specify the VV  to add  to the Volume set 

  .PARAMETER Comment 
     Specifies any comment or additional information for the set.	
	
  .PARAMETER Count
	Add a sequence of <num> VVs starting with "vvname". vvname should
	be of the format <basename>.<int>
	For each VV in the sequence, the .<int> suffix of the vvname is
	incremented by 1.

  .PARAMETER Add 
	Specifies that the VVs listed should be added to an existing set. At
	least one VV must be specified.	
	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection	
              
  .Notes
    NAME:  New-VvSet 
    LASTEDIT: January 2020
    KEYWORDS: New-VvSet
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$vvSetName,
		
		[Parameter(Position=1, Mandatory=$false)]
		[switch]
		$Add,
		
		[Parameter(Position=2, Mandatory=$false)]
		[System.String]
		$Count,
		
		[Parameter(Position=3, Mandatory=$false)]
		[System.String]
		$Comment,
		
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$Domain,
		
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$vvName,
		
		[Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)		

	Write-DebugLog "Start: In New-VvSet - validating input values" $Debug 
	if (!($vvSetName))
	{
		Write-DebugLog "Stop: Exiting New-VvSet since no values specified for vvset" $Debug
		Get-Help New-VvSet
		return
	}
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
				Write-DebugLog "Stop: Exiting New-VvSet since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet New-VvSet since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli -SANConnection $SANConnection
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}
	
	$CreateVolumeSetCmd = "createvvset "
	
	if($Add) 
	{
		$CreateVolumeSetCmd += " -add "			
	}
	if($Count) 
	{
		$CreateVolumeSetCmd += " -cnt $Count "			
	}
	if($Comment) 
	{
		$CreateVolumeSetCmd += " -comment $Comment "			
	}
	if($Domain) 
	{
		$CreateVolumeSetCmd += " -domain $Domain "			
	}
	if($vvSetName) 
	{
		$CreateVolumeSetCmd += " $vvSetName "			
	}
	if($vvName)
	{
		$CreateVolumeSetCmd += " $vvName "
	}
	
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $CreateVolumeSetCmd
	if($Add)
	{
		if([string]::IsNullOrEmpty($Result))
		{
			return "Success : New-VvSet command executed vv : $vvName is added to vvSet : $vvSetName"
		}
		else
		{
			return $Result
		}
	}	
	else
	{
		if([string]::IsNullOrEmpty($Result))
		{
			return "Success : New-VvSet command executed vvSet : $vvSetName is created with vv : $vvName"
		}
		else
		{
			return $Result
		}			
	}		
	
} # End of New-VvSet

##########################################################################
######################### FUNCTION Remove-LD #########################
##########################################################################
Function Remove-LD()
{
<#
  .SYNOPSIS
   Remove-LD - Remove logical disks (LD).

  .DESCRIPTION
   The Remove-LD command removes a specified LD from the system service group.

  .EXAMPLE
   Remove-LD -LD_Name xxx

  .PARAMETER Pat
   Specifies glob-style patterns. All LDs matching the specified
   pattern are removed. By default, confirmation is required to proceed
   with the command unless the -f option is specified. This option must be
   used if the pattern specifier is used.

  .PARAMETER Dr
   Specifies that the operation is a dry run and no LDs are removed.

  .PARAMETER LD_Name
   Specifies the LD name, using up to 31 characters. Multiple LDs can be specified.

  .PARAMETER Rmsys
   Specifies that system resource LDs such as logging LDs and preserved
   data LDs are removed.

  .PARAMETER Unused
   Specifies the command to remove non-system LDs.
   This option cannot be used with the  -rmsys option.

  .Notes
    NAME: Remove-LD
    LASTEDIT January 2020
    KEYWORDS: Remove-LD
  
  .Link
    http://www.hpe.com

 #Requires PS -Version 3.0
#>
[CmdletBinding()]
 param(
	 [Parameter(Position=0, Mandatory=$false)]
	 [switch]
	 $Pat,

	 [Parameter(Position=1, Mandatory=$false)]
	 [switch]
	 $Dr,

	 [Parameter(Position=2, Mandatory=$false)]
	 [switch]
	 $Rmsys,

	 [Parameter(Position=3, Mandatory=$false)]
	 [switch]
	 $Unused,

	 [Parameter(Position=4, Mandatory=$True)]
	 [System.String]
	 $LD_Name,

	 [Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
	 $SANConnection = $global:SANConnection
 )

 Write-DebugLog "Start: In Remove-LD - validating input values" $Debug 
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
			Write-DebugLog "Connection object is null/empty or the array address (FQDN/IP Address) or user credentials in the connection object are either null or incorrect.  Create a valid connection object using New-CLIConnection or New-PoshSshConnection" " ERR: "
			Write-DebugLog "Stop: Exiting Remove-LD since SAN connection object values are null/empty" $Debug 
			Return "Unable to execute the cmdlet Remove-LD since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
		}
	}
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
	write-debuglog "$plinkresult"
	Return $plinkresult
 }

 $Cmd = " removeld -f "

 if($Pat)
 {
	$Cmd += " -pat "
 }

 if($Dr)
 {
	$Cmd += " -dr "
 }

 if($Rmsys)
 {
	$Cmd += " -rmsys "
 }

 if($Unused)
 {
	$Cmd += " -unused "
 }

 if($LD_Name)
 {
  $Cmd += " $LD_Name "
 }

 $Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd
 Write-DebugLog "Executing function : Remove-LD command -->" INFO:
 
 Return $Result
} ##  End-of Remove-LD

####################################################################################
############################### FUNCTION Remove-Vv #################################
####################################################################################

Function Remove-Vv
{
<#
  .SYNOPSIS
    Delete virtual volumes 
  
  .DESCRIPTION
	Delete virtual volumes         

  .EXAMPLE	
	Remove-Vv -vvName PassThru-Disk -whatif
	Dry-run of deleted operation on vVolume named PassThru-Disk
		
  .EXAMPLE	
	Remove-Vv -vvName VV1 -force -Snaponly
	
  .EXAMPLE	
	Remove-Vv -vvName VV1 -force -Expired
	
  .EXAMPLE		
	Remove-Vv -vvName PassThru-Disk -force
	Forcibly deletes vVolume named PassThru-Disk 
		
  .PARAMETER vvName 
    Specify name of the volume to be removed. 
	
  .PARAMETER whatif
    If present, perform a dry run of the operation and no VLUN is removed	
	
  .PARAMETER force
	If present, perform forcible delete operation
	
  .PARAMETER Pat
    Specifies that specified patterns are treated as glob-style patterns and that all VVs matching the specified pattern are removed.
	
  .PARAMETER Stale
	Specifies that all stale VVs can be removed.       

  .PARAMETER  Expired
	Remove specified expired volumes.
       
  .PARAMETER  Snaponly
	Remove the snapshot copies only.

  .PARAMETER Cascade
	Remove specified volumes and their descendent volumes as long as none has an active VLUN. 

  .PARAMETER Nowait
	Prevents command blocking that is normally in effect until the vv is removed. 
	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  Remove-Vv  
    LASTEDIT: January 2020
    KEYWORDS: Remove-Vv 
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
		[System.String]
		$vvName,

		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$whatif, 
		
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$force, 
		
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$Pat, 
		
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$Stale, 
		
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$Expired, 
		
		[Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$Snaponly, 
		
		[Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$Cascade, 
		
		[Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$Nowait, 
		
		[Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)		
	
	Write-DebugLog "Start: In Remove-Vv - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting Remove-Vv since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Remove-Vv since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli -SANConnection $SANConnection
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}
	if (!($vvName))
	{
		write-debuglog "no Virtual Volume name sprcified to remove." "INFO:"
		Get-help Remove-Vv
		return
	}
	if (!(($force) -or ($whatif)))
	{
		write-debuglog "no option selected to remove/dry run of vv, Exiting...." "INFO:"
		return "FAILURE : Specify -force or -whatif options to delete or delete dryrun of a virtual volume"
	}
	
	$ListofLuns = Get-VvList -vvName $vvName -SANConnection $SANConnection
	if($ListofLuns -match "FAILURE")
	{
		return "FAILURE : No vv $vvName found"
	}
	$ActionCmd = "removevv "
	if ($Nowait)
	{
		$ActionCmd += "-nowait "
	}
	if ($Cascade)
	{
		$ActionCmd += "-cascade "
	}
	if ($Snaponly)
	{
		$ActionCmd += "-snaponly "
	}
	if ($Expired)
	{
		$ActionCmd += "-expired "
	}
	if ($Stale)
	{
		$ActionCmd += "-stale "
	}
	if ($Pat)
	{
		$ActionCmd += "-pat "
	}
	if ($whatif)
	{
		$ActionCmd += "-dr "
	}
	else
	{
		$ActionCmd += "-f "
	}
	$successmsglist = @()
	
	if ($ListofLuns)
	{
		foreach ($vVolume in $ListofLuns)
		{
			$vName = $vVolume.Name
			if ($vName)
			{
				$RemoveCmds = $ActionCmd + " $vName $($vVolume.Lun)"
				$Result1 = Invoke-CLICommand -Connection $SANConnection -cmds  $removeCmds
				if( ! (Test-CLIObject -objectType "vv" -objectName $vName -SANConnection $SANConnection))
				{
					$successmsglist += "Success : Removing vv $vName"
				}
				else
				{
					$successmsglist += "FAILURE : $Result1"
				}

				write-debuglog "Removing Virtual Volumes with command $removeCmds" "INFO:" 
			}
		}
		return $successmsglist		
	}	
	else
	{
		Write-DebugLog "no Virtual Volume found for $vvName." $Info
		return "FAILURE : No vv $vvName found"
	}
} # END Remove-Vv

##########################################################################
################# FUNCTION Remove-Vv_Ld_Cpg_Templates ################
##########################################################################
Function Remove-Vv_Ld_Cpg_Templates()
{
<#
  .SYNOPSIS
   Remove-Vv_Ld_Cpg_Templates - Remove one or more templates from the system

  .DESCRIPTION
   The Remove-Vv_Ld_Cpg_Templates command removes one or more virtual volume (VV),
   logical disk (LD), and common provisioning group (CPG) templates.

  .EXAMPLE
   Remove-Vv_Ld_Cpg_Templates -Template_Name xxx

  .PARAMETER Template_Name
   Specifies the name of the template to be deleted, using up to 31
   characters. This specifier can be repeated to remove multiple templates
	
  .PARAMETER Pat
   The specified patterns are treated as glob-style patterns and that all
   templates matching the specified pattern are removed. By default,
   confirmation is required to proceed with the command unless the -f
   option is specified. This option must be used if the pattern specifier
   is used.

  .Notes
    NAME: Remove-Vv_Ld_Cpg_Templates
    LASTEDIT January 2020
    KEYWORDS: Remove-Vv_Ld_Cpg_Templates
  
  .Link
    http://www.hpe.com

 #Requires PS -Version 3.0
#>
[CmdletBinding()]
 param(
	[Parameter(Position=0, Mandatory=$false)]
	[System.String]
	$Template_Name,

	[Parameter(Position=1, Mandatory=$false)]
	[switch]
	$Pat,

	[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
	$SANConnection = $global:SANConnection
 )

 Write-DebugLog "Start: In Remove-Vv_Ld_Cpg_Templates - validating input values" $Debug 
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
			Write-DebugLog "Connection object is null/empty or the array address (FQDN/IP Address) or user credentials in the connection object are either null or incorrect.  Create a valid connection object using New-CLIConnection or New-PoshSshConnection" " ERR: "
			Write-DebugLog "Stop: Exiting Remove-Vv_Ld_Cpg_Templates since SAN connection object values are null/empty" $Debug 
			Return "Unable to execute the cmdlet Remove-Vv_Ld_Cpg_Templates since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
		}
	}
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
	write-debuglog "$plinkresult"
	Return $plinkresult
 }

	$Cmd = " removetemplate -f "

 if($Pat)
 {
	$Cmd += " -pat "
 }

 if($Template_Name)
 {
	$Cmd += " $Template_Name "
 }

 $Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd
 Write-DebugLog "Executing function : Remove-Vv_Ld_Cpg_Templates command -->" INFO: 
 
 Return $Result
} ##  End-of Remove-Vv_Ld_Cpg_Templates

############################################################################
########################## FUNCTION Remove-VvSet ###########################
############################################################################
Function Remove-VvSet
{
<#
  .SYNOPSIS
    Remove a Virtual Volume set or remove VVs from an existing set
  
  .DESCRIPTION
	Removes a VV set or removes VVs from an existing set.
        
  .EXAMPLE
    Remove-VvSet -vvsetName "MyVVSet"  -force
	 Remove a VV set "MyVVSet"
	 
  .EXAMPLE
	Remove-VvSet -vvsetName "MyVVSet" -vvName "MyVV" -force
	 Remove a single VV "MyVV" from a vvset "MyVVSet"
	
  .PARAMETER vvsetName 
    Specify name of the vvsetName

  .PARAMETER vvName 
    Specify name of  a vv to remove from vvset

  .PARAMETER force
	If present, perform forcible delete operation	
	
  .PARAMETER pat
	Specifies that both the set name and VVs will be treated as glob-style patterns.
	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  Remove-VvSet 
    LASTEDIT: January 2020
    KEYWORDS: Remove-VvSet
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$true)]
		[System.String]
		$vvsetName,
		
		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$vvName,
		
		[Parameter(Position=2, Mandatory=$false,ValueFromPipeline=$true)]
		[switch]
		$force,
		
		[Parameter(Position=3, Mandatory=$false,ValueFromPipeline=$true)]
		[switch]
		$Pat,
		
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)		

	Write-DebugLog "Start: In Remove-VvSet - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting Remove-VvSet since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Remove-VvSet since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli -SANConnection $SANConnection
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}	
	if ($vvsetName)
	{
		if (!($force))
		{
			write-debuglog "no force option is selected to remove vvset, Exiting...." "INFO:"
			return "FAILURE : no -force option is selected to remove vvset"
		}
		$objType = "vvset"
		$objMsg  = "vv set"
		
		## Check vvset Name 		
		if ( -not ( Test-CLIObject -objectType $objType -objectName $vvsetName -objectMsg $objMsg -SANConnection $SANConnection)) 
		{
			write-debuglog " vvset $vvsetName does not exist. Nothing to remove"  "INFO:"  
			return "FAILURE : No vvset $vvSetName found"
		}
		else
		{
			$RemovevvsetCmd ="removevvset "			
			
			if($force)
			{
				$RemovevvsetCmd += " -f "
			}
			if($Pat)
			{
				$RemovevvsetCmd += " -pat "
			}
			
			$RemovevvsetCmd += " $vvsetName "
			
			if($vvName)
			{
				$RemovevvsetCmd +=" $vvName"
			}
		
			$Result1 = Invoke-CLICommand -Connection $SANConnection -cmds  $RemovevvsetCmd
			write-debuglog " Removing vvset  with the command --> $RemovevvsetCmd" "INFO:" 
			if([string]::IsNullOrEmpty($Result1))
			{
				if($vvName)
				{
					return  "Success : Removed vv $vvName from vvset $vvSetName"
				}
				return  "Success : Removed vvset $vvSetName"
			}
			else
			{
				return "FAILURE : While removing vvset $vvSetName $Result1"
			}
		}	
	}
	else
	{
		write-debuglog  "No name mentioned for removing vvset" "INFO:"
		Get-help Remove-VvSet			
	}
	
} # End of Remove-VvSet

##########################################################################
####################### FUNCTION Set-Template ########################
##########################################################################
Function Set-Template()
{
<#
  .SYNOPSIS
   Set-Template - Add, modify or remove template properties

  .DESCRIPTION
   The Set-Template command modifies the properties of existing templates.

  .EXAMPLE
	In the following example, template vvtemp1 is modified to support the
	availability of data should a drive magazine fail (mag) and to use the
	the stale_ss policy:

	Set-Template -Option_Value " -ha mag -pol stale_ss v" -Template_Name vtemp1

  .EXAMPLE 
	In the following example, the -nrw and -ha mag options are added to the
	template template1, and the -t option is removed:

	Set-Template -Option_Value "-nrw -ha mag -remove -t" -Template_Name template1
   
  .PARAMETER Option_Value
	Indicates the specified options and their values (if any) are added to
	an existing template. The specified option replaces the existing option
	in the template. For valid options, refer to createtemplate command.

  .PARAMETER Template_Name
	Specifies the name of the template to be modified, using up to 31 characters.

  .PARAMETER Remove
   Indicates that the option(s) that follow -remove are removed from the
   existing template. When specifying an option for removal, do not specify
   the option's value. For valid options, refer to createtemplate command.

  .Notes
    NAME: Set-Template
    LASTEDIT January 2020
    KEYWORDS: Set-Template
  
  .Link
    http://www.hpe.com

 #Requires PS -Version 3.0
#>
[CmdletBinding()]
 param( 
	[Parameter(Position=0, Mandatory=$True)]
	[System.String]
	$Option_Value,

	[Parameter(Position=1, Mandatory=$True)]
	[System.String]
	$Template_Name,

	[Parameter(Position=2, Mandatory=$false)]
	[System.String]
	$Remove,

	[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
	$SANConnection = $global:SANConnection
 )

 Write-DebugLog "Start: In Set-Template - validating input values" $Debug 
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
			Write-DebugLog "Connection object is null/empty or the array address (FQDN/IP Address) or user credentials in the connection object are either null or incorrect.  Create a valid connection object using New-CLIConnection or New-PoshSshConnection" " ERR: "
			Write-DebugLog "Stop: Exiting Set-Template since SAN connection object values are null/empty" $Debug 
			Return "Unable to execute the cmdlet Set-Template since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
		}
	}
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
	write-debuglog "$plinkresult"
	Return $plinkresult
 }

 $Cmd = " settemplate -f "

 if($Remove)
 {
	$Cmd += " -remove $Remove "
 }

 if($Option_Value)
 {
	$Cmd += " $Option_Value "
 }

 if($Template_Name)
 {
  $Cmd += " $Template_Name "
 }

 $Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd
 Write-DebugLog "Executing function : Set-Template command -->" INFO:
 
 Return $Result
} ##  End-of Set-Template

##########################################################################
########################### FUNCTION Set-VvSpace #########################
##########################################################################
Function Set-VvSpace()
{
<#
  .SYNOPSIS
   Set-VvSpace - Free SA and SD space from a VV if they are not in use.

  .DESCRIPTION
   The Set-VvSpace command frees snapshot administration and snapshot data spaces
   from a Virtual Volume (VV) if they are not in use.

  .EXAMPLE
   Set-VvSpace -VV_Name xxx

  .PARAMETER Pat
   Remove the snapshot administration and snapshot data spaces from all the
   virtual volumes that match any of the specified glob-style patterns.

  .PARAMETER VV_Name
   Specifies the virtual volume name, using up to 31 characters.
   
  .Notes
    NAME: Set-VvSpace
    LASTEDIT January 2020
    KEYWORDS: Set-VvSpace
  
  .Link
    http://www.hpe.com

 #Requires PS -Version 3.0
#>
[CmdletBinding()]
 param(
	 [Parameter(Position=0, Mandatory=$false)]
	 [switch]
	 $Pat,

	 [Parameter(Position=1, Mandatory=$True)]
	 [System.String]
	 $VV_Name,

	 [Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
	 $SANConnection = $global:SANConnection
 )

 Write-DebugLog "Start: In Set-VvSpace - validating input values" $Debug 
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
				Write-DebugLog "Connection object is null/empty or the array address (FQDN/IP Address) or user credentials in the connection object are either null or incorrect.  Create a valid connection object using New-CLIConnection or New-PoshSshConnection" " ERR: "
				Write-DebugLog "Stop: Exiting Set-VvSpace since SAN connection object values are null/empty" $Debug 
				Return "Unable to execute the cmdlet Set-VvSpace since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
	  }
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
	write-debuglog "$plinkresult"
	Return $plinkresult
 }

	$Cmd = " freespace -f "

 if($Pat)
 {
	$Cmd += " -pat "
 }
 
 if($VV_Name)
 {
	$Cmd += " $VV_Name "
 }

 $Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd
 Write-DebugLog "Executing function : Set-VvSpace command -->" INFO: 
 Return $Result
 
} ##  End-of Set-VvSpace

##########################################################################
###################### FUNCTION Show-LdMappingToVvs ######################
##########################################################################
Function Show-LdMappingToVvs()
{
<#
  .SYNOPSIS
   Show-LdMappingToVvs - Show mapping from a logical disk to virtual volumes.

  .DESCRIPTION
   The Show-LdMappingToVvs command displays the mapping from a logical (LD) disk to
   virtual volumes (VVs).

  .EXAMPLE
	The following example displays the region of logical disk v0.usr.0 that is used for a virtual volume:
	Show-LdMappingToVvs -LD_Name v0.usr.0
   
  .PARAMETER LD_Name
   Specifies the logical disk name.
   
  .Notes
    NAME: Show-LdMappingToVvs
    LASTEDIT January 2020
    KEYWORDS: Show-LdMappingToVvs
  
  .Link
    http://www.hpe.com

 #Requires PS -Version 3.0
#>
[CmdletBinding()]
 param(
	[Parameter(Position=0, Mandatory=$True)]
	[System.String]
	$LD_Name,

	[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
	$SANConnection = $global:SANConnection
 )

 Write-DebugLog "Start: In Show-LdMappingToVvs - validating input values" $Debug 
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
			Write-DebugLog "Connection object is null/empty or the array address (FQDN/IP Address) or user credentials in the connection object are either null or incorrect.  Create a valid connection object using New-CLIConnection or New-PoshSshConnection" " ERR: "
			Write-DebugLog "Stop: Exiting Show-LdMappingToVvs since SAN connection object values are null/empty" $Debug 
			Return "Unable to execute the cmdlet Show-LdMappingToVvs since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
		}
	}
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
	write-debuglog "$plinkresult"
	Return $plinkresult
 }

	$Cmd = " showldmap "

 if($LD_Name)
 {
	$Cmd += " $LD_Name "
 }

 $Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd
 Write-DebugLog "Executing function : Show-LdMappingToVvs command -->" INFO: 
 if($Result.count -gt 1)
 {	
	$tempFile = [IO.Path]::GetTempFileName()
	$LastItem = $Result.Count  
		
	foreach ($S in  $Result[0..$LastItem] )
	{
		$s= [regex]::Replace($s,"^ ","")			
		$s= [regex]::Replace($s,"^ ","")
		$s= [regex]::Replace($s,"^ ","")			
		$s= [regex]::Replace($s,"^ ","")		
		$s= [regex]::Replace($s," +",",")			
		#$s= [regex]::Replace($s,"-","")			
		$s= $s.Trim()			
		
		Add-Content -Path $tempfile -Value $s				
	}
	Import-Csv $tempFile 
	del $tempFile	
 }
 else
 {			
	Return  $Result
 }
} ##  End-of Show-LdMappingToVvs

##########################################################################
############################# FUNCTION Show-RSV ##########################
##########################################################################
Function Show-RSV()
{
<#
  .SYNOPSIS
   Show-RSV - Show information about scsi reservations of virtual volumes (VVs).

  .DESCRIPTION
   The Show-RSV command displays SCSI reservation and registration information
   for Virtual Logical Unit Numbers (VLUNs) bound for a specified port.

  .EXAMPLE
  
  .PARAMETER VV_Name
   Specifies the virtual volume name, using up to 31 characters.
   
  .PARAMETER SCSI3
   Specifies that either SCSI-3 persistent reservation or SCSI-2
   reservation information is displayed. If this option is not specified,
   information about both scsi2 and scsi3 reservations will be shown.
   
  .PARAMETER SCSI2
   Specifies that either SCSI-3 persistent reservation or SCSI-2
   reservation information is displayed. If this option is not specified,
   information about both scsi2 and scsi3 reservations will be shown.

  .PARAMETER Host
   Displays reservation and registration information only for virtual
   volumes that are visible to the specified host.

  .Notes
  .Notes
    NAME: Show-RSV
    LASTEDIT January 2020
    KEYWORDS: Show-RSV
  
  .Link
    http://www.hpe.com

 #Requires PS -Version 3.0
#>
[CmdletBinding()]
 param(
	[Parameter(Position=0, Mandatory=$false)]
	[switch]
	$SCSI3,

	[Parameter(Position=1, Mandatory=$false)]
	[switch]
	$SCSI2,

	[Parameter(Position=2, Mandatory=$false)]
	[System.String]
	$Host,
	
	[Parameter(Position=3, Mandatory=$false)]
	[System.String]
	$VV_Name,

	[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
	$SANConnection = $global:SANConnection
 )

 Write-DebugLog "Start: In Show-RSV - validating input values" $Debug 
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
			Write-DebugLog "Connection object is null/empty or the array address (FQDN/IP Address) or user credentials in the connection object are either null or incorrect.  Create a valid connection object using New-CLIConnection or New-PoshSshConnection" " ERR: "
			Write-DebugLog "Stop: Exiting Show-RSV since SAN connection object values are null/empty" $Debug 
			Return "Unable to execute the cmdlet Show-RSV since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
		}
	}
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
   write-debuglog "$plinkresult"
   Return $plinkresult
 }

	$Cmd = " showrsv "

 if($SCSI3)
 {
	$Cmd += " -l scsi3 "
 }
 
  if($SCSI2)
 {
	$Cmd += " -l scsi2 "
 }

 if($Host)
 {
	$Cmd += " -host $Host "
 }
 
 if($VV_Name)
 {
	$Cmd += " $VV_Name "
 }

 $Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd
 Write-DebugLog "Executing function : Show-RSV command -->" INFO: 
 if($Result.count -gt 1)
 {	
	if($Result -match "SYNTAX" )
	{
		Return $Result
	}
	$tempFile = [IO.Path]::GetTempFileName()
	$LastItem = $Result.Count
		
	foreach ($S in  $Result[0..$LastItem] )
	{
		$s= [regex]::Replace($s,"^ ","")			
		$s= [regex]::Replace($s,"^ ","")
		$s= [regex]::Replace($s,"^ ","")			
		$s= [regex]::Replace($s,"^ ","")		
		$s= [regex]::Replace($s," +",",")			
		#$s= [regex]::Replace($s,"-","")			
		$s= $s.Trim()			
		
		Add-Content -Path $tempfile -Value $s				
	}
	Import-Csv $tempFile 
	del $tempFile	
 }
 else
 {			
	Return  $Result
 }
} ##  End-of Show-RSV

##########################################################################
####################### FUNCTION Show-Template #######################
##########################################################################
Function Show-Template()
{
<#
  .SYNOPSIS
   Show-Template - Show templates.

  .DESCRIPTION
   The Show-Template command displays existing templates that can be used for
   Virtual Volume (VV), Logical Disk (LD) Common Provisioning Group (CPG) creation.

  .EXAMPLE

  .PARAMETER T
   Specifies that the template type displayed is a VV, LD, or CPG template.

  .PARAMETER Fit
   Specifies that the properties of the template is displayed to fit within
   80 character lines.
   
  .PARAMETER Template_name_or_pattern
   Specifies the name of a template, using up to 31 characters or
    glob-style pattern for matching multiple template names. If not
    specified, all templates are displayed.

  .Notes
    NAME: Show-Template
    LASTEDIT January 2020
    KEYWORDS: Show-Template
  
  .Link
    http://www.hpe.com

 #Requires PS -Version 3.0
#>
[CmdletBinding()]
 param(
	[Parameter(Position=0, Mandatory=$false)]
	[System.String]
	$T,

	[Parameter(Position=1, Mandatory=$false)]
	[switch]
	$Fit,

	[Parameter(Position=2, Mandatory=$false)]
	[System.String]
	$Template_name_or_pattern,

	[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
	$SANConnection = $global:SANConnection
 )

 Write-DebugLog "Start: In Show-Template - validating input values" $Debug 
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
			Write-DebugLog "Connection object is null/empty or the array address (FQDN/IP Address) or user credentials in the connection object are either null or incorrect.  Create a valid connection object using New-CLIConnection or New-PoshSshConnection" " ERR: "
			Write-DebugLog "Stop: Exiting Show-Template since SAN connection object values are null/empty" $Debug 
			Return "Unable to execute the cmdlet Show-Template since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
		}
	}
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
	write-debuglog "$plinkresult"
	Return $plinkresult
 }

	$Cmd = " showtemplate "

 if($T)
 {
	$Val = "vv","cpg" ,"ld"
	if($Val -eq $T.ToLower())
	{
		$Cmd += " -t $T "			
	}
	else
	{
		return " Illegal template type LDA, must be either vv,cpg or ld "
	}
 }

 if($Fit)
 {
	$Cmd += " -fit "
 }

 if($Template_name_or_pattern)
 {
	$Cmd += " $Template_name_or_pattern "
 }

 $Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd
 Write-DebugLog "Executing function : Show-Template command -->" INFO: 
 if($Result.count -gt 1)
 {	
	if($Result -match "SYNTAX" )
	{
		Return $Result
	}
	$tempFile = [IO.Path]::GetTempFileName()
	$LastItem = $Result.Count
		
	foreach ($S in  $Result[0..$LastItem] )
	{
		$s= [regex]::Replace($s,"^ ","")			
		$s= [regex]::Replace($s,"^ ","")
		$s= [regex]::Replace($s,"^ ","")			
		$s= [regex]::Replace($s,"^ ","")		
		$s= [regex]::Replace($s," +",",")			
		#$s= [regex]::Replace($s,"-","")			
		$s= $s.Trim()			
		
		Add-Content -Path $tempfile -Value $s				
	}
	Import-Csv $tempFile 
	del $tempFile	
 }
 else
 {			
	Return  $Result
 }
} ##  End-of Show-Template

##########################################################################
##################### FUNCTION Show-VvMappedToPD #####################
##########################################################################
Function Show-VvMappedToPD()
{
<#
  .SYNOPSIS
   Show-VvMappedToPD - Show which virtual volumes are mapped to a physical disk (or a chunklet in that physical disk).

  .DESCRIPTION
   The Show-VvMappedToPD command displays the virtual volumes that are mapped to a
   particular physical disk.

  .EXAMPLE
   Show-VvMappedToPD -PD_ID 4

  .EXAMPLE
   Show-VvMappedToPD -Sum -PD_ID 4
  
  .EXAMPLE
   Show-VvMappedToPD -P -Nd 1 -PD_ID 4
  
  .PARAMETER PD_ID
   Specifies the physical disk ID using an integer. This specifier is not
	required if -p option is used, otherwise it must be used at least once
	on the command line.
  
  .PARAMETER Sum
   Shows number of chunklets used by virtual volumes for different
   space types for each physical disk.

  .PARAMETER P
   Specifies a pattern to select <PD_ID> disks.
   
   The following arguments can be specified as patterns for this option:
   An item is specified as an integer, a comma-separated list of integers,
   or a range of integers specified from low to high.

  .PARAMETER Nd
   Specifies one or more nodes. Nodes are identified by one or more
   integers (item). Multiple nodes are separated with a single comma
   (e.g. 1,2,3). A range of nodes is separated with a hyphen (e.g. 0-
   7). The primary path of the disks must be on the specified node(s).

  .PARAMETER St
   Specifies one or more PCI slots. Slots are identified by one or more
   integers (item). Multiple slots are separated with a single comma
   (e.g. 1,2,3). A range of slots is separated with a hyphen (e.g. 0-
   7). The primary path of the disks must be on the specified PCI
   slot(s).

  .PARAMETER Pt
   Specifies one or more ports. Ports are identified by one or more
   integers (item). Multiple ports are separated with a single comma
   (e.g. 1,2,3). A range of ports is separated with a hyphen (e.g. 0-
   4). The primary path of the disks must be on the specified port(s).

  .PARAMETER Cg
   Specifies one or more drive cages. Drive cages are identified by one
   or more integers (item). Multiple drive cages are separated with a
   single comma (e.g. 1,2,3). A range of drive cages is separated with
   a hyphen (e.g. 0-3). The specified drive cage(s) must contain disks.

  .PARAMETER Mg
   Specifies one or more drive magazines. The "1." or "0." displayed
   in the CagePos column of showpd output indicating the side of the
   cage is omitted when using the -mg option. Drive magazines are
   identified by one or more integers (item). Multiple drive magazines
   are separated with a single comma (e.g. 1,2,3). A range of drive
   magazines is separated with a hyphen(e.g. 0-7). The specified drive
   magazine(s) must contain disks.

  .PARAMETER Pn
   Specifies one or more disk positions within a drive magazine. Disk
   positions are identified by one or more integers (item). Multiple
   disk positions are separated with a single comma(e.g. 1,2,3). A
   range of disk positions is separated with a hyphen(e.g. 0-3). The
   specified position(s) must contain disks.

  .PARAMETER Dk
   Specifies one or more physical disks. Disks are identified by one or
   more integers(item). Multiple disks are separated with a single
   comma (e.g. 1,2,3). A range of disks is separated with a hyphen(e.g.
   0-3).  Disks must match the specified ID(s).

  .PARAMETER Tc_gt
   Specifies that physical disks with total chunklets greater than the
   number specified be selected.

  .PARAMETER Tc_lt
   Specifies that physical disks with total chunklets less than the
   number specified be selected.

  .PARAMETER Fc_gt
   Specifies that physical disks with free chunklets greater than the
   number specified be selected.

  .PARAMETER Fc_lt
   Specifies that physical disks with free chunklets less than the
   number specified be selected.

  .PARAMETER Devid
   Specifies that physical disks identified by their models be
   selected. Models can be specified in a comma-separated list.
   Models can be displayed by issuing the "showpd -i" command.

  .PARAMETER Devtype
   Specifies that physical disks must have the specified device type
   (FC for Fast Class, NL for Nearline, SSD for Solid State Drive)
   to be used. Device types can be displayed by issuing the "showpd"
   command.

  .PARAMETER Rpm
   Drives must be of the specified relative performance metric, as
   shown in the "RPM" column of the "showpd" command.
   The number does not represent a rotational speed for the drives
   without spinning media (SSD). It is meant as a rough estimation of
   the performance difference between the drive and the other drives
   in the system.  For FC and NL drives, the number corresponds to
   both a performance measure and actual rotational speed. For SSD
   drives, the number is to be treated as a relative performance
   benchmark that takes into account I/O's per second, bandwidth and
   access time.
   Disks that satisfy all of the specified characteristics are used.
   For example -p -fc_gt 60 -fc_lt 230 -nd 2 specifies all the disks that
   have greater than 60 and less than 230 free chunklets and that are
   connected to node 2 through their primary path.

  .PARAMETER Sortcol
   Sorts command output based on column number (<col>). Columns are
   numbered from left to right, beginning with 0. At least one column must
   be specified. In addition, the direction of sorting (<dir>) can be
   specified as follows:
	   inc
	   Sort in increasing order (default).
	   dec
	   Sort in decreasing order.
   Multiple columns can be specified and separated by a colon (:). Rows
   with the same information in them as earlier columns will be sorted
   by values in later columns.

  .Notes
    NAME: Show-VvMappedToPD
    LASTEDIT January 2020
    KEYWORDS: Show-VvMappedToPD
  
  .Link
    http://www.hpe.com

 #Requires PS -Version 3.0
#>
[CmdletBinding()]
 param(
	[Parameter(Position=0, Mandatory=$false)]
	[switch]
	$Sum,

	[Parameter(Position=1, Mandatory=$false)]
	[switch]
	$P,

	[Parameter(Position=2, Mandatory=$false)]
	[System.String]
	$Nd,

	[Parameter(Position=3, Mandatory=$false)]
	[System.String]
	$St,

	[Parameter(Position=4, Mandatory=$false)]
	[System.String]
	$Pt,

	[Parameter(Position=5, Mandatory=$false)]
	[System.String]
	$Cg,

	[Parameter(Position=6, Mandatory=$false)]
	[System.String]
	$Mg,

	[Parameter(Position=7, Mandatory=$false)]
	[System.String]
	$Pn,

	[Parameter(Position=8, Mandatory=$false)]
	[System.String]
	$Dk,

	[Parameter(Position=9, Mandatory=$false)]
	[System.String]
	$Tc_gt,

	[Parameter(Position=10, Mandatory=$false)]
	[System.String]
	$Tc_lt,

	[Parameter(Position=11, Mandatory=$false)]
	[System.String]
	$Fc_gt,

	[Parameter(Position=12, Mandatory=$false)]
	[System.String]
	$Fc_lt,

	[Parameter(Position=13, Mandatory=$false)]
	[System.String]
	$Devid,

	[Parameter(Position=14, Mandatory=$false)]
	[System.String]
	$Devtype,

	[Parameter(Position=15, Mandatory=$false)]
	[System.String]
	$Rpm,

	[Parameter(Position=16, Mandatory=$false)]
	[System.String]
	$Sortcol,

	[Parameter(Position=17, Mandatory=$false)]
	[System.String]
	$PD_ID,

	[Parameter(Position=18, Mandatory=$false, ValueFromPipeline=$true)]
	$SANConnection = $global:SANConnection
 )

 Write-DebugLog "Start: In Show-VvMappedToPD - validating input values" $Debug 
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
			Write-DebugLog "Connection object is null/empty or the array address (FQDN/IP Address) or user credentials in the connection object are either null or incorrect.  Create a valid connection object using New-CLIConnection or New-PoshSshConnection" " ERR: "
			Write-DebugLog "Stop: Exiting Show-VvMappedToPD since SAN connection object values are null/empty" $Debug 
			Return "Unable to execute the cmdlet Show-VvMappedToPD since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
		}
	}
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
	write-debuglog "$plinkresult"
	Return $plinkresult
 }

	$Cmd = " showpdvv "

 if($Sum)
 {
	$Cmd += " -sum "
 }

 if($P)
 {
	$Cmd += " -p "
 }

 if($Nd)
 {
	$Cmd += " -nd $Nd "
 }

 if($St)
 {
	$Cmd += " -st $St "
 }

 if($Pt)
 {
	$Cmd += " -pt $Pt "
 }

 if($Cg)
 {
	$Cmd += " -cg $Cg "
 }

 if($Mg)
 {
	$Cmd += " -mg $Mg "
 }

 if($Pn)
 {
	$Cmd += " -pn $Pn "
 }

 if($Dk)
 {
	$Cmd += " -dk $Dk "
 }

 if($Tc_gt)
 {
	$Cmd += " -tc_gt $Tc_gt "
 }

 if($Tc_lt)
 {
	$Cmd += " -tc_lt $Tc_lt "
 }

 if($Fc_gt)
 {
	$Cmd += " -fc_gt $Fc_gt "
 }

 if($Fc_lt)
 {
	$Cmd += " -fc_lt $Fc_lt "
 }

 if($Devid)
 {
	$Cmd += " -devid $Devid "
 }

 if($Devtype)
 {
	$Cmd += " -devtype $Devtype "
 }

 if($Rpm)
 {
	$Cmd += " -rpm $Rpm "
 }

 if($Sortcol)
 {
	$Cmd += " -sortcol $Sortcol "
 }
 
 if($PD_ID)
 {
  $Cmd += " PD_ID "
 }

 $Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd
 Write-DebugLog "Executing function : Show-VvMappedToPD command -->" INFO: 
 if($Result.count -gt 1)
 {
	if($Result -match "SYNTAX" )
	{
		Return $Result
	}
	$tempFile = [IO.Path]::GetTempFileName()
	$LastItem = $Result.Count
		
	foreach ($S in  $Result[0..$LastItem] )
	{
		$s= [regex]::Replace($s,"^ ","")			
		$s= [regex]::Replace($s,"^ ","")
		$s= [regex]::Replace($s,"^ ","")			
		$s= [regex]::Replace($s,"^ ","")		
		$s= [regex]::Replace($s," +",",")			
		#$s= [regex]::Replace($s,"-","")			
		$s= $s.Trim()			
		
		Add-Content -Path $tempfile -Value $s				
	}
	Import-Csv $tempFile 
	del $tempFile	
 }
 else
 {			
	Return  $Result
 }
} ##  End-of Show-VvMappedToPD

##########################################################################
####################### FUNCTION Show-VvMapping ######################
##########################################################################
Function Show-VvMapping()
{
<#
  .SYNOPSIS
   Show-VvMapping - Show mapping from the virtual volume to logical disks.

  .DESCRIPTION
   The Show-VvMapping command displays information about how virtual volume regions
   are mapped to logical disks.

  .EXAMPLE
   None.
   
  .PARAMETER VV_Name
   The virtual volume name.

  .Notes
    NAME: Show-VvMapping
    LASTEDIT January 2020
    KEYWORDS: Show-VvMapping
  
  .Link
    http://www.hpe.com

 #Requires PS -Version 3.0
#>
[CmdletBinding()]
 param(
	[Parameter(Position=0, Mandatory=$True)]
	[System.String]
	$VV_Name,

	[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
	$SANConnection = $global:SANConnection
 )

 Write-DebugLog "Start: In Show-VvMapping - validating input values" $Debug 
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
			Write-DebugLog "Connection object is null/empty or the array address (FQDN/IP Address) or user credentials in the connection object are either null or incorrect.  Create a valid connection object using New-CLIConnection or New-PoshSshConnection" " ERR: "
			Write-DebugLog "Stop: Exiting Show-VvMapping since SAN connection object values are null/empty" $Debug 
			Return "Unable to execute the cmdlet Show-VvMapping since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
		}
	}
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
	write-debuglog "$plinkresult"
	Return $plinkresult
 }

	$Cmd = " showvvmap "

 if($VV_Name)
 {
	$Cmd += " $VV_Name "
 }

 $Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd
 Write-DebugLog "Executing function : Show-VvMapping command -->" INFO: 
 if($Result.count -gt 1)
 {	
	if($Result -match "SYNTAX" )
	{
		Return $Result
	}
	$tempFile = [IO.Path]::GetTempFileName()
	$LastItem = $Result.Count
		
	foreach ($S in  $Result[0..$LastItem] )
	{
		$s= [regex]::Replace($s,"^ ","")			
		$s= [regex]::Replace($s,"^ ","")
		$s= [regex]::Replace($s,"^ ","")			
		$s= [regex]::Replace($s,"^ ","")		
		$s= [regex]::Replace($s," +",",")			
		#$s= [regex]::Replace($s,"-","")			
		$s= $s.Trim()			
		
		Add-Content -Path $tempfile -Value $s				
	}
	Import-Csv $tempFile 
	del $tempFile	
 }
 else
 {			
	Return  $Result
 }
} ##  End-of Show-VvMapping

##########################################################################
###################### FUNCTION Show-VvpDistribution #################
##########################################################################
Function Show-VvpDistribution()
{
<#
  .SYNOPSIS
   Show-VvpDistribution - Show virtual volume distribution across physical disks.

  .DESCRIPTION
   The Show-VvpDistribution command displays virtual volume (VV) distribution across physical
   disks (PD).

  .EXAMPLE
  
  .PARAMETER VV_Name
	Specifies the virtual volume with the specified name (31 character
	maximum) or matches the glob-style pattern for which information is
	displayed. This specifier can be repeated to display configuration
	information about multiple virtual volumes. This specifier is not
	required. If not specified, configuration information for all virtual
	volumes in the system is displayed.

  .PARAMETER Sortcol
   Sorts command output based on column number (<col>). Columns are
   numbered from left to right, beginning with 0. At least one column must
   be specified. In addition, the direction of sorting (<dir>) can be
   specified as follows:
	   inc
	   Sort in increasing order (default).
	   dec
	   Sort in decreasing order.
   Multiple columns can be specified and separated by a colon (:). Rows
   with the same information in them as earlier columns will be sorted
   by values in later columns.

  .Notes
    NAME: Show-VvpDistribution
    LASTEDIT January 20204
    KEYWORDS: Show-VvpDistribution
  
  .Link
    http://www.hpe.com

 #Requires PS -Version 3.0
#>
[CmdletBinding()]
 param(
	[Parameter(Position=0, Mandatory=$false)]
	[System.String]
	$Sortcol,

	[Parameter(Position=1, Mandatory=$false)]
	[System.String]
	$VV_Name,

	[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
	$SANConnection = $global:SANConnection
 )

 Write-DebugLog "Start: In Show-VvpDistribution - validating input values" $Debug 
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
			Write-DebugLog "Connection object is null/empty or the array address (FQDN/IP Address) or user credentials in the connection object are either null or incorrect.  Create a valid connection object using New-CLIConnection or New-PoshSshConnection" " ERR: "
			Write-DebugLog "Stop: Exiting Show-VvpDistribution since SAN connection object values are null/empty" $Debug 
			Return "Unable to execute the cmdlet Show-VvpDistribution since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
		}
	}
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
	write-debuglog "$plinkresult"
	Return $plinkresult
 }

	$Cmd = " showvvpd "

 if($Sortcol)
 {
	$Cmd += " -sortcol $Sortcol "
 }


 if($VV_Name)
 {
  $Cmd += " $VV_Name "
 }

 $Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd
 Write-DebugLog "Executing function : Show-VvpDistribution command -->" INFO: 
 if($Result.count -gt 1)
 {	
	if($Result -match "SYNTAX" )
	{
		Return $Result
	}
	$tempFile = [IO.Path]::GetTempFileName()
	$LastItem = $Result.Count
		
	foreach ($S in  $Result[0..$LastItem] )
	{
		$s= [regex]::Replace($s,"^ ","")			
		$s= [regex]::Replace($s,"^ ","")
		$s= [regex]::Replace($s,"^ ","")			
		$s= [regex]::Replace($s,"^ ","")		
		$s= [regex]::Replace($s," +",",")			
		#$s= [regex]::Replace($s,"-","")			
		$s= $s.Trim()			
		
		Add-Content -Path $tempfile -Value $s				
	}
	Import-Csv $tempFile 
	del $tempFile	
 }
 else
 {			
	Return  $Result
 }
} ##  End-of Show-VvpDistribution

##########################################################################
########################## FUNCTION Start-LD #########################
##########################################################################
Function Start-LD()
{
<#
  .SYNOPSIS
   Start-LD - Start a logical disk (LD).  

  .DESCRIPTION
   The Start-LD command starts data services on a LD that has not yet been
   started.

  .EXAMPLE
   Start-LD -LD_Name xxx

  .PARAMETER LD_Name
   Specifies the LD name, using up to 31 characters.

  .PARAMETER Ovrd
   Specifies that the LD is forced to start, even if some underlying
   data is missing.

  .Notes
    NAME: Start-LD
    LASTEDIT January 2020
    KEYWORDS: Start-LD
  
  .Link
    http://www.hpe.com

 #Requires PS -Version 3.0
#>
[CmdletBinding()]
 param(
	[Parameter(Position=0, Mandatory=$false)]
	[switch]
	$Ovrd,

	[Parameter(Position=1, Mandatory=$True)]
	[System.String]
	$LD_Name,

	[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
	$SANConnection = $global:SANConnection
 )

 Write-DebugLog "Start: In Start-LD - validating input values" $Debug 
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
			Write-DebugLog "Connection object is null/empty or the array address (FQDN/IP Address) or user credentials in the connection object are either null or incorrect.  Create a valid connection object using New-CLIConnection or New-PoshSshConnection" " ERR: "
			Write-DebugLog "Stop: Exiting Start-LD since SAN connection object values are null/empty" $Debug 
			Return "Unable to execute the cmdlet Start-LD since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
		}
	}
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
	write-debuglog "$plinkresult"
	Return $plinkresult
 }

	$Cmd = " startld "

 if($Ovrd)
 {
	$Cmd += " -ovrd "
 }

 if($LD_Name)
 {
	$Cmd += " $LD_Name "
 }

 $Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd
 Write-DebugLog "Executing function : Start-LD command -->" INFO: 
 
 Return $Result
} ##  End-of Start-LD

##########################################################################
######################### FUNCTION Start-Vv ##########################
##########################################################################
Function Start-Vv()
{
<#
  .SYNOPSIS
   Start-Vv - Start a virtual volume.

  .DESCRIPTION
   The Start-Vv command starts data services on a Virtual Volume (VV) that has
   not yet been started.

  .EXAMPLE
   Start-Vv

  .PARAMETER VV_Name
   Specifies the VV name, using up to 31 characters.
   
  .PARAMETER Ovrd
   Specifies that the logical disk is forced to start, even if some
   underlying data is missing.

  .Notes
    NAME: Start-Vv
    LASTEDIT January 2020
    KEYWORDS: Start-Vv
  
  .Link
    http://www.hpe.com

 #Requires PS -Version 3.0
#>
[CmdletBinding()]
 param(
	[Parameter(Position=0, Mandatory=$false)]
	[switch]
	$Ovrd,

	[Parameter(Position=1, Mandatory=$True)]
	[System.String]
	$VV_Name,

	[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
	$SANConnection = $global:SANConnection
 )

 Write-DebugLog "Start: In Start-Vv - validating input values" $Debug 
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
			Write-DebugLog "Connection object is null/empty or the array address (FQDN/IP Address) or user credentials in the connection object are either null or incorrect.  Create a valid connection object using New-CLIConnection or New-PoshSshConnection" " ERR: "
			Write-DebugLog "Stop: Exiting Start-Vv since SAN connection object values are null/empty" $Debug 
			Return "Unable to execute the cmdlet Start-Vv since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
		}
	}
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
	write-debuglog "$plinkresult"
	Return $plinkresult
 }

	$Cmd = " startvv "

 if($Ovrd)
 {
	$Cmd += " -ovrd "
 }

 if($VV_Name)
 {
	$Cmd += " $VV_Name "
 }

 $Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd
 Write-DebugLog "Executing function : Start-Vv command -->" INFO: 
 
 Return $Result
} ##  End-of Start-Vv

########################################################################
############################### FUNCTION Test-Vv #######################
########################################################################
Function Test-Vv
{
<#
  .SYNOPSIS
	The Test-Vv command executes validity checks of VV administration information in the event of an uncontrolled system shutdown and optionally repairs corrupted virtual volumes.   
   
  .DESCRIPTION
	The Test-Vv command executes validity checks of VV administration information in the event of an uncontrolled system shutdown
    and optionally repairs corrupted virtual volumes.
   
  .EXAMPLE
	Test-Vv -VVName XYZ

  .EXAMPLE
	Test-Vv -Yes -VVName XYZ
	
  .EXAMPLE
	Test-Vv -Offline -VVName XYZ

  .PARAMETER Yes
	Specifies that if errors are found they are either modified so they are valid (-y) or left unmodified (-n). If not specified, errors are left
	unmodified (-n).
	
  .PARAMETER No
	Specifies that if errors are found they are either modified so they are valid (-y) or left unmodified (-n). If not specified, errors are left
	unmodified (-n)

  .PARAMETER Offline
	Specifies that VVs specified by <VV_name> be offlined before validating the VV administration information. The entire VV tree will be
	offlined if this option is specified.

  .PARAMETER Dedup_Dryrun
	Launches a dedup ratio calculation task in the background that analyzes
	the potential space savings with Deduplication technology if the
	VVs specified were in a same deduplication group. The VVs specified
	can be TPVVs, compressed VVs and fully provisioned volumes.

  .PARAMETER Compr_Dryrun
	Launches a compression ratio calculation task in the background that analyzes
	the potential space savings with Compression technology of specified
	VVs. Specified volumes can be TPVVs, TDVVs, fully provisioned volumes
	and snapshots.
		
  .PARAMETER Fixsd
	Specifies that VVs specified by <VV_name> be checked for compressed data
	consistency. The entire tree will not be checked; only those VVs
	specified in the list will be checked.


  .PARAMETER Dedup_Compr_Dryrun
	Launches background space estimation task that analyzes the overall
	savings of converting the specified VVs into a compressed TDVVs.
	Specified volumes can be TPVVs, TDVVs, compressed TPVVs, fully
	provisioned volumes, and snapshots.

	This task will display compression and total savings ratios on a per-VV
	basis, and the dedup ratio will be calculated on a group basis of input VVs. 	
	
  .PARAMETER VVName       
	Requests that the integrity of the specified VV is checked. This
	specifier can be repeated to execute validity checks on multiple VVs.
	Only base VVs are allowed.
	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME: Test-Vv  
    LASTEDIT: January 2020
    KEYWORDS: Test-Vv 
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0
 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[switch]
		$Yes,	
		
		[Parameter(Position=1, Mandatory=$false)]
		[switch]
		$No,
		
		[Parameter(Position=2, Mandatory=$false)]
		[switch]
		$Offline,
		
		[Parameter(Position=3, Mandatory=$false)]
		[System.String]
		$VVName,

		[Parameter(Position=4, Mandatory=$false)]
		[switch]
		$Fixsd,
		
		[Parameter(Position=5, Mandatory=$false)]
		[switch]
		$Dedup_Dryrun,
		
		[Parameter(Position=6, Mandatory=$false)]
		[switch]
		$Compr_Dryrun,
		
		[Parameter(Position=7, Mandatory=$false)]
		[switch]
		$Dedup_Compr_Dryrun,
		
		[Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)		
	
	Write-DebugLog "Start: In Test-Vv - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting Test-Vv since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Test-Vv since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli -SANConnection $SANConnection
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}
	if($VVName)
	{		
		$cmd = "checkvv -f "	
			
		if($Yes)	
		{
			$cmd += " -y "
		}
		if($No)	
		{
			$cmd += " -n "
		}
		if($Offline)	
		{
			$cmd += " -offline "
		}
		if($Fixsd)	
		{
			$cmd += " -fixsd "
		}
		if($Dedup_Dryrun)	
		{
			$cmd += " -dedup_dryrun "
		}
		if($Compr_Dryrun)	
		{
			$cmd += " -compr_dryrun "
		}
		if($Dedup_Compr_Dryrun)	
		{
			$cmd += " -dedup_compr_dryrun "
		}
		
		$cmd += " $VVName"
		$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $cmd
		write-debuglog "  Executing Test-Vv Command.-->  " "INFO:" 
		return  "$Result"
	}
	else
	{
		write-debugLog "No VV Name specified ." "ERR:" 
		return "FAILURE : No VV name specified"
	} 
	
} ##  End-of  Test-Vv

##########################################################################
################### FUNCTION Update-SnapSpace ########################
##########################################################################
Function Update-SnapSpace()
{
<#
  .SYNOPSIS
   Update-SnapSpace - Update the snapshot space usage accounting.

  .DESCRIPTION
   The Update-SnapSpace command starts a non-cancelable task to update the
   snapshot space usage accounting. The snapshot space usage displayed by
   "showvv -hist" is not necessarily the current usage and the SpaceCalcTime
   column will show when it was last calculated.  This command causes the
   system to start calculating current snapshot space usage.  If one or more
   VV names or patterns are specified, only the specified VVs will be updated.
   If none are specified, all VVs will be updated.

  .EXAMPLE
   None.

  .Notes
    NAME: Update-SnapSpace
    LASTEDIT January 2020
    KEYWORDS: Update-SnapSpace
  
  .Link
    http://www.hpe.com

 #Requires PS -Version 3.0
#>
[CmdletBinding()]
 param( 
	[Parameter(Position=0, Mandatory=$false)]
	[System.String]
	$VV_Name,

	[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
	$SANConnection = $global:SANConnection
 )

 Write-DebugLog "Start: In Update-SnapSpace - validating input values" $Debug 
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
			Write-DebugLog "Connection object is null/empty or the array address (FQDN/IP Address) or user credentials in the connection object are either null or incorrect.  Create a valid connection object using New-CLIConnection or New-PoshSshConnection" " ERR: "
			Write-DebugLog "Stop: Exiting Update-SnapSpace since SAN connection object values are null/empty" $Debug 
			Return "Unable to execute the cmdlet Update-SnapSpace since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
		}
	}
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
	write-debuglog "$plinkresult"
	Return $plinkresult
 }

	$Cmd = " updatesnapspace "

 if($VV_Name)
 {
	$Cmd += " $VV_Name "
 }

 $Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd
 Write-DebugLog "Executing function : Update-SnapSpace command -->" INFO: 
 
 Return $Result
} ##  End-of Update-SnapSpace

##################################################################################
################################## FUNCTION Update-Vv ############################
##################################################################################
Function Update-Vv
{
<#
  .SYNOPSIS
   The Update-Vv command increases the size of a virtual volume.
   
  .DESCRIPTION
   The Update-Vv command increases the size of a virtual volume.
   
  .EXAMPLE
	Update-Vv -VVname XYZ -Size 1g
	
  .PARAMETER VVname     
	The name of the volume to be grown.
	
  .PARAMETER Size       
	Specifies the size in MB to be added to the volume user space. The size must be an integer in the range from 1 to 16T.

  .PARAMETER Option       
	Suppresses the requested confirmation before growing a virtual volume size from under 2 T to over2 T.
	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  Update-Vv
    LASTEDIT: January 2020
    KEYWORDS: Update-Vv
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0
 #>
[CmdletBinding()]
	param(
		
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$VVname ,		
		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$Size ,						
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       )		
	Write-DebugLog "Start: In Update-Vv  - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting Update-Vv since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Update-Vv since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}		
	$cmd= "growvv -f "
	
	if ($VVname)
	{		
		$cmd+=" $VVname "
	}
	else
	{
		Write-DebugLog "Stop: VVname  is mandatory" $Debug
		return "Error :  -VVname  is mandatory. "		
	}
	if ($Size)
	{
		$demo=$Size[-1]
		$de=" g | G | t | T "
		if($de -match $demo)
		{
			$cmd+=" $Size "
		}
		else
		{
			return "Error: -Size $Size is Invalid Try eg: 2G  "
		}
	}
	else
	{
		Write-DebugLog "Stop: Size  is mandatory" $Debug
		return "Error :  -Size  is mandatory. "
	}	
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $cmd
	write-debuglog "  Executing Update-Vv command increases the size of a virtual volume" "INFO:" 
	return  $Result
} #End-of Update-Vv

##########################################################################
################## FUNCTION Update-VvProperties ######################
##########################################################################
Function Update-VvProperties()
{
<#
  .SYNOPSIS
   Update-VvProperties - Change the properties associated with a virtual volume.

  .DESCRIPTION
   The Update-VvProperties command changes the properties associated with a virtual volume. Use
   the Update-VvProperties to modify volume names, volume policies, allocation warning and
   limit levels, and the volume's controlling common provisioning group (CPG).

  .EXAMPLE  
	The following example sets the policy of virtual volume vv1 to no_stale_ss.
	Update-VvProperties -Pol "no_stale_ss" -Vvname vv1

  .EXAMPLE
	Use the command to change the name:
	cli% setvv -name newtest test

  .EXAMPLE
	The following example modifies the WWN of virtual volume vv1
	Update-VvProperties -Wwn "50002AC0001A0024" -Vvname vv1

  .EXAMPLE
	The following example modifies the udid value for virtual volume vv1.
	Update-VvProperties -Udid "1715" -Vvname vv1
  
  .PARAMETER Vvname  
	Specifies the virtual volume name or all virtual volumes that match the
	pattern specified, using up to 31 characters. The patterns are glob-
	style patterns (see help on sub, globpat). Valid characters include
	alphanumeric characters, periods, dashes, and underscores.

  .PARAMETER Name
   Specifies that the name of the virtual volume be changed to a new name (
   as indicated by the <new_name> specifier) that uses up to 31 characters.

  .PARAMETER Wwn
   Specifies that the WWN of the virtual volume be changed to a new WWN as
   indicated by the <new_wwn> specifier. If <new_wwn> is set to "auto", the
   system will automatically choose the WWN based on the system serial
   number, the volume ID, and the wrap counter. This option is not allowed
   for the admitted volume before it is imported, or while the import process
   is taking place.
   
   Only one of the following three options can be specified:

  .PARAMETER Udid
   Specifies the user defined identifier for VVs for OpenVMS hosts. Udid
   value should be between 0 to 65535 and can be identical for several VVs.

  .PARAMETER Clrrsv
   Specifies that all reservation keys (i.e. registrations) and all
   persistent reservations on the virtual volume are cleared.

  .PARAMETER Clralua
   Restores ALUA state of the virtual volume to ACTIVE/OPTIMIZED state.
   In ACTIVE/OPTIMIZED state hosts will have complete access to the volume.

  .PARAMETER Exp
   Specifies the relative time from the current time that volume will
   expire. <time> is a positive integer value and in the range of
   1 minute - 1825 days. Time can be specified in days, hours, or
   minutes.  Use "d" or "D" for days, "h" or "H" for hours, or "m" or "M"
   for minutes following the entered time value.
   To remove the expiration time for the volume, enter 0 for <time>.

  .PARAMETER Comment
   Specifies any additional information up to 511 characters for the
   volume. Use -comment "" to remove the comments.

  .PARAMETER Retain
   Specifies the amount of time, relative to the current time, that the
   volume will be retained. <time> is a positive integer value and in the
   range of 1 minute - 1825 days. Time can be specified in days, hours, or
   minutes.  Use "d" or "D" for days, "h" or "H" for hours, or "m" or "M"
   for minutes following the entered time value.
   Note: If the volume is not in any domain, then its retention time
   cannot exceed the value of the system's VVRetentionTimeMax. The default
   value for the system's VVRetentionTimeMax is 14 days. If the volume
   belongs to a domain, then its retention time cannot exceed the value of
   the domain's VVRetentionTimeMax, if set. The retention time cannot be
   removed or reduced once it is set. If the volume has its retention time
   set, it cannot be removed within its retention time. If both expiration
   time and retention time are specified, then the retention time cannot
   be longer than the expiration time.
   This option requires the Virtual Lock license. Contact your
   local service provider for more information.

  .PARAMETER Pol
   Specifies the following policies that the created virtual volume follows.
   
  .PARAMETER Snp_cpg
   Specifies that the volume snapshot space is to be provisioned from the
   specified CPG. If no snp_cpg is currently defined, or no snapshots exist
   for the volume, the snp_cpg may be set to any CPG.

  .PARAMETER Snp_aw
   Enables a snapshot space allocation warning. A warning alert is
   generated when the reserved snapshot space of the VV
   exceeds the indicated percentage of the VV size.

  .PARAMETER Snp_al
   Sets a snapshot space allocation limit. The snapshot space of the
   VV is prevented from growing beyond the indicated
   percentage of the virtual volume size.
  
  The following options can only be used on thinly provisioned volumes:

  .PARAMETER Usr_aw
   This option enables user space allocation warning. Generates a warning
   alert when the user data space of the TPVV exceeds the specified
   percentage of the virtual volume size.

  .PARAMETER Usr_al
   Indicates the user space allocation limit. The user space of the TPVV
   is prevented from growing beyond the indicated percentage of the virtual
   volume size. After this limit is reached, any new writes to the virtual
   volume will fail.

  .PARAMETER Spt
   Defines the virtual volume geometry sectors per track value that is
   reported to the hosts through the SCSI mode pages. The valid range is
   between 4 to 8192 and the default value is 304.

  .PARAMETER Hpc
   Allows you to define the virtual volume geometry heads per cylinder
   value that is reported to the hosts though the SCSI mode pages. The
   valid range is between 1 to 255 and the default value is 8.

  .Notes
    NAME: Update-VvProperties
    LASTEDIT January 2020
    KEYWORDS: Update-VvProperties
  
  .Link
    http://www.hpe.com

 #Requires PS -Version 3.0
#>
[CmdletBinding()]
 param(
	[Parameter(Position=0, Mandatory=$false)]
	[System.String]
	$Name,

	[Parameter(Position=1, Mandatory=$false)]
	[System.String]
	$Wwn,

	[Parameter(Position=2, Mandatory=$false)]
	[System.String]
	$Udid,

	[Parameter(Position=3, Mandatory=$false)]
	[switch]
	$Clrrsv,

	[Parameter(Position=4, Mandatory=$false)]
	[switch]
	$Clralua,

	[Parameter(Position=5, Mandatory=$false)]
	[System.String]
	$Exp,

	[Parameter(Position=6, Mandatory=$false)]
	[System.String]
	$Comment,

	[Parameter(Position=7, Mandatory=$false)]
	[System.String]
	$Retain,

	[Parameter(Position=8, Mandatory=$false)]
	[System.String]
	$Pol,

	[Parameter(Position=9, Mandatory=$false)]
	[System.String]
	$Snp_cpg,

	[Parameter(Position=10, Mandatory=$false)]
	[System.String]
	$Snp_aw,

	[Parameter(Position=11, Mandatory=$false)]
	[System.String]
	$Snp_al,

	[Parameter(Position=12, Mandatory=$false)]
	[System.String]
	$Usr_aw,

	[Parameter(Position=13, Mandatory=$false)]
	[System.String]
	$Usr_al,

	[Parameter(Position=14, Mandatory=$false)]
	[System.String]
	$Spt,

	[Parameter(Position=15, Mandatory=$false)]
	[System.String]
	$Hpc,

	[Parameter(Position=16, Mandatory=$True)]
	[System.String]
	$Vvname,

	[Parameter(Position=17, Mandatory=$false, ValueFromPipeline=$true)]
	$SANConnection = $global:SANConnection
 )

 Write-DebugLog "Start: In Update-VvProperties - validating input values" $Debug 
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
			Write-DebugLog "Connection object is null/empty or the array address (FQDN/IP Address) or user credentials in the connection object are either null or incorrect.  Create a valid connection object using New-CLIConnection or New-PoshSshConnection" " ERR: "
			Write-DebugLog "Stop: Exiting Update-VvProperties since SAN connection object values are null/empty" $Debug 
			Return "Unable to execute the cmdlet Update-VvProperties since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
		}
	}
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
	write-debuglog "$plinkresult"
	Return $plinkresult
 }

 $Cmd = " setvv -f "

 if($Name)
 {
	$Cmd += " -name $Name "
 }

 if($Wwn)
 {
	$Cmd += " -wwn $Wwn "
 }

 if($Udid)
 {
	$Cmd += " -udid $Udid "
 }

 if($Clrrsv)
 {
	$Cmd += " -clrrsv "
 }

 if($Clralua)
 {
	$Cmd += " -clralua "
 }

 if($Exp)
 {
	$Cmd += " -exp $Exp "
 }

 if($Comment)
 {
	$Cmd += " -comment $Comment "
 }

 if($Retain)
 {
	$Cmd += " -retain $Retain "
 }

 if($Pol)
 {
	$Cmd += " -pol $Pol "
 }

 if($Snp_cpg)
 {
	$Cmd += " -snp_cpg $Snp_cpg "
 }

 if($Snp_aw)
 {
	$Cmd += " -snp_aw $Snp_aw "
 }

 if($Snp_al)
 {
	$Cmd += " -snp_al $Snp_al "
 }

 if($Usr_aw)
 {
	$Cmd += " -usr_aw $Usr_aw "
 }

 if($Usr_al)
 {
	$Cmd += " -usr_al $Usr_al "
 }

 if($Spt)
 {
	$Cmd += " -spt $Spt "
 }

 if($Hpc)
 {
	$Cmd += " -hpc $Hpc "
 }

 if($Pol)
 {
	$Cmd += " -pol $Pol "
 }

 if($Vvname)
 {
  $Cmd += " $Vvname "
 }

 $Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd
 Write-DebugLog "Executing function : Update-VvProperties command -->" INFO:
 
 Return $Result
} ##  End-of Update-VvProperties

##########################################################################
###################### FUNCTION Update-VvSetProperties ###################
##########################################################################
Function Update-VvSetProperties()
{
<#
  .SYNOPSIS
   Update-VvSetProperties - set parameters for a Virtual Volume set

  .DESCRIPTION
   The Update-VvSetProperties command sets the parameters and modifies the properties of
   a Virtual Volume(VV) set.

  .EXAMPLE
   Update-VvSetProperties
  
  .PARAMETER Setname
   Specifies the name of the vv set to modify.

  .PARAMETER Comment
   Specifies any comment or additional information for the set. The
   comment can be up to 255 characters long. Unprintable characters are
   not allowed.

  .PARAMETER Name
   Specifies a new name for the VV set using up to 27 characters.

  .Notes
    NAME: Update-VvSetProperties
    LASTEDIT January 2020
    KEYWORDS: Update-VvSetProperties
  
  .Link
    http://www.hpe.com

 #Requires PS -Version 3.0
#>
[CmdletBinding()]
 param(
	[Parameter(Position=0, Mandatory=$false)]
	[System.String]
	$Comment,

	[Parameter(Position=1, Mandatory=$false)]
	[System.String]
	$Name,

	[Parameter(Position=2, Mandatory=$True)]
	[System.String]
	$Setname,

	[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
	$SANConnection = $global:SANConnection
 )

 Write-DebugLog "Start: In Update-VvSetProperties - validating input values" $Debug 
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
			Write-DebugLog "Connection object is null/empty or the array address (FQDN/IP Address) or user credentials in the connection object are either null or incorrect.  Create a valid connection object using New-CLIConnection or New-PoshSshConnection" " ERR: "
			Write-DebugLog "Stop: Exiting Update-VvSetProperties since SAN connection object values are null/empty" $Debug 
			Return "Unable to execute the cmdlet Update-VvSetProperties since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
		}
	}
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
	write-debuglog "$plinkresult"
	Return $plinkresult
 }

	$Cmd = " setvvset "

 if($Comment)
 {
	$Cmd += " -comment $Comment "
 }

 if($Name)
 {
	$Cmd += " -name $Name "
 }

 if($Setname)
 {
	$Cmd += " Setname "
 }

 $Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd
 Write-DebugLog "Executing function : Update-VvSetProperties command -->" INFO: 
 
 Return $Result
} ##  End-of Update-VvSetProperties

############################################################################################################################################
## FUNCTION Set-Host
############################################################################################################################################
Function Set-Host
{
<#
  .SYNOPSIS
     Add WWN or iSCSI name to an existing host.
  
  .DESCRIPTION
	  Add WWN or iSCSI name to an existing host.
        
  .EXAMPLE
    Set-Host -hostName HV01A -Address  10000000C97B142E, 10000000C97B142F
	Adds WWN 10000000C97B142E, 0000000C97B142F to host HV01A
	
  .EXAMPLE	
	Set-Host -hostName HV01B  -iSCSI:$true -Address  iqn.1991-06.com.microsoft:dt-391-xp.hq.3par.com
	Adds iSCSI  iqn.1991-06.com.microsoft:dt-391-xp.hq.3par.com to host HV01B
	
  .EXAMPLE
    Set-Host -hostName HV01A  -Domain D_Aslam
	
  .EXAMPLE
    Set-Host -hostName HV01A  -Add
	
  .PARAMETER hostName
    Name of an existing host

  .PARAMETER Address
    Specify the list of WWNs for the new host

  .PARAMETER iSCSI
    If present, the address provided is an iSCSI address instead of WWN
	
  .PARAMETER Add
	Add the specified WWN(s) or iscsi_name(s) to an existing host (at least one WWN or iscsi_name must be specified).  Do not specify host persona.

  .PARAMETER Domain <domain | domain_set>
	Create the host in the specified domain or domain set.
		
  .PARAMETER Loc <location>
	Specifies the host's location.

  .PARAMETER  IP <IP address>
	Specifies the host's IP address.

  .PARAMETER  OS <OS>
	Specifies the operating system running on the host.

  .PARAMETER Model <model>
	Specifies the host's model.

  .PARAMETER  Contact <contact>
	Specifies the host's owner and contact information.

  .PARAMETER  Comment <comment>
	Specifies any additional information for the host.
		
  .PARAMETER  Persona <hostpersonaval>
	Sets the host persona that specifies the personality for all ports which are part of the host set.  

  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  Set-Host  
    LASTEDIT: January 2020
    KEYWORDS: Set-Host
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(		
		
		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$hostName,		
		
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String[]]
        $Address,
		
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
        $iSCSI=$false,
		
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
        $Add,
		
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String[]]
        $Domain,
		
		[Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String[]]
        $Loc,
		
		[Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String[]]
        $IP,
		
		[Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String[]]
        $OS,
		
		[Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String[]]
        $Model,
		
		[Parameter(Position=10, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String[]]
        $Contact,
		
		[Parameter(Position=11, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String[]]
        $Comment,
		
		[Parameter(Position=12, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String[]]
        $Persona,
		
		[Parameter(Position=13, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)		
	
	Write-DebugLog "Start: In Set-Host - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting Set-Host since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Set-Host since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli -SANConnection $SANConnection
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}      
	if ($hostName)
	{
		#$objType = "host"
		#$objMsg  = "hosts"
				
		$SetHostCmd = "createhost -f "			 
		if ($iSCSI)
		{ 
			$SetHostCmd +=" -iscsi "
		}
		if($Add)
		{
			$SetHostCmd +=" -add "
		}
		if($Domain)
		{
			$SetHostCmd +=" -domain $Domain"
		}
		if($Loc)
		{
			$SetHostCmd +=" -loc $Loc"
		}
		if($Persona)
		{
			$SetHostCmd +=" -persona $Persona"
		}
		if($IP)
		{
			$SetHostCmd +=" -ip $IP"
		}
		if($OS)
		{
			$SetHostCmd +=" -os $OS"
		}
		if($Model)
		{
			$SetHostCmd +=" -model $Model"
		}
		if($Contact)
		{
			$SetHostCmd +=" -contact $Contact"
		}
		if($Comment)
		{
			$SetHostCmd +=" -comment $Comment"
		}
		
		$Addr = [string]$Address
		$SetHostCmd +=" $hostName $Addr"
		
		$Result1 = Invoke-CLICommand -Connection $SANConnection -cmds  $SetHostCmd
		write-debuglog " Setting  Host with the command --> $SetHostCmd" "INFO:"
		if([string]::IsNullOrEmpty($Result1))
		{
			return "Success : Set host $hostName with Optn_Iscsi $Optn_Iscsi $Addr "
		}
		else
		{
			return $Result1
		}		
				
	}
	else
	{
		write-debugLog "No name specified for host. Skip updating  host" "ERR:"
		Get-help Set-Host
		return	
	} 
} # End Set-Host

######################################################################################################################
## FUNCTION Show-Peer
######################################################################################################################
Function Show-Peer
{
<#
  .SYNOPSIS   
	The Show-Peer command displays the arrays connected through the host ports or peer ports over the same fabric.
		
  .DESCRIPTION  
	The Show-Peer command displays the arrays connected through the
    host ports or peer ports over the same fabric. The Type field
    specifies the connectivity type with the array. The Type value
    of Slave means the array is acting as a source, the Type value
    of Master means the array is acting as a destination, the type
    value of Peer means the array is acting as both source and
    destination.
   
  .EXAMPLE	
	Show-Peer
	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
	NAME: Show-Peer
	LASTEDIT: March 2020
	KEYWORDS: Show-Peer
   
	.Link
		http://www.hpe.com
 
 #Requires PS -Version 3.0
 #>
[CmdletBinding()]
	param(	
		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)		
	
	Write-DebugLog "Start: In Show-Peer - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting Show-Peer since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Show-Peer since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli -SANConnection $SANConnection
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}	
	$cmd = " showpeer"
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $cmd
	write-debuglog "  Executing Show-Peer Command.-->" "INFO:"
	if($Result -match "No peers")
	{
		return $Result
	}
	else
	{
		$tempFile = [IO.Path]::GetTempFileName()
		$LastItem = $Result.Count  
		#Write-Host " Result Count =" $Result.Count
		foreach ($s in  $Result[0..$LastItem] )
		{		
			$s= [regex]::Replace($s,"^ ","")			
			$s= [regex]::Replace($s," +",",")	
			$s= [regex]::Replace($s,"-","")
			$s= $s.Trim() 	
			Add-Content -Path $tempFile -Value $s
			#Write-Host	" First if statement $s"		
		}
		Import-Csv $tempFile 
		del $tempFile
	}
	if($Result -match "No peers")
	{	
		return $Result			
	}
	else
	{
		return  " Success : Executing Show-Peer "			 		
	}		
	
} ##  End-of  Show-Peer

##########################################################################
######################### FUNCTION Resize-Vv ########################
##########################################################################
Function Resize-Vv()
{
<#
  .SYNOPSIS
   Resize-Vv - Consolidate space in virtual volumes (VVs). (HIDDEN)

  .EXAMPLE
	Resize-Vv -VVName testv
	
  .PARAMETER VVName
	Specifies the name of the VV.
  
  .PARAMETER PAT
	Compacts VVs that match any of the specified patterns. This option must be used if the pattern specifier is used.

  .Notes
    NAME: Resize-Vv
    LASTEDIT : March 2020
    KEYWORDS: Resize-Vv
  
  .Link
    http://www.hpe.com

 #Requires PS -Version 3.0
#>
[CmdletBinding()]
	param(
	[Parameter(Position=0, Mandatory=$true)]
	[System.String]
	$VVName,
	
	[Parameter(Position=1, Mandatory=$false)]
	[switch]
	$PAT,
	
	[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
	$SANConnection = $global:SANConnection
 )

 Write-DebugLog "Start: In Resize-Vv - validating input values" $Debug 
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
			Write-DebugLog "Connection object is null/empty or the array address (FQDN/IP Address) or user credentials in the connection object are either null or incorrect.  Create a valid connection object using New-CLIConnection or New-PoshSshConnection" " ERR: "
			Write-DebugLog "Stop: Exiting Resize-Vv since SAN connection object values are null/empty" $Debug 
			Return "Unable to execute the cmdlet Resize-Vv since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
		}
	}
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
   write-debuglog "$plinkresult"
   Return $plinkresult
 }
 
	$Cmd = " compactvv -f "

 if($PAT)
 {
	$Cmd += " -pat "
 }
 
 if($VVName)
 {
	$Cmd += " $VVName "
 }

 $Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd
 Write-DebugLog "Executing Function : Resize-Vv Command -->" INFO: 
 
 Return $Result
 
} ##  End-of Resize-Vv

Export-ModuleMember Add-Vv , Compress-LD , Find-LD , Get-LD , Get-LDChunklet , Get-Space , Get-Vv , Get-VvList , Get-VvSet , Import-Vv , New-Vv ,
New-VvSet , Remove-LD , Remove-Vv , Remove-Vv_Ld_Cpg_Templates , Remove-VvSet , Set-Template , Set-VvSpace , Show-LdMappingToVvs , Show-RSV ,
Show-Template , Show-VvMappedToPD , Show-VvMapping , Show-VvpDistribution , Start-LD , Start-Vv , Test-Vv , Update-SnapSpace , Update-Vv , 
Update-VvProperties , Update-VvSetProperties , Set-Host , Show-Peer , Resize-Vv