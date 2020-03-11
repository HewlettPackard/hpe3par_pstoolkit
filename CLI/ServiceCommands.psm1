####################################################################################
## 	© 2019,2020 Hewlett Packard Enterprise Development LP
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
##	File Name:		ServiceCommands.psm1
##	Description: 	Service Commands cmdlets 
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
## FUNCTION Test-3parObject
############################################################################################################################################
Function Test-3parobject 
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
	
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $Cmds
	if ($Result -like "no $ObjectMsg listed")
	{
		$IsObjectExisted = $false
	}
	return $IsObjectExisted
	
} # End FUNCTION Test-3parObject

##########################################################################
######################## FUNCTION Add-Hardware #######################
##########################################################################
Function Add-Hardware()
{
<#
  .SYNOPSIS
   Add-Hardware - Admit new hardware into the system.

  .DESCRIPTION
   The Add-Hardware command admits new hardware into the system. If new disks
   are discovered on any two-node HPE StoreServ system, tunesys will be
   started automatically to redistribute existing volumes to use the new
   capacity. This facility can be disabled using either the -notune
   option or setting the AutoAdmitTune system parameter to "no". On
   systems with more than two nodes, tunesys must always be run manually
   after disk installation.

  .EXAMPLE

  .PARAMETER Checkonly
   Only performs passive checks; does not make any changes.

  .PARAMETER F
   If errors are encountered, the Add-Hardware command ignores them and
   continues. The messages remain displayed.

  .PARAMETER Nopatch
   Suppresses the check for drive table update packages for new
   hardware enablement.

  .PARAMETER Tune
   Always run tunesys to rebalance the system after new disks are
   discovered.

  .PARAMETER Notune
   Do not automatically run tunesys to rebalance the system after new
   disks are discovered.

  .Notes
    NAME: Add-Hardware
    LASTEDIT December 2019
    KEYWORDS: Add-Hardware
  
  .Link
    Http://www.hpe.com

 #Requires PS -Version 3.0
#>
[CmdletBinding()]
 param(
	[Parameter(Position=0, Mandatory=$false)]
	[switch]
	$Checkonly,

	[Parameter(Position=1, Mandatory=$false)]
	[switch]
	$F,

	[Parameter(Position=2, Mandatory=$false)]
	[switch]
	$Nopatch,

	[Parameter(Position=3, Mandatory=$false)]
	[switch]
	$Tune,

	[Parameter(Position=4, Mandatory=$false)]
	[switch]
	$Notune,

	[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
	$SANConnection = $global:SANConnection
 )

 Write-DebugLog "Start: In Add-Hardware - validating input values" $Debug 
 #check if connection object contents are null/empty
 if(!$SANConnection)
 {
	#check if connection object contents are null/empty
	$Validate1 = Test-ConnectionObject $SANConnection
	if($Validate1 -eq "Failed")
	{
		#check if global connection object contents are null/empty
		$Validate2 = Test-ConnectionObject $global:SANConnection
		if($Validate2 -eq "Failed")
		{
			Write-DebugLog "Connection object is null/empty or Connection object UserName,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" " ERR: "
			Write-DebugLog "Stop: Exiting Add-Hardware since SAN connection object values are null/empty" $Debug 
			Return "FAILURE : Exiting Add-Hardware since SAN connection object values are null/empty"
		}
	}
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
	write-debuglog "$plinkresult"
	Return $plinkresult
 }

	$Cmd = " admithw "

 if($Checkonly)
 {
	$Cmd += " -checkonly "
 }

 if($F)
 {
	$Cmd += " -f "
 }

 if($Nopatch)
 {
	$Cmd += " -nopatch "
 }

 if($Tune)
 {
	$Cmd += " -tune "
 }

 if($Notune)
 {
	$Cmd += " -notune "
 }

 $Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $Cmd
 Write-DebugLog "Executing function : Add-Hardware command -->" INFO:
 
 Return $Result
} ##  End-of Add-Hardware

##########################################################################
##################### FUNCTION Get-SystemPatch #######################
##########################################################################
Function Get-SystemPatch()
{
<#
  .SYNOPSIS
   Get-SystemPatch - Show what patches have been applied to the system.

  .DESCRIPTION
   The Get-SystemPatch command displays patches applied to a system.

  .EXAMPLE
	Get-3parSystemPatc
	
  .EXAMPLE
	Get-3parSystemPatc -Hist

  .PARAMETER Hist
   Provides an audit log of all patches and updates that have been applied to the system.

  .PARAMETER D
   When used with the -hist option, shows detailed history information including
   the username who installed each package. If -d is used with a patch specification,
   it shows detailed patch information. Otherwise it shows detailed information on the
   currently installed patches.

  .Notes
    NAME: Get-SystemPatch
    LASTEDIT December 2019
    KEYWORDS: Get-SystemPatch
  
  .Link
    Http://www.hpe.com

 #Requires PS -Version 3.0
#>
[CmdletBinding()]
 param(
	[Parameter(Position=0, Mandatory=$false)]
	[switch]
	$Hist,

	[Parameter(Position=1, Mandatory=$false)]
	[switch]
	$D,

	[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
	$SANConnection = $global:SANConnection
 )

 Write-DebugLog "Start: In Get-SystemPatch - validating input values" $Debug 
 #check if connection object contents are null/empty
 if(!$SANConnection)
 {
	#check if connection object contents are null/empty
	$Validate1 = Test-ConnectionObject $SANConnection
	if($Validate1 -eq "Failed")
	{
		#check if global connection object contents are null/empty
		$Validate2 = Test-ConnectionObject $global:SANConnection
		if($Validate2 -eq "Failed")
		{
			Write-DebugLog "Connection object is null/empty or Connection object UserName,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" " ERR: "
			Write-DebugLog "Stop: Exiting Get-SystemPatch since SAN connection object values are null/empty" $Debug 
			Return "FAILURE : Exiting Get-SystemPatch since SAN connection object values are null/empty"
		}
	}
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
	write-debuglog "$plinkresult"
	Return $plinkresult
 }

	$Cmd = " showpatch "

 if($Hist)
 {
	$Cmd += " -hist "
 }

 if($D)
 {
	$Cmd += " -d "
 }

 $Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $Cmd
 Write-DebugLog "Executing function : Get-SystemPatch command -->" INFO: 
 
 Return $Result
} ##  End-of Get-SystemPatch

##########################################
######### FUNCTION Get-Version  ##########
##########################################
 
Function Get-Version()
{	
<#
  .SYNOPSIS
    Get list of  HPE 3PAR Storage system software version information 
  
  .DESCRIPTION
    Get list of  HPE 3PAR Storage system software version information
        
  .EXAMPLE
    Get-Version	
	Get list of  HPE 3PAR Storage system software version information

  .EXAMPLE
    Get-Version -number	
	Get list of  HPE 3PAR Storage system release version number only
	
  .EXAMPLE
    Get-Version -build	
	Get list of  HPE 3PAR Storage system build levels

  .PARAMETER build
	Show build levels.

  .PARAMETER number
	Show release version number only (useful for scripting).
	
  .Notes
    NAME:  Get-Version  
    LASTEDIT: December 2019
    KEYWORDS: Get-Version
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
 [CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[switch]
		$number,
		
		[Parameter(Position=1, Mandatory=$false)]
		[switch]
		$build,
	
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)
	Write-DebugLog "Start: In Get-Version - validating input values" $Debug 
	
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{
		
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
	
		if($Validate1 -eq "Failed")
		{
			
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
			
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Get-Version since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Get-Version since SAN connection object values are null/empty"
			}
		}
	}
	
	$plinkresult = Test-PARCLi -SANConnection $SANConnection
	if($plinkresult -match "FAILURE :")
	{
	
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}
	
	if($number)
	{
		$Getversion = "showversion -s"
		Invoke-3parCLICmd -Connection $SANConnection -cmds  $Getversion
		write-debuglog "Get HPE 3par version info using cmd $Getversion " "INFO:"
		return
	}
	elseif($build)
	{
		$Getversion = "showversion -b "
	}
	else
	{
		$Getversion = "showversion"
	}
	
	#write-host "test"
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $Getversion
	write-debuglog "Get version info " "INFO:" 
	
	$Result = $Result | where { ($_ -notlike '*total*') -and ($_ -notlike '*------*')} ## Eliminate summary lines
	write-host " "
	return $Result
	<#
	$version = New-Object -TypeName _Version
	$version.ReleaseVersionName = partempgetversion 0 2 3
	$version.Patches = partempgetversion 1 1 2
	$version.CliServer = partempgetversion 4 2 3
	$version.CliClient = partempgetversion 5 2 3
	$version.SystemManager = partempgetversion 6 2 3
	$version.Kernel = partempgetversion 7 1 2
	$version.TPDKernelCode = partempgetversion 8 3 4
	$version
	#>
} ## End-of Get-Version

##########################################################################
######################### FUNCTION Update-Cage ######################
##########################################################################
Function Update-Cage()
{
<#
  .SYNOPSIS
   Update-Cage - Upgrade firmware for the specified cage.

  .DESCRIPTION
   The Update-Cage command downloads new firmware into the specified cage.

  .EXAMPLE

  .PARAMETER A
   All drive cages are upgraded one at a time.

  .PARAMETER Parallel
   All drive cages are upgraded in parallel by interface card domain.
   If -wait is specified, the command will not return until the upgrades
   are completed. Otherwise, the command returns immediately and completion
   of the upgrade can be monitored with the -status option.

  .PARAMETER Status
   Print status of the current Update-Cage operation in progress or the last
   executed Update-Cage operation. If any cagenames are specified, result
   is filtered to only display those cages.

  .Notes
    NAME: Update-Cage
    LASTEDIT December 2019
    KEYWORDS: Update-Cage
  
  .Link
    Http://www.hpe.com

 #Requires PS -Version 3.0
#>
[CmdletBinding()]
 param(
	 [Parameter(Position=0, Mandatory=$false)]
	 [switch]
	 $A,

	 [Parameter(Position=1, Mandatory=$false)]
	 [switch]
	 $Parallel,
	 
	 [Parameter(Position=2, Mandatory=$false)]
	 [switch]
	 $Wait,
	 
	 [Parameter(Position=3, Mandatory=$false)]
	 [switch]
	 $Status,

	 [Parameter(Position=4, Mandatory=$false)]
	 [System.String]
	 $Cagename,

	 [Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
	 $SANConnection = $global:SANConnection
 )

 Write-DebugLog "Start: In Update-Cage - validating input values" $Debug 
 #check if connection object contents are null/empty
 if(!$SANConnection)
 {
	#check if connection object contents are null/empty
	$Validate1 = Test-ConnectionObject $SANConnection
	if($Validate1 -eq "Failed")
	{
		#check if global connection object contents are null/empty
		$Validate2 = Test-ConnectionObject $global:SANConnection
		if($Validate2 -eq "Failed")
		{
			Write-DebugLog "Connection object is null/empty or Connection object UserName,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" " ERR: "
			Write-DebugLog "Stop: Exiting Update-Cage since SAN connection object values are null/empty" $Debug 
			Return "FAILURE : Exiting Update-Cage since SAN connection object values are null/empty"
		}
	}
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
	write-debuglog "$plinkresult"
	Return $plinkresult
 }

 $Cmd = " upgradecage "
 
 if($A)
 {
	$Cmd += " -a "
 }
 
 if($Parallel)
 {
	$Cmd += " -parallel "
	 if($Wait)
	 {
		$Cmd += " -wait "
	 }
 }
 if($Status)
 {
	$Cmd += " -status "
 }
 if($Cagename)
 {
	$Cmd += " $Cagename "
 }

 $Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $Cmd
 Write-DebugLog "Executing function : Update-Cage command -->" INFO:
 if($Status)
 {
	 if($Result.count -gt 1)
	 {			
		$tempFile = [IO.Path]::GetTempFileName()
		$LastItem = $Result.Count   
		
		foreach ($s in  $Result[1..$LastItem] )
		{
			$s= [regex]::Replace($s,"^ ","")			
			$s= [regex]::Replace($s,"^ ","")			
			$s= [regex]::Replace($s," +",",")			
			#$s= [regex]::Replace($s,"-","")			
			$s= $s.Trim()			
			
			$temp1 = $s -replace 'StartTime','S-Date,S-Time,S-Zone'
			$temp2 = $temp1 -replace 'StopTime','E-Date,E-Time,E-Zone'
			$s = $temp2					
			Add-Content -Path $tempfile -Value $s				
		}
		Import-Csv $tempFile 
		del $tempFile	
	 }
	 else
	 {			
		Return  $Result
	 }
 }
 else
 {
	Return $Result
 }
 
} ##  End-of Update-Cage

##########################################################################
##################### FUNCTION Reset-SystemNode ######################
##########################################################################
Function Reset-SystemNode()
{
<#
  .SYNOPSIS
   Reset-SystemNode - Halts or reboots a system node.

  .DESCRIPTION
   The Reset-SystemNode command shuts down a system node.

  .EXAMPLE
   Reset-SystemNode -Halt -Node_ID 0.
   
  .PARAMETER Node_ID
	Specifies the node, identified by its ID, to be shut down.
   
  .PARAMETER Halt
	Specifies that the nodes are halted after shutdown.
	
  .PARAMETER Reboot
	Specifies that the nodes are restarted after shutdown.
	
  .PARAMETER Check
	Checks if multipathing is correctly configured so that it is
	safe to halt or reboot the specified node. An error will be
	generated if the loss of the specified node would interrupt
	connectivity to the volume and cause I/O disruption.
	
  .PARAMETER Restart
	Specifies that the storage services should be restarted.
   
  .Notes
    NAME: Reset-SystemNode
    LASTEDIT December 2019
    KEYWORDS: Reset-SystemNode
  
  .Link
    Http://www.hpe.com

 #Requires PS -Version 3.0
#>
[CmdletBinding()]
 param(
	[Parameter(Position=0, Mandatory=$false)]
	[switch]
	$Halt,

	[Parameter(Position=1, Mandatory=$false)]
	[switch]
	$Reboot,

	[Parameter(Position=2, Mandatory=$false)]
	[switch]
	$Check,

	[Parameter(Position=3, Mandatory=$false)]
	[switch]
	$Restart,

	[Parameter(Position=4, Mandatory=$True)]
	[System.String]
	$Node_ID,

	[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
	$SANConnection = $global:SANConnection
 )

 Write-DebugLog "Start: In Reset-SystemNode - validating input values" $Debug 
 #check if connection object contents are null/empty
 if(!$SANConnection)
 {
	#check if connection object contents are null/empty
	$Validate1 = Test-ConnectionObject $SANConnection
	if($Validate1 -eq "Failed")
	{
		#check if global connection object contents are null/empty
		$Validate2 = Test-ConnectionObject $global:SANConnection
		if($Validate2 -eq "Failed")
		{
			Write-DebugLog "Connection object is null/empty or Connection object UserName,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" " ERR: "
			Write-DebugLog "Stop: Exiting Reset-SystemNode since SAN connection object values are null/empty" $Debug 
			Return "FAILURE : Exiting Reset-SystemNode since SAN connection object values are null/empty"
		}
	}
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
	write-debuglog "$plinkresult"
	Return $plinkresult
 }

	$Cmd = " shutdownnode "

 if($Halt)
 {
	$Cmd += " halt "
 }
 Elseif($Reboot)
 {
	$Cmd += " reboot "
 }
 Elseif($Check)
 {
	$Cmd += " check "
 }
 Elseif($Restart)
 {
	$Cmd += " restart "
 }
 else
 {
	Return "Select at least one from [ Halt | Reboot | Check | Restart]"
 }
 
 if($Node_ID)
 {
	$Cmd += " Node_ID "
 }

 $Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $Cmd
 Write-DebugLog "Executing function : Reset-SystemNode command -->" INFO: 
 
 Return $Result
} ##  End-of Reset-SystemNode

##########################################################################
####################### FUNCTION Set-Magazines #######################
##########################################################################
Function Set-Magazines()
{
<#
  .SYNOPSIS
   Set-Magazines - Take magazines or disks on or off loop.

  .DESCRIPTION
   The Set-Magazines command takes drive magazines, or disk drives within a
   magazine, either on-loop or off-loop. Use this command when replacing a
   drive magazine or disk drive within a drive magazine.

  .EXAMPLE
	Set-Magazines -Offloop -Cage_name "xxx" -Magazine "xxx"
	
  .EXAMPLE
	Set-Magazines -Offloop -Port "Both" -Cage_name "xxx" -Magazine "xxx"
  
  .PARAMETER Offloop
	Specifies that the specified drive magazine or disk drive is either
	taken off-loop or brought back on-loop.

  .PARAMETER Onloop
	Specifies that the specified drive magazine or disk drive is either
	taken off-loop or brought back on-loop.
  
  .PARAMETER Cage_name
	Specifies the name of the drive cage. Drive cage information can be
	viewed by issuing the showcage command.
  
  .PARAMETER Magazine
	Specifies the drive magazine number within the drive cage. Valid formats
	are <drive_cage_number>.<drive_magazine> or <drive_magazine> (for
	example 1.3 or 3, respectively).
  
  .PARAMETER Disk
   Specifies that the operation is performed on the disk as determined by
   its position within the drive magazine. If not specified, the operation
   is performed on the entire drive magazine.

  .PARAMETER Port
   Specifies that the operation is performed on port A, port B, or both A
   and B. If not specified, the operation is performed on both ports A and
   B.

  .PARAMETER F
   Specifies that the command is forced. If this option is not used, the
   command requires confirmation before proceeding with its operation.

  .Notes
    NAME: Set-Magazines
    LASTEDIT December 2019
    KEYWORDS: Set-Magazines
  
  .Link
    Http://www.hpe.com

 #Requires PS -Version 3.0
#>
[CmdletBinding()]
 param( 
	[Parameter(Position=0, Mandatory=$false)]
	[switch]
	$Offloop,

	[Parameter(Position=1, Mandatory=$false)]
	[switch]
	$Onloop,

	[Parameter(Position=2, Mandatory=$True)]
	[System.String]
	$Cage_name,

	[Parameter(Position=3, Mandatory=$True)]
	[System.String]
	$Magazine,

	[Parameter(Position=4, Mandatory=$false)]
	[System.String]
	$Disk,

	[Parameter(Position=5, Mandatory=$false)]
	[System.String]
	$Port,

	[Parameter(Position=6, Mandatory=$false)]
	[switch]
	$F,

	[Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
	$SANConnection = $global:SANConnection
 )

 Write-DebugLog "Start: In Set-Magazines - validating input values" $Debug 
 #check if connection object contents are null/empty
 if(!$SANConnection)
 {
	#check if connection object contents are null/empty
	$Validate1 = Test-ConnectionObject $SANConnection
	if($Validate1 -eq "Failed")
	{
		#check if global connection object contents are null/empty
		$Validate2 = Test-ConnectionObject $global:SANConnection
		if($Validate2 -eq "Failed")
		{
			Write-DebugLog "Connection object is null/empty or Connection object UserName,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" " ERR: "
			Write-DebugLog "Stop: Exiting Set-Magazines since SAN connection object values are null/empty" $Debug 
			Return "FAILURE : Exiting Set-Magazines since SAN connection object values are null/empty"
		}
	}
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
	write-debuglog "$plinkresult"
	Return $plinkresult
 }

	$Cmd = " controlmag "

 if($Offloop)
 {
	$Cmd += " offloop "
 }
 Elseif($Onloop)
 {
	$Cmd += " onloop "
 }
 else
 {
	Return "Select at least one from [ Offloop | Onloop ] "
 }

 if($Disk)
 {
	$Cmd += " -disk $Disk "
 }
 if($Port)
 {
	$Val = "A","B" ,"BOTH"
	if($Val -eq $T.ToLower())
	{
		$Cmd += " -port $Port.ToLower "			
	}
	else
	{
		return " Illegal Port value, must be either A,B or Both "
	}
 }

 if($F)
 {
	$Cmd += " -f "
 }

 if($Cage_name)
 {
	$Cmd += " $Cage_name "
 }

 if($Magazine)
 {
	$Cmd += " $Magazine "
 }

 $Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $Cmd
 Write-DebugLog "Executing function : Set-Magazines command -->" INFO: 
 
 Return $Result
} ##  End-of Set-Magazines

##########################################################################
######################### FUNCTION Set-ServiceCage ###################
##########################################################################
Function Set-ServiceCage()
{
<#
  .SYNOPSIS
   Set-ServiceCage - Service a cage.

  .DESCRIPTION
   The Set-ServiceCage command is necessary when executing removal and replacement
   actions for a drive cage interface card or power cooling module. The
   start subcommand is used to initiate service on a cage, and the end
   subcommand is used to indicate that service is completed.

  .EXAMPLE

  .PARAMETER Start
	Specifies the start of service on a cage.
		
  .PARAMETER End
	Specifies the end of service on a cage.
		
  .PARAMETER Reset
	Initiates a soft reset of the interface card for DCN5, DCS11, and DCS12 drive cages.
		
  .PARAMETER Hreset
	Initiates a hard reset of the interface card for DCN5, DCS11, and DCS12 drive cages.
		
  .PARAMETER Remove
	Removes the indicated drive cage (indicated with the <cagename>
	specifier) from the system. This subcommand fails when the cage has
	active ports or is in use.
  
  .PARAMETER Pcm
	For DCS11 and DCS12, this specifies that the Power Cooling Module (PCM)
	will be serviced. For DCN5, this specifies the Power Cooling Battery
	Module (PCBM) will be serviced.

  .PARAMETER Iom
	Specifies that the I/O module will be serviced. This option is not
	valid for DCN5 cage.
	
  .PARAMETER Zero
	For subcommands reset and hreset, this specifies the interface card
	number of the cage to be reset. For subcommands start and end, this
	specifies the number of the module indicated by -pcm or -iom to be
	serviced.
		
  .PARAMETER One
	For subcommands reset and hreset, this specifies the interface card
	number of the cage to be reset. For subcommands start and end, this
	specifies the number of the module indicated by -pcm or -iom to be
	serviced.

	
  .PARAMETER CageName
	Specifies the name of the cage to be serviced.

  .Notes
    NAME: Set-ServiceCage
    LASTEDIT December 2019
    KEYWORDS: Set-ServiceCage
  
  .Link
    Http://www.hpe.com

 #Requires PS -Version 3.0
#>
[CmdletBinding()]
 param(
 
	[Parameter(Position=0, Mandatory=$false)]
	[switch]
	$Start,

	[Parameter(Position=1, Mandatory=$false)]
	[switch]
	$End,

	[Parameter(Position=2, Mandatory=$false)]
	[switch]
	$Reset,

	[Parameter(Position=3, Mandatory=$false)]
	[switch]
	$Hreset,

	[Parameter(Position=4, Mandatory=$false)]
	[switch]
	$Remove,

	[Parameter(Position=5, Mandatory=$false)]
	[switch]
	$Pcm,

	[Parameter(Position=6, Mandatory=$false)]
	[switch]
	$Iom,

	[Parameter(Position=7, Mandatory=$false)]
	[switch]
	$Zero,

	[Parameter(Position=8, Mandatory=$false)]
	[switch]
	$One,

	[Parameter(Position=9, Mandatory=$false)]
	[System.String]
	$CageName,

	[Parameter(Position=10, Mandatory=$false, ValueFromPipeline=$true)]
	$SANConnection = $global:SANConnection
 )

 Write-DebugLog "Start: In Set-ServiceCage - validating input values" $Debug 
 #check if connection object contents are null/empty
 if(!$SANConnection)
 {
	#check if connection object contents are null/empty
	$Validate1 = Test-ConnectionObject $SANConnection
	if($Validate1 -eq "Failed")
	{
		#check if global connection object contents are null/empty
		$Validate2 = Test-ConnectionObject $global:SANConnection
		if($Validate2 -eq "Failed")
		{
			Write-DebugLog "Connection object is null/empty or Connection object UserName,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" " ERR: "
			Write-DebugLog "Stop: Exiting Set-ServiceCage since SAN connection object values are null/empty" $Debug 
			Return "FAILURE : Exiting Set-ServiceCage since SAN connection object values are null/empty"
		}
	}
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
	write-debuglog "$plinkresult"
	Return $plinkresult
 }

 $Cmd = " servicecage "

 if($Start)
 {
	$Cmd += " start "
	
	if($Iom)
	{
		$Cmd += " -iom "
	}
	elseif($Pcm)
	{
		$Cmd += " -pcm "
	}
	else
	{
		Return "Select at least one from [ Iom | Pcm]..."
	}
	
	if($Zero)
	{
		$Cmd += " 0 "
	}
	elseif($One)
	{
		$Cmd += " 1 "
	}
	else
	{
		Return "Select at least one from [ Zero | One]..."
	}
 }
 elseif($End)
 {
	$Cmd += " end "
	
	if($Iom)
	{
		$Cmd += " -iom "
	}
	elseif($Pcm)
	{
		$Cmd += " -pcm "
	}
	else
	{
		Return "Select at least one from [ Iom | Pcm]..."
	}
	
	if($Zero)
	{
		$Cmd += " 0 "
	}
	elseif($One)
	{
		$Cmd += " 1 "
	}
	else
	{
		Return "Select at least one from [ Zero | One]..."
	}
 }
 elseif($Reset)
 {
	$Cmd += " reset -f "
	if($Zero)
	{
		$Cmd += " 0 "
	}
	elseif($One)
	{
		$Cmd += " 1 "
	}
	else
	{
		Return "Select at least one from [ Zero | One]..."
	}
 }
 elseif($Hreset)
 {
	$Cmd += " hreset -f "
	if($Zero)
	{
		$Cmd += " 0 "
	}
	elseif($One)
	{
		$Cmd += " 1 "
	}
	else
	{
		Return "Select at least one from [ Zero | One]..."
	}
 }
 elseif($Remove)
 {
	$Cmd += " remove -f "	
 }
 else
 {
	Return "Select at least one from [ Start | End | Reset | Hreset | Remove]..."
 }
  
 if($CageName)
 {
	$Cmd += " $CageName "
 }
 else
 {
	Return "Cage Name is Mandatory..."
 }
 
 $Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $Cmd
 Write-DebugLog "Executing Function : Set-ServiceCage Command -->" INFO: 
 Return $Result
} ##  End-of Set-ServiceCage

##########################################################################
##################### FUNCTION Set-ServiceNodes ######################
##########################################################################
Function Set-ServiceNodes()
{
<#
  .SYNOPSIS
   Set-ServiceNodes - Prepare a node for service.

  .DESCRIPTION
   The Set-ServiceNodes command informs the system that a certain component will
   be replaced, and will cause the system to indicate the physical location
   of that component.

  .EXAMPLE
	Set-ServiceNodes -Start -Nodeid 0

  .EXAMPLE
	Set-ServiceNodes -Start -Pci 3 -Nodeid 0
	
  .PARAMETER Start
	Specifies the start of service on a node. If shutting down the node
	is required to start the service, the command will prompt for
	confirmation before proceeding further.

  .PARAMETER Status
	Displays the state of any active servicenode operations.

  .PARAMETER End
	Specifies the end of service on a node. If the node was previously
	halted for the service, this command will boot the node.
  
  .PARAMETER Ps
   Specifies which power supply will be placed into servicing-mode.
   Accepted values for <psid> are 0 and 1. For HPE 3PAR 600 series
   systems, this option is not supported, use servicecage for servicing
   the Power Cooling Battery Module (PCBM).

  .PARAMETER Pci
   Only the service LED corresponding to the PCI card in the specified
   slot will be illuminated. Accepted values for <slot> are 3 through 5
   for HPE 3PAR 600 series systems.

  .PARAMETER Fan
   Specifies which node fan will be placed into servicing-mode.
   For HPE 3PAR 600 series systems, this option is not supported,
   use servicecage for servicing the Power Cooling Battery Module (PCBM).

  .PARAMETER Bat
   Specifies that the node's battery backup unit will be placed into
   servicing-mode. For HPE 3PAR 600 series systems, this option is not
   supported, use servicecage for servicing the Power Cooling Battery
   Module (PCBM).

  .Notes
    NAME: Set-ServiceNodes
    LASTEDIT December 2019
    KEYWORDS: Set-ServiceNodes
  
  .Link
    Http://www.hpe.com

 #Requires PS -Version 3.0
#>
[CmdletBinding()]
 param(
	 [Parameter(Position=0, Mandatory=$True)]
	 [System.String]
	 $Nodeid,
	 
	 [Parameter(Position=1, Mandatory=$false)]
	 [switch]
	 $Start,
	 
	 [Parameter(Position=2, Mandatory=$false)]
	 [switch]
	 $Status,
	 
	 [Parameter(Position=3, Mandatory=$false)]
	 [switch]
	 $End,
	 
	 [Parameter(Position=4, Mandatory=$false)]
	 [System.String]
	 $Ps,

	 [Parameter(Position=5, Mandatory=$false)]
	 [System.String]
	 $Pci,

	 [Parameter(Position=6, Mandatory=$false)]
	 [System.String]
	 $Fan,

	 [Parameter(Position=7, Mandatory=$false)]
	 [switch]
	 $Bat,

	 [Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
	 $SANConnection = $global:SANConnection
 )

 Write-DebugLog "Start: In Set-ServiceNodes - validating input values" $Debug 
 #check if connection object contents are null/empty
 if(!$SANConnection)
 {
	#check if connection object contents are null/empty
	$Validate1 = Test-ConnectionObject $SANConnection
	if($Validate1 -eq "Failed")
	{
		#check if global connection object contents are null/empty
		$Validate2 = Test-ConnectionObject $global:SANConnection
		if($Validate2 -eq "Failed")
		{
			Write-DebugLog "Connection object is null/empty or Connection object UserName,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" " ERR: "
			Write-DebugLog "Stop: Exiting Set-ServiceNodes since SAN connection object values are null/empty" $Debug 
			Return "FAILURE : Exiting Set-ServiceNodes since SAN connection object values are null/empty"
		}
	}
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
	write-debuglog "$plinkresult"
	Return $plinkresult
 }

 $Cmd = " servicenode "

 if($Start)
 {
	$Cmd += " start "
 }
 Elseif($Status)
 {
	$Cmd += " status "
 }
 Elseif($End)
 {
	$Cmd += " end "
 }
 else
 {
	Return "Select at least one from [ Start | Status | End]"
 }
 
 if($Ps)
 {
	$Cmd += " -ps $Ps "
 }

 if($Pci)
 {
	$Cmd += " -pci $Pci "
 }

 if($Fan)
 {
	$Cmd += " -fan $Fan "
 }

 if($Bat)
 {
	$Cmd += " -bat "
 }

 if($Nodeid)
 {
	$Cmd += " Nodeid "
 }

 $Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $Cmd
 Write-DebugLog "Executing function : Set-ServiceNodes command -->" INFO:
 
 Return $Result
} ##  End-of Set-ServiceNodes

##########################################################################
######################## FUNCTION Reset-System ########################
##########################################################################
Function Reset-System()
{
<#
  .SYNOPSIS
   Reset-System - Halts or reboots the entire system.

  .DESCRIPTION
   The Reset-System command shuts down an entire system.

  .EXAMPLE
   Reset-System -Halt.
   
  .PARAMETER Halt
	Specifies that the system should be halted after shutdown. If this
	subcommand is not specified, the reboot or restart subcommand must be used.
	
  .PARAMETER Reboot
	Specifies that the system should be restarted after shutdown. If
	this subcommand is not given, the halt or restart subcommand must be used.
	
  .PARAMETER Restart
	Specifies that the storage services should be restarted. If
	this subcommand is not given, the halt or reboot subcommand must be used.
    
  .Notes
    NAME: Reset-System
    LASTEDIT December 2019
    KEYWORDS: Reset-System
  
  .Link
    Http://www.hpe.com

 #Requires PS -Version 3.0
#>
[CmdletBinding()]
 param(
	[Parameter(Position=0, Mandatory=$false)]
	[switch]
	$Halt,

	[Parameter(Position=1, Mandatory=$false)]
	[switch]
	$Reboot,

	[Parameter(Position=2, Mandatory=$false)]
	[switch]
	$Restart,

	[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
	$SANConnection = $global:SANConnection
 )

 Write-DebugLog "Start: In Reset-System - validating input values" $Debug 
 #check if connection object contents are null/empty
 if(!$SANConnection)
 {
	#check if connection object contents are null/empty
	$Validate1 = Test-ConnectionObject $SANConnection
	if($Validate1 -eq "Failed")
	{
		#check if global connection object contents are null/empty
		$Validate2 = Test-ConnectionObject $global:SANConnection
		if($Validate2 -eq "Failed")
		{
			Write-DebugLog "Connection object is null/empty or Connection object UserName,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" " ERR: "
			Write-DebugLog "Stop: Exiting Reset-System since SAN connection object values are null/empty" $Debug 
			Return "FAILURE : Exiting Reset-System since SAN connection object values are null/empty"
		}
	}
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
	write-debuglog "$plinkresult"
	Return $plinkresult
 }

	$Cmd = " shutdownsys "

 if($Halt)
 {
	$Cmd += " halt "
 }
 Elseif($Reboot)
 {
	$Cmd += " reboot "
 }
 Elseif($Restart)
 {
	$Cmd += " restart "
 }
 else
 {
	Return "Select at least one from [Halt | Reboot | Restart ]"
 }

 $Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $Cmd
 Write-DebugLog "Executing function : Reset-System command -->" INFO:
 
 Return $Result
} ##  End-of Reset-System

##########################################################################
###################### FUNCTION Update-PdFirmware ####################
##########################################################################
Function Update-PdFirmware()
{
<#
  .SYNOPSIS
   Update-PdFirmware - Upgrade physical disk firmware.

  .DESCRIPTION
   The Update-PdFirmware command upgrades the physical disk firmware.

  .EXAMPLE

  .PARAMETER F
   Upgrades the physical disk firmware without requiring confirmation.

  .PARAMETER Skiptest
   Skips the 10 second diagnostic test normally completed after each
   physical disk upgrade.

  .PARAMETER A
   Specifies that all physical disks with valid IDs and whose firmware
   is not current are upgraded. If this option is not specified, then
   either the -w option or PD_ID specifier must be issued on the command
   line.

  .PARAMETER W
   Specifies that the firmware of either one or more physical disks,
   identified by their WWNs, is upgraded. If this option is not specified,
   then either the -a option or PD_ID specifier must be issued on the
   command line.

  .PARAMETER PD_ID
	Specifies that the firmware of either one or more physical disks
	identified by their IDs (PD_ID) is upgraded. If this specifier is not
	used, then the -a or -w option must be issued on the command line.
   
  .Notes
    NAME: Update-PdFirmware
    LASTEDIT December 2019
    KEYWORDS: Update-PdFirmware
  
  .Link
    Http://www.hpe.com

 #Requires PS -Version 3.0
#>
[CmdletBinding()]
 param(
	[Parameter(Position=0, Mandatory=$false)]
	[switch]
	$F,

	[Parameter(Position=1, Mandatory=$false)]
	[switch]
	$Skiptest,

	[Parameter(Position=2, Mandatory=$false)]
	[switch]
	$A,

	[Parameter(Position=3, Mandatory=$false)]
	[System.String]
	$W,

	[Parameter(Position=4, Mandatory=$false)]
	[System.String]
	$PD_ID,

	[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
	$SANConnection = $global:SANConnection
 )

 Write-DebugLog "Start: In Update-PdFirmware - validating input values" $Debug 
 #check if connection object contents are null/empty
 if(!$SANConnection)
 {
	#check if connection object contents are null/empty
	$Validate1 = Test-ConnectionObject $SANConnection
	if($Validate1 -eq "Failed")
	{
		#check if global connection object contents are null/empty
		$Validate2 = Test-ConnectionObject $global:SANConnection
		if($Validate2 -eq "Failed")
		{
			Write-DebugLog "Connection object is null/empty or Connection object UserName,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" " ERR: "
			Write-DebugLog "Stop: Exiting Update-PdFirmware since SAN connection object values are null/empty" $Debug 
			Return "FAILURE : Exiting Update-PdFirmware since SAN connection object values are null/empty"
		}
	}
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
	write-debuglog "$plinkresult"
	Return $plinkresult
 }

 $Cmd = " upgradepd "
 
 if($F)
 {
	$Cmd += " -f "
 } 
 if($Skiptest)
 {
	$Cmd += " -skiptest "
 } 
 if($A)
 {
	$Cmd += " -a "
 } 
 if($W)
 {
	$Cmd += " -w $W "
 } 
 if($PD_ID)
 {
	$Cmd += " $PD_ID "
 } 

 $Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $Cmd
 Write-DebugLog "Executing function : Update-PdFirmware command -->" INFO:
 
 Return $Result
} ##  End-of Update-PdFirmware

##########################################################################
######################### FUNCTION Search-ServiceNode ################
##########################################################################
Function Search-ServiceNode()
{
<#
  .SYNOPSIS
   Search-ServiceNode - Prepare a node for service.

  .DESCRIPTION
   The Search-ServiceNode command informs the system that a certain component will
   be replaced, and will cause the system to indicate the physical location
   of that component.

  .EXAMPLE

  .PARAMETER Start
	Specifies the start of service on a node. If shutting down the node
	is required to start the service, the command will prompt for
	confirmation before proceeding further.

  .PARAMETER Status
	Displays the state of any active servicenode operations.
	
  .PARAMETER End
	Specifies the end of service on a node. If the node was previously
	halted for the service, this command will boot the node.
  
  .PARAMETER Ps
   Specifies which power supply will be placed into servicing-mode.
   Accepted values for <psid> are 0 and 1. For HPE 3PAR 600 series
   systems, this option is not supported, use servicecage for servicing
   the Power Cooling Battery Module (PCBM).

  .PARAMETER Pci
   Only the service LED corresponding to the PCI card in the specified
   slot will be illuminated. Accepted values for <slot> are 3 through 5
   for HPE 3PAR 600 series systems.

  .PARAMETER Fan
   Specifies which node fan will be placed into servicing-mode.
   For HPE 3PAR 600 series systems, this option is not supported,
   use servicecage for servicing the Power Cooling Battery Module (PCBM).

  .PARAMETER Bat
   Specifies that the node's battery backup unit will be placed into
   servicing-mode. For HPE 3PAR 600 series systems, this option is not
   supported, use servicecage for servicing the Power Cooling Battery
   Module (PCBM).
   
  .PARAMETER NodeId  
	Indicates which node the servicenode operation will act on. Accepted
	values are 0 through 3 for HPE 3PAR 600 series systems.

  .Notes
    NAME: Search-ServiceNode
    LASTEDIT January 2020
    KEYWORDS: Search-ServiceNode
  
  .Link
    Http://www.hpe.com

 #Requires PS -Version 3.0
#>
[CmdletBinding()]
 param(
	[Parameter(Position=0, Mandatory=$false)]
	[switch]
	$Start,

	[Parameter(Position=1, Mandatory=$false)]
	[switch]
	$Status,

	[Parameter(Position=2, Mandatory=$false)]
	[switch]
	$End,

	[Parameter(Position=3, Mandatory=$false)]
	[System.String]
	$Ps,

	[Parameter(Position=4, Mandatory=$false)]
	[System.String]
	$Pci,

	[Parameter(Position=5, Mandatory=$false)]
	[System.String]
	$Fan,

	[Parameter(Position=6, Mandatory=$false)]
	[switch]
	$Bat,

	[Parameter(Position=7, Mandatory=$true)]
	[System.String]
	$NodeId,

	[Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
	$SANConnection = $global:SANConnection
 )

 Write-DebugLog "Start: In Search-ServiceNode - validating input values" $Debug 
 #check if connection object contents are null/empty
 if(!$SANConnection)
 {
	#check if connection object contents are null/empty
	$Validate1 = Test-ConnectionObject $SANConnection
	if($Validate1 -eq "Failed")
	{
		#check if global connection object contents are null/empty
		$Validate2 = Test-ConnectionObject $global:SANConnection
		if($Validate2 -eq "Failed")
		{
			Write-DebugLog "Connection object is null/empty or Connection object UserName,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" " ERR: "
			Write-DebugLog "Stop: Exiting Search-ServiceNode since SAN connection object values are null/empty" $Debug 
			Return "FAILURE : Exiting Search-ServiceNode since SAN connection object values are null/empty"
		}
	}
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
	write-debuglog "$plinkresult"
	Return $plinkresult
 }

 $Cmd = " servicenode "

 if($Start)
 {
	$Cmd += " start "
 }
 elseif($Status)
 {
	$Cmd += " status "
 }
 elseif($End)
 {
	$Cmd += " end "
 }
 else
 {
	Return "Select at least one from [Start | Status | End]..."
 } 
 
 if($Ps)
 {
	$Cmd += " -ps $Ps "
 }

 if($Pci)
 {
	$Cmd += " -pci $Pci "
 }

 if($Fan)
 {
	$Cmd += " -fan $Fan "
 }

 if($Bat)
 {
	$Cmd += " -bat "
 }

 if($NodeId)
 {
	$Cmd += " $NodeId "
 }
 
 $Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $Cmd
 Write-DebugLog "Executing Function : Search-ServiceNode Command -->" INFO: 
 
 Return $Result
} ##  End-of Search-ServiceNode


Export-ModuleMember Add-Hardware , Get-SystemPatch , Get-Version , Update-Cage , Reset-SystemNode , Set-Magazines , 
Set-ServiceCage , Set-ServiceNodes , Reset-System , Update-PdFirmware , Search-ServiceNode