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
##	File Name:		Replication.psm1
##	Description: 	Replication cmdlets 
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

####################################################################################################################
## FUNCTION Add-RCopyTarget
####################################################################################################################
Function Add-RCopyTarget
{
<#
  .SYNOPSIS
    The Add-RCopyTarget command adds a target to a remote-copy volume group.
	
  .DESCRIPTION
    The Add-RCopyTarget command adds a target to a remote-copy volume group.
	
  .EXAMPLE
   Add-RCopyTarget -Target_name XYZ -Mode sync -Group_name test
   This example admits physical disks.
  
  .PARAMETER Target_name 
	Specifies the name of the target that was previously created with the creatercopytarget command.
	 
  .PARAMETER Mode 
	Specifies the mode of the target as either synchronous (sync), asynchronous periodic (periodic), or asynchronous streaming (async).
	
  .PARAMETER Group_name 
    Specifies the name of the existing remote copy volume group created with the creatercopygroup command to which the target will be added.
	  
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  Add-RCopyTarget
    LASTEDIT: December 2019
    KEYWORDS: Add-RCopyTarget
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		
		[Parameter(Position=0, Mandatory=$true,ValueFromPipeline=$true)]
		[System.String]
		$Target_name,
		
		[Parameter(Position=1, Mandatory=$true,ValueFromPipeline=$true)]
		[System.String]
		$Mode,
		
		[Parameter(Position=2, Mandatory=$true,ValueFromPipeline=$true)]
		[System.String]
		$Group_name,
				
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection       
		)	
	
	Write-DebugLog "Start: In Add-RCopyTarget   - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting Add-RCopyTarget since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Add-RCopyTarget since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}		
	$cmd= "admitrcopytarget "
	if ($Target_name)
	{		
		$cmd+=" $Target_name "			
	}
	else
	{
		return " FAILURE :  Target_name is mandatory for to execute  "
	}
	if ($Mode)
	{	
		$a = "sync","periodic","async"
		$l=$Mode
		if($a -eq $l)
		{
			$cmd+=" $Mode "			
		}
		else
		{ 
			Write-DebugLog "Stop: Exiting    Add-RCopyTarget since -Mode $Mode in incorrect "
			Return "FAILURE : -Mode :- $Mode is an Incorrect Mode  [sync | periodic | async]  can be used only . "
		}
					
	}
	else
	{
		return " FAILURE :  Mode is mandatory for to execute  "
	}
	if ($Group_name)
	{		
		$cmd+=" $Group_name "			
	}
	else
	{
		return " FAILURE :  Group_name is mandatory for to execute  "
	}
	
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $cmd	
	write-debuglog " The Add-RCopyTarget command creates and admits physical disk definitions to enable the use of those disks  " "INFO:" 
	return 	$Result	
} # End Add-RCopyTarget

####################################################################################################################
## FUNCTION Add-RCopyVv
####################################################################################################################
Function Add-RCopyVv
{
<#
  .SYNOPSIS
    The Add-RCopyVv command adds an existing virtual volume to an existing remote copy volume group.

  .DESCRIPTION
	The Add-RCopyVv command adds an existing virtual volume to an existing remote copy volume group.
	
  .EXAMPLE	
    Add-RCopyVv -SourceVolumeName XXXX -Group_name ZZZZ -Target_name TestTarget -TargetVolumeName YYYY
	
  .EXAMPLE
     Add-RCopyVv -SourceVolumeName XXXX -Snapname snp -Group_name ZZZZ -Target_name TestTarget -TargetVolumeName YYYY
   
  .EXAMPLE
    Add-RCopyVv -SourceVolumeName XXXX -Snapname snp -Group_name AS_TEST -Target_name CHIMERA03 -TargetVolumeName YYYY
   
  .EXAMPLE
    Add-RCopyVv -Pat -SourceVolumeName XXXX -Group_name ZZZZ -Target_name TestTarget -TargetVolumeName YYYY

  .EXAMPLE	
	Add-RCopyVv -CreateVV -SourceVolumeName XXXX -Group_name ZZZZ -Target_name TestTarget -TargetVolumeName YYYY
	
  .EXAMPLE
	Add-RCopyVv -NoWWN -SourceVolumeName XXXX -Group_name ZZZZ -Target_name TestTarget -TargetVolumeName YYYY
  
  .PARAMETER Pat
	Specifies that the <VV_name> is treated as a glob-style pattern and that
	all remote copy volumes matching the specified pattern are admitted to the
	remote copy group. When this option is used the <sec_VV_name> and
	<snapname> (if specified) are also treated as patterns. It is required
	that the secondary volume names and snapshot names can be derived from the
	local volume name by adding a prefix, suffix or both. <snapname> and
	<sec_VV_name> should take the form prefix@vvname@suffix, where @vvname@
	resolves to the name of each volume that matches the <VV_name> pattern.

  .PARAMETER CreateVV
	Specifies that the secondary volumes should be created automatically. This
	specifier cannot be used when starting snapshots (<VV_name>:<snapname>) are
	specified.

  .PARAMETER NoWWN
	When used with -createvv, it ensures a different WWN is	used on the secondary volume. Without this option -createvv will use the same WWN for both primary and secondary volumes.

  .PARAMETER NoSync
	Specifies that the volume should skip the initial sync. This is for the
	admission of volumes that have been pre-synced with the target volume.
	This specifier cannot be used when starting snapshots (<VV_name>:<snapname>)
	are specified.
  
  .PARAMETER SourceVolumeName
	Specifies the name of the existing virtual volume to be admitted to an
	existing remote copy volume group that was created with the
	creatercopygroup command.
  
  .PARAMETER Snapname
	An optional read-only snapshot <snapname> can be specified along with
	the virtual volume name <VV_name>.
		
  .PARAMETER Group_name
	Specifies the name of the existing remote copy volume group created with
	the creatercopygroup command, to which the volume will be added.

  .PARAMETER Target_name
	The target name associated with this group, as set with the
	creatercopygroup command. The target is created with the
	creatercopytarget command.
  
  .PARAMETER TargetVolumeName
	The target name associated with this group, as set with the
	creatercopygroup command. The target is created with the
	creatercopytarget command. <sec_VV_name> specifies the name of the
	secondary volume on the target system.  One <target_name>:<sec_VV_name>
	must be specified for each target of the group.
	 
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  Add-RCopyVv
    LASTEDIT: December 2019
    KEYWORDS: Add-RCopyVv
   
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
		$CreateVV,
		
		[Parameter(Position=2, Mandatory=$false)]
		[switch]
		$NoWWN,
		
		[Parameter(Position=3, Mandatory=$false)]
		[switch]
		$NoSync,
		
		[Parameter(Position=4, Mandatory=$true,ValueFromPipeline=$true)]
		[System.String]
		$SourceVolumeName,
		
		[Parameter(Position=5, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$Snapname,
		
		[Parameter(Position=6, Mandatory=$true,ValueFromPipeline=$true)]
		[System.String]
		$Group_name,
		
		[Parameter(Position=7, Mandatory=$true,ValueFromPipeline=$true)]
		[System.String]
		$Target_name,
		
		[Parameter(Position=8, Mandatory=$true,ValueFromPipeline=$true)]
		[System.String]
		$TargetVolumeName,		
				
		[Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection       
	)	
	
	Write-DebugLog "Start: In Add-RCopyVv   - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting Add-RCopyVv since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Add-RCopyVv since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}		
	$cmd= "admitrcopyvv "
	if ($Pat)
	{	
		$cmd+=" -pat "		
	}
	if ($CreateVV)
	{	
		$cmd+=" -createvv "		
	}
	if ($NoWWN)
	{	
		$cmd+=" -nowwn "		
	}
	if ($NoSync)
	{	
		$cmd+=" -nosync "		
	}
	if ($SourceVolumeName)
	{		
		$cmd+=" $SourceVolumeName"	
	}	
	else
	{
		return " FAILURE :  Existing virtual volume is mandatory for to execute  "
	}
	if ($Snapname)
	{		
		$cmd+=":$Snapname "	
	}
	if ($Group_name)
	{		
		$cmd+=" $Group_name "	
	}	
	else
	{
		return " FAILURE :  Group_name is mandatory for to execute  "
	}
	if ($Target_name)
	{		
		$cmd+=" $Target_name"	
	}	
	else
	{
		return " FAILURE :  Target_name is mandatory for to execute  "
	}
	if ($TargetVolumeName)
	{		
		$cmd+=":$TargetVolumeName "	
	}	
	else
	{
		return " FAILURE :  TargetVolumeName is mandatory for to execute  "
	}
	
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $cmd
	write-debuglog " The Add-RCopyVv command creates and admits physical disk definitions to enable the use of those disks  " "INFO:" 
	return 	$Result	
} # End Add-RCopyVv

####################################################################################################################
## FUNCTION Add-RCopyLink 
###################################################################################################################
Function Add-RCopyLink
{
<#
  .SYNOPSIS
    The  command adds one or more links (connections) to a remote-copy target system.
	
  .DESCRIPTION
    The  command adds one or more links (connections) to a remote-copy target system.  
  
  .EXAMPLE
  Add-RCopyLink  -TargetName demo1 -N_S_P_IP 1:2:1:193.1.2.11
  This Example adds a link on System2 using the node, slot, and port information of node 1, slot 2, port 1 of the Ethernet port on the primary system. The IP address 193.1.2.11 specifies the address on the target system:
  
  .EXAMPLE
  Add-RCopyLink  -TargetName System2 -N_S_P_WWN 5:3:2:1122112211221122
  This Example WWN creates an RCFC link to target System2, which connects to the local 5:3:2 (N:S:P) in the target system.
  
	
  .PARAMETER TargetName 
    Specify name of the TargetName to be updated.

  .PARAMETER N_S_P_IP
	Node number:Slot number:Port Number:IP Address of the Target to be created.
	
   .PARAMETER N_S_P_WWN
	Node number:Slot number:Port Number:World Wide Name (WWN) address on the target system.
	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  Add-RCopyLink   
    LASTEDIT: December 2019
    KEYWORDS: Add-RCopyLink 
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$TargetName,
		
		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$N_S_P_IP,
		
		[Parameter(Position=2, Mandatory=$false)]
		[System.String]
		$N_S_P_WWN,
				
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)		
	Write-DebugLog "Start: In Add-RCopyLink    - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting Add-RCopyLink  since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Add-RCopyLink since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}
	
	$cmd = "admitrcopylink "
	
	if ($TargetName)
	{
		$cmd += "$TargetName "
	}
	else
	{
		Write-DebugLog "Stop: TargetName is mandatory" $Debug
		return "Error :  -TargetName is mandatory. "			
	}	
	if($N_S_P_IP)
	{
		if ($N_S_P_WWN)
		{
			return "Error : -N_S_P_WWN and -N_S_P_IP cannot be used simultaneously.  "
		}
		$s = $N_S_P_IP
		$s= [regex]::Replace($s,","," ")
		$cmd+="$s"
		$cmd1="yes"
	}
	if ($N_S_P_WWN)
	{
		if("yes" -eq $cmd1)
		{
			return "Error : -N_S_P_WWN and -N_S_P_IP cannot be used simultaneously.  "
		}
		$s = $N_S_P_WWN
		$s= [regex]::Replace($s,","," ")
		$cmd+="$s"	
	}
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $cmd
	write-debuglog "Add-RCopyLink  command adds one or more links (connections) to a remote-copy target system. cmd   " "INFO:" 	
	return $Result	
} # End Add-RCopyLink

####################################################################################################################
## FUNCTION Disable-RCopylink
####################################################################################################################
Function Disable-RCopylink
{
<#
  .SYNOPSIS
    The Disable-RCopylink command removes one or more links (connections)
    created with the admitrcopylink command to a target system.

  .DESCRIPTION
    The Disable-RCopylink command removes one or more links (connections)
    created with the admitrcopylink command to a target system.
	
  .EXAMPLE
   Disable-RCopylink -RCIP -Target_name test -NSP_IP_address 1.1.1.1

  .EXAMPLE
   Disable-RCopylink -RCFC -Target_name test -NSP_WWN 1245
      
  .PARAMETER RCIP  
	Syntax for remote copy over IP (RCIP)
	
  .PARAMETER RCFC
	Syntax for remote copy over FC (RCFC)
		
  .PARAMETER Target_name	
	The target name, as specified with the creatercopytarget command.
	
  .PARAMETER NSP_IP_address		
	Specifies the node, slot, and port of the Ethernet port on the local system and an IP address of the peer port on the target system.

  .PARAMETER NSP_WWN
	Specifies the node, slot, and port of the Fibre Channel port on the local system and World Wide Name (WWN) of the peer port on the target system.
	 
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  Disable-RCopylink
    LASTEDIT: December 2019
    KEYWORDS: Disable-RCopylink
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
	
		[Parameter(Position=0, Mandatory=$false)]
		[Switch]
		$RCIP,
	
		[Parameter(Position=1, Mandatory=$false)]
		[Switch]
		$RCFC,

		[Parameter(Position=2, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$Target_name,
		
		[Parameter(Position=3, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$NSP_IP_address,
		
		[Parameter(Position=4, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$NSP_WWN,		
				
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection       
	)	
	
	Write-DebugLog "Start: In Disable-RCopylink   - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting Disable-RCopylink since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Disable-RCopylink since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}		
	$cmd= "dismissrcopylink "
	if($RCFC -or $RCIP)
	{
		if($RCFC)
		{
			if($RCIP)
			{
				return "Please select only one RCFC -or RCIP"
			}
			else
			{
				if ($Target_name)
				{		
					$cmd+=" $Target_name "	
				}	
				else
				{
					return " FAILURE :  Target_name is mandatory to execute  "
				}
				if ($NSP_IP_address)
				{		
					$cmd+=" $NSP_IP_address "	
				}	
				else
				{
					return " FAILURE :  NSP_IP_address is mandatory to execute  "
				}
			}
		}
		if($RCIP)
		{
			if($RCFC)
			{
				return "Please select only one RCFC -or RCIP"
			}
			else
			{
				if ($Target_name)
				{		
					$cmd+=" $Target_name "	
				}	
				else
				{
					return " FAILURE :  Target_name is mandatory for to execute  "
				}
				if ($NSP_WWN)
				{		
					$cmd+=" $NSP_WWN "	
				}	
				else
				{
					return " FAILURE :  NSP_WWN is mandatory for to execute  "
				}
			}
		}
	}
	else
	{
		return "Please Select at-list any one from RCFC -or RCIP to execute Disable-RCopylink command"
	}
		
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $cmd
	write-debuglog " The Disable-RCopylink command creates and admits physical disk definitions to enable the use of those disks  " "INFO:" 
	return 	$Result	
	
} # End Disable-RCopylink

####################################################################################################################
## FUNCTION Disable-RCopyTarget
####################################################################################################################
Function Disable-RCopyTarget
{
<#
  .SYNOPSIS
    The Disable-RCopyTarget command removes a remote copy target from a
    remote copy volume group.

  .DESCRIPTION
    The Disable-RCopyTarget command removes a remote copy target from a
    remote copy volume group.
	
  .EXAMPLE
   Disable-RCopyTarget -Target_name Test -Group_name Test2
     		
  .PARAMETER Target_name	
	The name of the target to be removed.
	
  .PARAMETER Group_name		
	 The name of the group that currently includes the target.
	 
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  Disable-RCopyTarget
    LASTEDIT: December 2019
    KEYWORDS: Disable-RCopyTarget
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(		

		[Parameter(Position=0, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$Target_name,
		
		[Parameter(Position=1, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$Group_name,
				
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection       
	)	
	
	Write-DebugLog "Start: In Disable-RCopyTarget   - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting Disable-RCopyTarget since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Disable-RCopyTarget since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}		
	$cmd= "dismissrcopytarget -f "
	if ($Target_name)
	{		
		$cmd+=" $Target_name "	
	}	
	else
	{
		return " FAILURE :  Target_name is mandatory for to execute  "
	}
	if ($Group_name)
	{		
		$cmd+=" $Group_name "	
	}	
	else
	{
		return " FAILURE :  Group_name is mandatory for to execute  "
	}
		
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $cmd
	write-debuglog " The Disable-RCopyTarget command creates and admits physical disk definitions to enable the use of those disks  " "INFO:" 
	return 	$Result	
} # End Disable-RCopyTarget

####################################################################################################################
## FUNCTION Disable-RCopyVv
####################################################################################################################
Function Disable-RCopyVv
{
<#
  .SYNOPSIS
    The Disable-RCopyVv command removes a virtual volume from a remote copy volume
    group.

  .DESCRIPTION
    The Disable-RCopyVv command removes a virtual volume from a remote copy volume
    group.
	
  .EXAMPLE
   Disable-RCopyVv -VV_name XYZ -Group_name XYZ
   
  .EXAMPLE
   Disable-RCopyVv -Pat -VV_name XYZ -Group_name XYZ
   
  .EXAMPLE
   Disable-RCopyVv -KeepSnap -VV_name XYZ -Group_name XYZ
   
  .EXAMPLE
   Disable-RCopyVv -RemoveVV -VV_name XYZ -Group_name XYZ
  
  .PARAMETER Pat
	Specifies that specified patterns are treated as glob-style patterns
	and all remote copy volumes matching the specified pattern will be
	dismissed from the remote copy group. This option must be used
	if the <pattern> specifier is used.

  .PARAMETER KeepSnap
	Specifies that the local volume's resync snapshot should be retained.
	The retained snapshot will reflect the state of the secondary volume
	and might be used as the starting snapshot if the volume is readmitted
	to a remote copy group. The snapshot name will begin with "sv.rcpy"

  .PARAMETER RemoveVV
	Remove remote sides' volumes.
  
  .PARAMETER VV_name	
	The name of the volume to be removed. Volumes are added to a group with the admitrcopyvv command.
	  	
  .PARAMETER Group_name		
	 The name of the group that currently includes the target.
	 
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  Disable-RCopyVv
    LASTEDIT: December 2019
    KEYWORDS: Disable-RCopyVv
   
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
		$KeepSnap,
		
		[Parameter(Position=2, Mandatory=$false)]
		[switch]
		$RemoveVV,

		[Parameter(Position=3, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$VV_name,
		
		[Parameter(Position=4, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$Group_name,
				
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection       
	)	
	
	Write-DebugLog "Start: In Disable-RCopyVv   - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting Disable-RCopyVv since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Disable-RCopyVv since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}		
	$cmd= "dismissrcopyvv -f "
	
	if($Pat)
	{
		$cmd+=" -pat "
	}
	if($KeepSnap)
	{
		$cmd+=" -keepsnap "
	}
	if($RemoveVV)
	{
		$cmd+=" -removevv "
	}
	if ($VV_name)
	{		
		$cmd+=" $VV_name "	
	}	
	else
	{
		return " FAILURE :  VV_name is mandatory for to execute  "
	}
	if ($Group_name)
	{		
		$cmd+=" $Group_name "	
	}	
	else
	{
		return " FAILURE :  Group_name is mandatory for to execute  "
	}
		
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $cmd
	write-debuglog " The Disable-RCopyVv command creates and admits physical disk definitions to enable the use of those disks  " "INFO:" 
	return 	$Result	
	
} # End Disable-RCopyVv

####################################################################################################################
## FUNCTION Get-RCopy
####################################################################################################################
Function Get-RCopy
{
<#
  .SYNOPSIS
   The Get-RCopy command displays details of the remote-copy configuration.
   
  .DESCRIPTION
    The Get-RCopy command displays details of the remote-copy configuration.
	
  .EXAMPLE
	Get-RCopy -Detailed -Links
	This Example displays details of the remote-copy configuration and Specifies all remote-copy links.   
	
  .EXAMPLE  	
	Get-RCopy -Detailed -Domain PSTest -Targets Demovv1
	This Example displays details of the remote-copy configuration which Specifies either all target definitions
 
  .PARAMETER Detailed	:	Displays more detailed configuration information.
	
  .PARAMETER QW	:	Displays additional target specific automatic transparent failover-related configuration, where applicable.
  	 
  .PARAMETER Domain
	Shows only remote-copy links whose virtual volumes are in domains with names that match one or more of the specified domain name or pattern.
	
  .PARAMETER Links
	Specifies all remote-copy links.
		
  .PARAMETER Groups 
	Specifies either all remote-copy volume groups or a specific remote-copy volume group by name or by glob-style pattern.
  
  .PARAMETER Targets
	Specifies either all target definitions or a specific target definition by name or by glob-style pattern.
	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  Get-RCopy
    LASTEDIT: December 2019
    KEYWORDS: Get-RCopy
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false,ValueFromPipeline=$true)]
		[switch]
		$Detailed,
		
		[Parameter(Position=1, Mandatory=$false,ValueFromPipeline=$true)]
		[switch]
		$QW,
		
		[Parameter(Position=2, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$Domain,
		
		[Parameter(Position=3, Mandatory=$false)]
		[switch]
		$Links,
		
		[Parameter(Position=4, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$Groups,
		
		[Parameter(Position=5, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$Targets,
			
		[Parameter(Position=5, Mandatory=$false,ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)		
	
	Write-DebugLog "Start: In Get-RCopy   - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting Get-RCopy since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Get-RCopy since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}		
	$cmd= "showrcopy "	
	if ($Detailed)
	{
		$cmd += " -d "
	}
	if ($QW)
	{
		$cmd += " -qw "
	}
	if ($Domain)
	{
		$cmd += " -domain $Domain "
	}
	if ($Links)
	{
		$cmd += " links "
	}	
	if ($Groups)
	{
		$cmd+="groups $Groups "		
	}	
	if ($Targets)
	{		
		$cmd+="targets $Targets "
	}
	
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $cmd
	write-debuglog "  The Get-RCopy command displays details of the remote-copy configuration." "INFO:" 
	return $Result
} # End Get-RCopy

####################################################################################################################
## FUNCTION Get-StatRCopy
####################################################################################################################
Function Get-StatRCopy
{
<#
  .SYNOPSIS
   The Get-StatRCopy command displays statistics for remote-copy volume groups.
   
	.DESCRIPTION
       The Get-StatRCopy command displays statistics for remote-copy volume groups.
	
	.EXAMPLE
	Get-StatRCopy -HeartBeat -Iteration 1
	This example shows statistics for sending links ,Specifies that the heartbeat round-trip time.
	
	.EXAMPLE  
	Get-StatRCopy -Iteration 1
	This example shows statistics for sending links link0 and link1.
   
	.EXAMPLE  
	Get-StatRCopy -HeartBeat -Unit k -Iteration 1
	This example shows statistics for sending links ,Specifies that the heartbeat round-trip time & displays statistics as kilobytes	
	
	.PARAMETER HeartBeat  
	Specifies that the heartbeat round-trip time of the links should be displayed in addition to the link throughput.
	 
	.PARAMETER Unit
	Displays statistics as kilobytes (k), megabytes (m), or gigabytes (g). If no unit is specified, the default is kilobytes.
	
	.PARAMETER Iteration 
	Specifies that I/O statistics are displayed a specified number of times as indicated by the num argument using an integer from 1 through 2147483647.
	
	.PARAMETER Interval
	Specifies the interval, in seconds, that statistics are sampled using an
	integer from 1 through 2147483647. If no interval is specified, the option
	defaults to an interval of two seconds.
	
	.PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  Get-StatRCopy
    LASTEDIT: December 2019
    KEYWORDS: Get-StatRCopy
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$Interval,
		
		[Parameter(Position=1, Mandatory=$false)]
		[switch]
		$HeartBeat,
		
		[Parameter(Position=2, Mandatory=$false)]
		[System.String]
		$Unit,
		
		[Parameter(Position=3, Mandatory=$false)]
		[System.String]
		$Iteration,		
		
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)		
	Write-DebugLog "Start: In Get-StatRCopy   - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting Get-StatRCopy since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Get-StatRCopy since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}		
	$cmd= "statrcopy "	
	if ($Iteration)
	{
		$cmd += " -iter $Iteration "
	}	
	else
	{
		Write-DebugLog "Stop: Iteration is mandatory" $Debug
		return "Error :  -Iteration is mandatory. "			
	}
	
	if ($Interval )
	{
		$cmd+= "-d $Interval "
	}
	if ($HeartBeat )
	{
		$cmd+= "-hb "
	}
	if ($Unit)
	{
		$c= "k","m","g"		
		if ($c -eq $Unit)
		{
			$cmd+=" -u $Unit  "
		}
		else
		{
			Write-DebugLog "Stop: Exiting Get-StatRCopy  Unit  in unavailable "
			Return "FAILURE : -Unit  $Unit is Unavailable to execute use only [k | m | g]. "
		}
	}		
				
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $cmd	
	write-debuglog "  The Get-StatRCopy command displays statistics for remote-copy volume groups. " "INFO:" 
	return  $Result
	<#
	if($Result.Count -gt 1)
	{
		$tempFile = [IO.Path]::GetTempFileName()
		$LastItem = $Result.Count
		$incre = "true" 		
		foreach ($s in  $Result[1..$LastItem] )
		{			
			$s= [regex]::Replace($s,"^ ","")						
			$s= [regex]::Replace($s," +",",")			
			$s= [regex]::Replace($s,"-","")			
			$s= $s.Trim()			
			if($incre -eq "true")
			{		
				$sTemp1=$s				
				$sTemp = $sTemp1.Split(',')					
				$sTemp[5]="Current(Throughput)"				
				$sTemp[6]="Average(Throughput)"
				$sTemp[7]="Current(Write_Same_Zero)"				
				$sTemp[8]="Average(Writ_Same_Zero)"
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
	}
	else
	{			
		return  $Result
	}	
#>	
} # End Get-StatRCopy

####################################################################################################################
## FUNCTION Remove-RCopyGroup
###################################################################################################################
Function Remove-RCopyGroup
{
<#
  .SYNOPSIS
   The Remove-RCopyGroup command removes a remote-copy volume group or multiple remote-copy groups that match a given pattern.
   
  .DESCRIPTION
    The Remove-RCopyGroup command removes a remote-copy volume group or multiple remote-copy groups that match a given pattern.	
   
  .EXAMPLE  
	Remove-RCopyGroup -Pat -GroupName testgroup*	
	This example Removes remote-copy groups that start with the name testgroup	
   
  .EXAMPLE  
	Remove-RCopyGroup -KeepSnap -GroupName group1	
	This example Removes the remote-copy group (group1) and retains the resync snapshots associated with each volume
		
  .PARAMETER Pat
	Specifies that specified patterns are treated as glob-style patterns and that all remote-copy groups matching the specified pattern will be removed.
				
  .PARAMETER KeepSnap
	Specifies that the local volume's resync snapshot should be retained.
	
  .PARAMETER RemoveVV
	Remove remote sides' volumes.	
	
  .PARAMETER GroupName      
	The name of the group that currently includes the target.

  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  Remove-RCopyGroup
    LASTEDIT: December 2019
    KEYWORDS: Remove-RCopyGroup
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[switch]
		$RemoveVV,
		
		[Parameter(Position=1, Mandatory=$false)]
		[switch]
		$KeepSnap,
		
		[Parameter(Position=2, Mandatory=$false)]
		[switch]
		$Pat,
		
		[Parameter(Position=3, Mandatory=$false)]
		[System.String]
		$GroupName,
				
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)		
	
	Write-DebugLog "Start: In Remove-RCopyGroup  - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting Remove-RCopyGroup since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Remove-RCopyGroupsince no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}		
	$cmd= "removercopygroup -f "	
	if ($RemoveVV)
	{
		$cmd+=" -removevv "
	}	
	if ($KeepSnap)
	{
		$cmd+=" -keepsnap "
	}
	if ($Pat)
	{
		$cmd+=" -pat "
	}
	if ($GroupName)
	{
		$cmd1= "showrcopy"
		$Result1 = Invoke-CLICommand -Connection $SANConnection -cmds  $cmd1
		if ($Result1 -match $GroupName )
		{
			$cmd+=" $GroupName "
		}
		else
		{
			Write-DebugLog "Stop: Exiting  Remove-RCopyGroup  GroupName in unavailable "
			Return "FAILURE : -GroupName $GroupName  is Unavailable . "
		}		
	}		
	else
	{
		Write-DebugLog "Stop: GroupName is mandatory" $Debug
		return "Error :  -GroupName is mandatory. "			
	}		
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $cmd	
	write-debuglog "  Executing Remove-RCopyGroup  command removes a remote-copy volume group or multiple remote-copy groups that match a given pattern." "INFO:" 	
	if($Result -match "deleted")
	{
		return  "Success : Remove-RCopyGroup Command `n $Result  "
	}
	else
	{
		return  "FAILURE : While Executing Remove-RCopyGroup $Result "
	} 	
} # End Remove-RCopyGroup

####################################################################################################################
## FUNCTION Remove-RCopyTarget
####################################################################################################################
Function Remove-RCopyTarget
{
<#
  .SYNOPSIS
   The Remove-RCopyTarget command command removes target designation from a remote-copy system and removes all links affiliated with that target definition.   
   
  .DESCRIPTION
   The Remove-RCopyTarget command command removes target designation from a remote-copy system and removes all links affiliated with that target definition.   
 
  .EXAMPLE  
	Remove-RCopyTarget -ClearGroups -TargetName demovv1
    This Example removes target designation from a remote-copy system & Remove all groups.
		
  .PARAMETER ClearGroups :	Remove all groups that have no other targets or dismiss this target from groups with additional targets.
		
  .PARAMETER TargetName      
	The name of the group that currently includes the target.

  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  Remove-RCopyTarget
    LASTEDIT: December 2019
    KEYWORDS: Remove-RCopyTarget
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
		$ClearGroups,
		
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$TargetName,
				
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)		
	
	Write-DebugLog "Start: In Remove-RCopyTarget  - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting Remove-RCopyTarget since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Remove-RCopyTargetsince no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}	
	$cmd= "removercopytarget -f "
	if ($ClearGroups)
	{
		$cmd+=" -cleargroups "
	}		
	if ($TargetName)
	{
		$cmd+=" $TargetName "	
	}
	else
	{
		Write-DebugLog "Stop: TargetName is mandatory" $Debug
		return "Error :  -TargetName is mandatory. "			
	}	
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $cmd
	write-debuglog "  Executing Remove-RCopyTarget  command removes target designation from a remote-copy system and removes all links affiliated with that target definitionusing. cmd   " "INFO:" 	
	if([string]::IsNullOrEmpty($Result))
	{
		return  "Success : Remove-RCopyTarget   "
	}
	else
	{
		return  "FAILURE : While Executing Remove-RCopyTarget $Result  "
	} 
} # End Remove-RCopyTarget

####################################################################################################################
## FUNCTION Remove-RCopyTargetFromGroup
####################################################################################################################
Function Remove-RCopyTargetFromGroup
{
<#
  .SYNOPSIS
   The Remove-RCopyTargetFromGroup removes a remote-copy target from a remote-copy volume group.
   
 .DESCRIPTION
   The Remove-RCopyTargetFromGroup removes a remote-copy target from a remote-copy volume group.
   
  .EXAMPLE
	Remove-RCopyTargetFromGroup -TargetName target1 -GroupName group1
   The following example removes target Target1 from Group1.
	
  .PARAMETER TargetName     
	The name of the target to be removed.
	
  .PARAMETER GroupName      
	The name of the group that currently includes the target.

  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  Remove-RCopyTargetFromGroup
    LASTEDIT: December 2019
    KEYWORDS: Remove-RCopyTargetFromGroup
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$TargetName,
		
		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$GroupName,
				
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)		
	Write-DebugLog "Start: In Remove-RCopyTargetFromGroup  - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting Remove-RCopyTargetFromGroup since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Remove-RCopyTargetFromGroup since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}		
	$cmd= "dismissrcopytarget -f "	
	if ($TargetName)
	{		
		$cmd+=" $TargetName "
	}
	else
	{
		Write-DebugLog "Stop: TargetName is mandatory" $Debug
		return "Error :  -TargetName is mandatory. "		
	}
	if ($GroupName)
	{
		$cmd1= "showrcopy"
		$Result1 = Invoke-CLICommand -Connection $SANConnection -cmds  $cmd1
		if ($Result1 -match $GroupName )
		{
			$cmd+=" $GroupName "
		}
		else
		{
			Write-DebugLog "Stop: Exiting  Remove-RCopyTargetFromGroup GroupName in unavailable "
			Return "FAILURE : -GroupName $GroupName is Unavailable to execute. "
		}
	}
	else
	{
		Write-DebugLog "Stop: GroupName is mandatory" $Debug
		return "Error :  -GroupName is mandatory. "
	}
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $cmd
	write-debuglog "  Executing Remove-RCopyTargetFromGroup removes a remote-copy target from a remote-copy volume group.using cmd   " "INFO:" 
	return  "$Result"
} # End Remove-RCopyTargetFromGroup

####################################################################################################################
## FUNCTION Set-RCopyGroupPeriod
####################################################################################################################
Function Set-RCopyGroupPeriod
{
<#
  .SYNOPSIS
  Sets a resynchronization period for volume groups in asynchronous periodic mode.
   
  .DESCRIPTION
	Sets a resynchronization period for volume groups in asynchronous periodic mode.   
	
  .EXAMPLE
	Set-RCopyGroupPeriod -Period 10m -TargetName CHIMERA03 -GroupName AS_TEST

  .EXAMPLE
	Set-RCopyGroupPeriod -Period 10m -Force -TargetName CHIMERA03 -GroupName AS_TEST

  .EXAMPLE
	Set-RCopyGroupPeriod -Period 10m -T 1 -TargetName CHIMERA03 -GroupName AS_TEST

  .EXAMPLE
	Set-RCopyGroupPeriod -Period 10m -Stopgroups -TargetName CHIMERA03 -GroupName AS_TEST

  .EXAMPLE
	Set-RCopyGroupPeriod -Period 10m -Local -TargetName CHIMERA03 -GroupName AS_TEST

  .EXAMPLE
	Set-RCopyGroupPeriod -Period 10m -Natural -TargetName CHIMERA03 -GroupName AS_TEST	
  
  .PARAMETER PeriodValue
	Specifies the time period in units of seconds (s), minutes (m), hours (h), or days (d), for automatic resynchronization (for example, 14h for 14 hours).
		
  .PARAMETER TargetName
	Specifies the target name for the target definition
	
  .PARAMETER GroupName
	Specifies the name of the volume group whose policy is set, or whose target direction is switched.
	
  .PARAMETER T
	When used with <dr_operation> subcommands, specifies the target to which
	the <dr_operation> command applies to.  This is optional for single
	target groups, but is required for multi-target groups. If no groups are
	specified, it applies to all relevant groups. When used with the pol subcommand,
	specified for a group with multiple targets then the command only applies to
	that target, otherwise it will be applied to all targets.

	NOTE: The -t option without the groups listed in the command, will only work
	in a unidirectional configuration. For bidirectional configurations, the -t
	option must be used along with the groups listed in the command.

  .PARAMETER Force
	Does not ask for confirmation for disaster recovery commands.

  .PARAMETER Nostart
	Specifies that groups are not started after role reversal is completed.
	This option can be used for failover, recover and restore subcommands.

  .PARAMETER Nosync
	Specifies that groups are not synced after role reversal is completed
	through the recover, restore and failover specifiers.

  .PARAMETER Discard
	Specifies not to check a group's other targets to see if newer data
	should be pushed from them if the group has multiple targets. The use
	of this option can result in the loss of the most recent changes to
	the group's volumes and should be used carefully. This option is only
	valid for the failover specifier.

  .PARAMETER Nopromote
	This option is only valid for the failover and reverse specifiers.  When
	used with the reverse specifier, specifies that the synchronized snapshots
	of groups that are switched from primary to secondary not be promoted to
	the base volume. When used with the failover specifier, it indicates that
	snapshots of groups that are switched from secondary to primary should not
	be promoted to the base volume in the case where all volumes of the group
	were not synchronized to the same time point.
	The incorrect use of this option can lead to the primary secondary volumes
	not being consistent.

  .PARAMETER Nosnap
	Specifies that snapshots are not taken of groups that are switched from
	secondary to primary. Additionally, existing snapshots are deleted
	if groups are switched from primary to secondary. The use of this option
	may result in a full synchronization of the secondary volumes. This
	option can be used for failover, restore, and reverse subcommands.

  .PARAMETER Stopgroups
	Specifies that groups are stopped before running the reverse subcommand.
	
  .PARAMETER Local
	The -local option only applies to the "reverse" operation and then
	only when the -natural or -current options to the "reverse" operation
	are specified. Specifying -local with the "reverse" operation and an
	associated -natural or -current option will only affect the array
	where the command is issued and will not be mirrored to any other
	arrays in the Remote Copy configuration.

  .PARAMETER Natural
	Specifying the -natural option with the "reverse" operation changes
	the role of the groups but not the direction of data flow between the
	groups on the arrays. For example, if the role of the groups are
	"primary" and "secondary", issuing the -natural option with the
	"reverse" operation will result in the role of the groups becoming
	"primary-rev" and "secondary-rev" respectively. The direction of data
	flow between the groups is not affected only the roles. Since the
	-natural option does not change the direction of data flow between
	groups it does not require the groups be stopped.

  .PARAMETER Current
	Specifying the -current option with the "reverse" operation changes
	both the role and the direction of data flow between the groups. For
	example, if the roles of the groups are "primary" and "secondary",
	issuing the -current option to the "reverse" operation will result in
	the roles of the group becoming "secondary-rev" and "primary-rev"
	respectively and the direction data flow between the groups is
	reversed. Since the -current option actually reverses the direction of
	data replication it requires the group be stopped.

	Both the -natural and -current options must be used with care to
	ensure the Remote Copy groups do not end up in a non-deterministic
	state (like "secondary", "secondary-rev" for example) and to ensure
	data loss does not occur by inadvertently changing the direction of
	data flow and re-syncing old data on top of newer data.

  .PARAMETER Waittask
	Wait for all tasks created by this command to complete before returning.
	This option applies to the failover, recover, restore, and reverse subcommands.

  .PARAMETER Pat
	Specifies that specified patterns are treated as glob-style patterns
	and all remote copy groups matching the specified pattern will be
	set. The -pat option can specify a list of patterns. This option must be used
	if <pattern> specifier is used.

  .PARAMETER Usr_cpg 
	Specifies the local user CPG and target user CPG that will be used for
	volumes that are auto-created. The local CPG will only be used after failover
	and recover.

  .PARAMETER Snp_cpg 
	Specifies the local snap CPG and target snap CPG that will be used for
	volumes that are auto-created. The local CPG will only be used after failover
	and recover.

  .PARAMETER Usr_cpg_unset
	Unset all user CPGs that are associated with this group.
  .PARAMETER Snp_cpg_unset
	Unset all snap CPGs that are associated with this group.
	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-PoshSshConnection Or New-CLIConnection
	
  .Notes
    NAME:  Set-RCopyGroupPeriod
    LASTEDIT: December 2019
    KEYWORDS: Set-RCopyGroupPeriod
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$PeriodValue,
		
		[Parameter(Position=1, Mandatory=$false)]
		[Switch]
		$Force,
		
		[Parameter(Position=2, Mandatory=$false)]
		[System.String]
		$T,	
		
		[Parameter(Position=3, Mandatory=$false)]
		[Switch]
		$Nostart,
		
		[Parameter(Position=4, Mandatory=$false)]
		[Switch]
		$Nosync,
		
		[Parameter(Position=5, Mandatory=$false)]
		[Switch]
		$Discard,
		
		[Parameter(Position=6, Mandatory=$false)]
		[Switch]
		$Nopromote,
		
		[Parameter(Position=7, Mandatory=$false)]
		[Switch]
		$Nosnap,
		
		[Parameter(Position=8, Mandatory=$false)]
		[Switch]
		$Stopgroups,
		
		[Parameter(Position=9, Mandatory=$false)]
		[Switch]
		$Local,
		
		[Parameter(Position=10, Mandatory=$false)]
		[Switch]
		$Natural,
		
		[Parameter(Position=11, Mandatory=$false)]
		[Switch]
		$Current,
		
		[Parameter(Position=12, Mandatory=$false)]
		[Switch]
		$Waittask,
		
		[Parameter(Position=13, Mandatory=$false)]
		[Switch]
		$Pat,
		
		[Parameter(Position=14, Mandatory=$false)]
		[System.String]
		$Usr_cpg,
		
		[Parameter(Position=15, Mandatory=$false)]
		[System.String]
		$Snp_cpg,
		
		[Parameter(Position=16, Mandatory=$false)]
		[Switch]
		$Usr_cpg_unset,
		
		[Parameter(Position=17, Mandatory=$false)]
		[Switch]
		$Snp_cpg_unset,
		
		[Parameter(Position=18, Mandatory=$false)]
		[System.String]
		$TargetName,
		
		[Parameter(Position=19, Mandatory=$false)]
		[System.String]
		$GroupName,
		
		[Parameter(Position=20, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection
	)			
	Write-DebugLog "Start: In Set-RCopyGroupPeriod   - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting Set-RCopyGroupPeriod since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Set-RCopyGroupPeriod since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}
		
	$cmd= "setrcopygroup period "
		
	if($Force)
	{
		$cmd+= " -f "
	}
	if($T)
	{
		$cmd+= " -t $T "
	}
	if($Nostart)
	{
		$cmd+= " -nostart "
	}
	if($Nosync)
	{
		$cmd+= " -nosync "
	}
	if($Discard)
	{
		$cmd+= " -discard "
	}
	if($Nopromote)
	{
		$cmd+= " -nopromote "
	}
	if($Nosnap)
	{
		$cmd+= " -nosnap "
	}
	if($Stopgroups)
	{
		$cmd+= " -stopgroups "
	}
	if($Local)
	{
		$cmd+= " -local "
	}
	if($Natural)
	{
		$cmd+= " -natural "
	}
	if($Current)
	{
		$cmd+= " -current "
	}	
	if($Waittask)
	{
		$cmd+= " -waittask "
	}	
	if($Pat)
	{
		$cmd+= " -pat "
	}
	if($Usr_cpg)
	{
		$cmd+= " -usr_cpg $Usr_cpg "
	}
	if($Snp_cpg)
	{
		$cmd+= " -snp_cpg $Snp_cpg "
	}	
	if($Usr_cpg_unset)
	{
		$cmd+= " -usr_cpg_unset "
	}
	if($Snp_cpg_unset)
	{
		$cmd+= " -snp_cpg_unset "
	}	
	if ($PeriodValue)
	{
		$p=$PeriodValue[-1]
		$s = "s | m | h | d"	 			
		if($s -match $p)
		{
			$cmd+=" $PeriodValue "
		}
		else
		{
			return " ERROR : -Period $PeriodValue is not Valid . use [ s | m | h |  d ] Only, Ex: -Period 10s "	
		}
	}
	else
	{
		Write-DebugLog "Stop: Period is mandatory" $Debug
		return "Error : -Period is mandatory. "			
	}
	if ($TargetName)
	{
		$cmd+= " $TargetName "
	}
	else
	{
		Write-DebugLog "Stop: TargetName is mandatory" $Debug
		return "Error :  -TargetName is mandatory. "
	}	
	if ($GroupName)
	{
		$cmd+= " $GroupName "
	}
	else
	{
		Write-DebugLog "Stop: GroupName is mandatory" $Debug
		return "Error :  -GroupName is mandatory. "
	}
	
	
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $cmd	
	write-debuglog "  Executing Set-RCopyGroupPeriod using cmd   " "INFO:" 
	if([string]::IsNullOrEmpty($Result))
	{
		return  "Success : Executing Set-RCopyGroupPeriod Command "
	}
	else
	{
		return  "FAILURE : While Executing Set-RCopyGroupPeriod  $Result"
	} 
} # End Set-RCopyGroupPeriod

####################################################################################################################
## FUNCTION Set-RCopyGroupPol
####################################################################################################################
Function Set-RCopyGroupPol
{
<#
  .SYNOPSIS
    Sets the policy of the remote-copy volume group for dealing with I/O failure and error handling.
   
  .DESCRIPTION
	Sets the policy of the remote-copy volume group for dealing with I/O failure and error handling.
    
  .EXAMPLE	
	Set-RCopyGroupPol -policy test -GroupName AS_TEST

  .EXAMPLE
	Set-RCopyGroupPol -policy auto_failover -GroupName AS_TEST

  .EXAMPLE
	Set-RCopyGroupPol -Force -policy auto_failover -GroupName AS_TEST

  .EXAMPLE
	Set-RCopyGroupPol -T 1 -policy auto_failover -GroupName AS_TEST

  .EXAMPLE
	Set-RCopyGroupPol -Stopgroups -policy auto_failover -GroupName AS_TEST

  .EXAMPLE
	Set-RCopyGroupPol -Local -policy auto_failover -GroupName AS_TEST

  .EXAMPLE
	Set-RCopyGroupPol -Natural -policy auto_failover -GroupName AS_TEST

  .EXAMPLE
	Set-RCopyGroupPol -policy no_auto_failover -GroupName AS_TEST

  .EXAMPLE
	Set-RCopyGroupPol -Force -policy no_auto_failover -GroupName AS_TEST

  .EXAMPLE
	Set-RCopyGroupPol -T 1 -policy no_auto_failover -GroupName AS_TEST
	
   .PARAMETER T
	When used with <dr_operation> subcommands, specifies the target to which
	the <dr_operation> command applies to.  This is optional for single
	target groups, but is required for multi-target groups. If no groups are
	specified, it applies to all relevant groups. When used with the pol subcommand,
	specified for a group with multiple targets then the command only applies to
	that target, otherwise it will be applied to all targets.

	NOTE: The -t option without the groups listed in the command, will only work
	in a unidirectional configuration. For bidirectional configurations, the -t
	option must be used along with the groups listed in the command.

  .PARAMETER Force
	Does not ask for confirmation for disaster recovery commands.

  .PARAMETER Nostart
	Specifies that groups are not started after role reversal is completed.
	This option can be used for failover, recover and restore subcommands.

  .PARAMETER Nosync
	Specifies that groups are not synced after role reversal is completed
	through the recover, restore and failover specifiers.

  .PARAMETER Discard
	Specifies not to check a group's other targets to see if newer data
	should be pushed from them if the group has multiple targets. The use
	of this option can result in the loss of the most recent changes to
	the group's volumes and should be used carefully. This option is only
	valid for the failover specifier.

  .PARAMETER Nopromote
	This option is only valid for the failover and reverse specifiers.  When
	used with the reverse specifier, specifies that the synchronized snapshots
	of groups that are switched from primary to secondary not be promoted to
	the base volume. When used with the failover specifier, it indicates that
	snapshots of groups that are switched from secondary to primary should not
	be promoted to the base volume in the case where all volumes of the group
	were not synchronized to the same time point.
	The incorrect use of this option can lead to the primary secondary volumes
	not being consistent.

  .PARAMETER Nosnap
	Specifies that snapshots are not taken of groups that are switched from
	secondary to primary. Additionally, existing snapshots are deleted
	if groups are switched from primary to secondary. The use of this option
	may result in a full synchronization of the secondary volumes. This
	option can be used for failover, restore, and reverse subcommands.

  .PARAMETER Stopgroups
	Specifies that groups are stopped before running the reverse subcommand.
	
  .PARAMETER Local
	The -local option only applies to the "reverse" operation and then
	only when the -natural or -current options to the "reverse" operation
	are specified. Specifying -local with the "reverse" operation and an
	associated -natural or -current option will only affect the array
	where the command is issued and will not be mirrored to any other
	arrays in the Remote Copy configuration.

  .PARAMETER Natural
	Specifying the -natural option with the "reverse" operation changes
	the role of the groups but not the direction of data flow between the
	groups on the arrays. For example, if the role of the groups are
	"primary" and "secondary", issuing the -natural option with the
	"reverse" operation will result in the role of the groups becoming
	"primary-rev" and "secondary-rev" respectively. The direction of data
	flow between the groups is not affected only the roles. Since the
	-natural option does not change the direction of data flow between
	groups it does not require the groups be stopped.

  .PARAMETER Current
	Specifying the -current option with the "reverse" operation changes
	both the role and the direction of data flow between the groups. For
	example, if the roles of the groups are "primary" and "secondary",
	issuing the -current option to the "reverse" operation will result in
	the roles of the group becoming "secondary-rev" and "primary-rev"
	respectively and the direction data flow between the groups is
	reversed. Since the -current option actually reverses the direction of
	data replication it requires the group be stopped.

	Both the -natural and -current options must be used with care to
	ensure the Remote Copy groups do not end up in a non-deterministic
	state (like "secondary", "secondary-rev" for example) and to ensure
	data loss does not occur by inadvertently changing the direction of
	data flow and re-syncing old data on top of newer data.

  .PARAMETER Waittask
	Wait for all tasks created by this command to complete before returning.
	This option applies to the failover, recover, restore, and reverse subcommands.

  .PARAMETER Pat
	Specifies that specified patterns are treated as glob-style patterns
	and all remote copy groups matching the specified pattern will be
	set. The -pat option can specify a list of patterns. This option must be used
	if <pattern> specifier is used.

  .PARAMETER Usr_cpg 
	Specifies the local user CPG and target user CPG that will be used for
	volumes that are auto-created. The local CPG will only be used after failover
	and recover.

  .PARAMETER Snp_cpg 
	Specifies the local snap CPG and target snap CPG that will be used for
	volumes that are auto-created. The local CPG will only be used after failover
	and recover.

  .PARAMETER Usr_cpg_unset
	Unset all user CPGs that are associated with this group.
	
  .PARAMETER Snp_cpg_unset
	Unset all snap CPGs that are associated with this group.
   
  .PARAMETER policy 
	auto_failover	:	Configure automatic failover on a remote-copy group.
	
	no_auto_failover	:	Remote-copy groups will not be subject to automatic fail-over (default).
	
	auto_recover	:	Specifies that if the remote copy is stopped as a result of the remote-copy links going down,	the group is restarted automatically after the links come back up.
	
	no_auto_recover	:	Specifies that if the remote copy is stopped as a result of the remote-copy links going down, the group must be restarted manually after the links come back up (default).
		
	over_per_alert	:	If a synchronization of a periodic remote-copy group takes longer to complete than its synchronization period then an alert will be generated.
	
	no_over_per_alert 	:	If a synchronization of a periodic remote-copy group takes longer to complete than its synchronization period then an alert will not be generated.
	
	path_management	:	Volumes in the specified group will be enabled to support ALUA.
	
	no_path_management	:	ALUA behaviour will be disabled for volumes in the group.	
	
  .PARAMETER GroupName
	Specifies the name of the volume group whose policy is set, or whose target direction is switched.
  
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-PoshSshConnection Or New-CLIConnection
	
  .Notes
    NAME:  Set-RCopyGroupPol
    LASTEDIT: December 2019
    KEYWORDS: Set-RCopyGroupPol
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[Switch]
		$Force,
		
		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$T,	
		
		[Parameter(Position=3, Mandatory=$false)]
		[Switch]
		$Nostart,
		
		[Parameter(Position=4, Mandatory=$false)]
		[Switch]
		$Nosync,
		
		[Parameter(Position=5, Mandatory=$false)]
		[Switch]
		$Discard,
		
		[Parameter(Position=6, Mandatory=$false)]
		[Switch]
		$Nopromote,
		
		[Parameter(Position=7, Mandatory=$false)]
		[Switch]
		$Nosnap,
		
		[Parameter(Position=8, Mandatory=$false)]
		[Switch]
		$Stopgroups,
		
		[Parameter(Position=9, Mandatory=$false)]
		[Switch]
		$Local,
		
		[Parameter(Position=10, Mandatory=$false)]
		[Switch]
		$Natural,
		
		[Parameter(Position=11, Mandatory=$false)]
		[Switch]
		$Current,
		
		[Parameter(Position=12, Mandatory=$false)]
		[Switch]
		$Waittask,
		
		[Parameter(Position=13, Mandatory=$false)]
		[Switch]
		$Pat,
		
		[Parameter(Position=14, Mandatory=$false)]
		[System.String]
		$Usr_cpg,
		
		[Parameter(Position=15, Mandatory=$false)]
		[System.String]
		$Snp_cpg,
		
		[Parameter(Position=16, Mandatory=$false)]
		[Switch]
		$Usr_cpg_unset,
		
		[Parameter(Position=17, Mandatory=$false)]
		[Switch]
		$Snp_cpg_unset,
		
		[Parameter(Position=18, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$policy,
		
		[Parameter(Position=19, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$GroupName,
		
		[Parameter(Position=20, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection
	)	
	Write-DebugLog "Start: In Set-RCopyGroupPol   - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting Set-RCopyGroupPol since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Set-RCopyGroupPol since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}
			
	$cmd= "setrcopygroup pol "
	
	if($Force)
	{
		$cmd+= " -f "
	}
	if($T)
	{
		$cmd+= " -t $T "
	}
	if($Nostart)
	{
		$cmd+= " -nostart "
	}
	if($Nosync)
	{
		$cmd+= " -nosync "
	}
	if($Discard)
	{
		$cmd+= " -discard "
	}
	if($Nopromote)
	{
		$cmd+= " -nopromote "
	}
	if($Nosnap)
	{
		$cmd+= " -nosnap "
	}
	if($Stopgroups)
	{
		$cmd+= " -stopgroups "
	}
	if($Local)
	{
		$cmd+= " -local "
	}
	if($Natural)
	{
		$cmd+= " -natural "
	}
	if($Current)
	{
		$cmd+= " -current "
	}	
	if($Waittask)
	{
		$cmd+= " -waittask "
	}	
	if($Pat)
	{
		$cmd+= " -pat "
	}
	if($Usr_cpg)
	{
		$cmd+= " -usr_cpg $Usr_cpg "
	}
	if($Snp_cpg)
	{
		$cmd+= " -snp_cpg $Snp_cpg "
	}	
	if($Usr_cpg_unset)
	{
		$cmd+= " -usr_cpg_unset "
	}
	if($Snp_cpg_unset)
	{
		$cmd+= " -snp_cpg_unset "
	}
	if ($policy )
	{
		$s = " auto_failover | no_auto_failover | auto_recover | no_auto_recover | over_per_alert | no_over_per_alert | path_management	| no_path_management "
	 	$demo = $policy
		if($s -match $demo)
		{
			$cmd+=" $policy "
		}
		else
		{
			return " FAILURE : -policy $policy is not Valid . use [$s] Only.  "	
		}
	}
	else
	{
		Write-DebugLog "Stop: policy is mandatory" $Debug
		return "Error :  -policy is mandatory. "
	}
	if ($GroupName)
	{		
		$cmd+="$GroupName "			
	}
	else
	{
		Write-DebugLog "Stop: GroupName is mandatory" $Debug
		return "Error :  -GroupName is mandatory. "			
	}	
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $cmd	
	write-debuglog "  Executing Set-RCopyGroupPol using cmd    " "INFO:"	
	if([string]::IsNullOrEmpty($Result))
	{
		return  "Success : Executing Set-RCopyGroupPol Command "
	}
	else
	{
		return  "FAILURE : While Executing Set-RCopyGroupPol $Result "
	} 	
} # End Set-RCopyGroupPol

####################################################################################################################
## FUNCTION Set-RCopyTarget
####################################################################################################################
Function Set-RCopyTarget
{
<#
  .SYNOPSIS
	The Set-RCopyTarget Changes the name of the indicated target using the <NewName> specifier.
   
  .DESCRIPTION
	The Set-RCopyTarget Changes the name of the indicated target using the <NewName> specifier.  
	
  .EXAMPLE
	Set-RCopyTarget -Enable -TargetName Demo1
	This Example Enables  the targetname Demo1.
	
  .EXAMPLE
	Set-RCopyTarget -Disable -TargetName Demo1
	This Example disables  the targetname Demo1.  
	
  .PARAMETER Enables/Disable 
	specify enable or disable 
 
  .PARAMETER TargetName  
	Specifies the target name 
  
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection		
  
  .Notes
    NAME: Set-RCopyTarget
    LASTEDIT: December 2019
    KEYWORDS: Set-RCopyTarget
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
		$Enable ,
		
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
		$Disable ,
		
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$TargetName,
		
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)			
	Write-DebugLog "Start: In Set-RCopyTarget  - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting Set-RCopyTarget since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Set-RCopyTarget since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}	
	$cmd= "setrcopytarget "
	if ($Enable)
	{	
		$cmd += " enable "
	}
	elseif ($Disable)
	{	
		$cmd += " disable "
	}
	else
	{
		Write-DebugLog "Stop: Option  is mandatory" $Debug
		return "Error :  At-list select any one of them Enable/Disable. "			
	}	
	if ($TargetName)
	{
		$cmd+=" $TargetName "
	}
	else
	{
		Write-DebugLog "Stop: TargetName is mandatory" $Debug
		return "Error :  -TargetName is mandatory. "			
	}	
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $cmd	
	write-debuglog "  Executing Set-RCopyTarget Changes the name of the indicated target   " "INFO:" 
	if([string]::IsNullOrEmpty($Result))
	{
		return  "Success : Executing Set-RCopyTarget $Result"
	}
	else
	{
		return  "FAILURE : While Executing Set-RCopyTarget $Result "
	} 	
} # End Set-RCopyTarget

####################################################################################################################
## FUNCTION Set-RCopyTargetName
####################################################################################################################
Function Set-RCopyTargetName
{
<#
  .SYNOPSIS
	The Set-RCopyTargetName Changes the name of the indicated target using the <NewName> specifier.
   
  .DESCRIPTION
	The Set-RCopyTargetName Changes the name of the indicated target using the <NewName> specifier.
  
  .EXAMPLE
	Set-RCopyTargetName -NewName DemoNew1  -TargetName Demo1
	This Example Changes the name of the indicated target using the -NewName demoNew1.   
	
  .PARAMETER NewName 
	The new name for the indicated target. 
 
  .PARAMETER TargetName  
	Specifies the target name for the target definition.
  
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection	
	  
  .Notes
    NAME: Set-RCopyTargetName
    LASTEDIT: December 2019
    KEYWORDS: Set-RCopyTargetName
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$NewName,
		
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$TargetName,
		
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)		
	
	Write-DebugLog "Start: In Set-RCopyTargetName  - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting Set-RCopyTargetName  since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Set-RCopyTargetName since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}	
	$cmd= "setrcopytarget name "
	if ($NewName)
	{
		$cmd+="$NewName "
	}
	else
	{
		Write-DebugLog "Stop: NewName is mandatory" $Debug
		return "Error :  -NewName is mandatory. "			
	}	
	if ($TargetName)
	{
		$cmd+="$TargetName "
	}
	else
	{
		Write-DebugLog "Stop: TargetName is mandatory" $Debug
		return "Error :  -TargetName is mandatory. "			
	}	
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $cmd	
	write-debuglog "  Executing Set-RCopyTargetName Changes the name of the indicated target   " "INFO:" 
	if([string]::IsNullOrEmpty($Result))
	{
		return  "Success : Executing Set-RCopyTargetName $Result"
	}
	else
	{
		return  "FAILURE : While Executing Set-RCopyTargetName $Result "
	} 	
} # End Set-RCopyTargetName

####################################################################################################################
## FUNCTION Set-RCopyTargetPol
####################################################################################################################
Function Set-RCopyTargetPol
{
<#
  .SYNOPSIS
  The Set-RCopyTargetPol command Sets the policy for the specified target using the <policy> specifier
   
  .DESCRIPTION
	The Set-RCopyTargetPol command Sets the policy for the specified target using the <policy> specifier

  .EXAMPLE
	Set-RCopyTargetPol -Mmirror_Config -Target vv3
	This Example sets the policy that all configuration commands,involving the specified target are duplicated for the target named vv3.   	

  .PARAMETER Mirror_Config
	Specifies that all configuration commands,involving the specified target are duplicated.

  .PARAMETER No_Mirror_Config
	If not specified, all configuration commands are duplicated.	

  .PARAMETER Target
	Specifies the target name for the target definition.

  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection

  .PARAMETER	Note
	That the no_mirror_config specifier should only be used to allow recovery from an unusual error condition and only used after consulting your HPE representative.

  .Notes
	NAME: Set-RCopyTargetPol
	LASTEDIT: December 2019
	KEYWORDS: Set-RCopyTargetPol
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
		$Mirror_Config,
		
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
		$No_Mirror_Config,
		
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$Target,
		
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)		
	Write-DebugLog "Start: In Set-RCopyTargetPol   - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting Set-RCopyTargetPol since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Set-RCopyTargetPol since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}	
	$cmd= "setrcopytarget pol "
	if ($Mirror_Config)
	{
		$cmd+=" mirror_config "
	}
	elseif($No_Mirror_Config)
	{
			$cmd+=" no_mirror_config "
	}
	else
	{
		Write-DebugLog "Stop: policy is mandatory" $Debug
		return "Error :  Please select at-list any one from Mirror_Config/No_Mirror_Config. "			
	}
	if ($Target)
	{
		$cmd+="$Target "
	}
	else
	{
		Write-DebugLog "Stop: Target is mandatory" $Debug
		return "Error :  -Target is mandatory. "			
	}	
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $cmd	
	write-debuglog "  Executing Set-RCopyTargetPol Command Sets the policy for the specified target using the <policy> specifier." "INFO:" 
	if([string]::IsNullOrEmpty($Result))
	{
		return  "Success : Executing Set-RCopyTargetPol Command "
	}
	else
	{
		return  "FAILURE : While Executing Set-RCopyTargetPol $result "
	} 
} # End Set-RCopyTargetPol

####################################################################################################################
## FUNCTION Set-RCopyTargetWitness
####################################################################################################################
Function Set-RCopyTargetWitness
{
<#
  .SYNOPSIS
	The Set-RCopyTargetWitness Changes the name of the indicated target using the <NewName> specifier.
   
  .DESCRIPTION
	The Set-RCopyTargetWitness Changes the name of the indicated target using the <NewName> specifier.
  
  .EXAMPLE
	Set-RCopyTargetWitness -SubCommand create -Witness_ip 1.2.3.4 -Target TEST
	This Example Changes the name of the indicated target using the -NewName demoNew1.
		
  .EXAMPLE	
	Set-RCopyTargetWitness -SubCommand create -Remote -Witness_ip 1.2.3.4 -Target TEST
	
  .EXAMPLE
	Set-RCopyTargetWitness -SubCommand start -Target TEST
  
  .EXAMPLE
	Set-RCopyTargetWitness -SubCommand stop  -Target TEST
  
  .EXAMPLE  
	Set-RCopyTargetWitness -SubCommand remove -Remote -Target TEST
  
  .EXAMPLE  
	Set-RCopyTargetWitness -SubCommand check  -Node_id 1 -Witness_ip 1.2.3.4
  
  .PARAMETER SubCommand 
	Sub Command like create, Start, Stop, Remove and check.				
	create
	Create an association between a synchronous target and a Quorum Witness (QW)
	as part of a Peer Persistence configuration.
	start|stop|remove
	Activate, deactivate and remove the ATF configuration.
	check
	Check connectivity to Quorum Witness.
		
 .PARAMETER Remote
	Used to forward a witness subcommand to the be executed on the
	remote Storage System. When used in conjunction with the
	"witness check" subcommand the target must be specified - when executing
	on the local storage system target specification is not required to check
	connectivity with the Quorum Witness.
	
  .PARAMETER Witness_ip
	The IP address of the Quorum Witness (QW) application, to which the
	Storage System will connect to update its status periodically.
		
  .PARAMETER Target			
	Specifies the target name for the target definition previously created
	with the creatercopytarget command.
  
  .PARAMETER Node_id	
	Nodee id with node option
	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection	
	  
  .Notes
    NAME: Set-RCopyTargetWitness
    LASTEDIT: December 2019
    KEYWORDS: Set-RCopyTargetWitness
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$SubCommand,
		
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
		$Remote,
		
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$Witness_ip,
		
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$Target,
		
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$Node_id,
		
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)		
	
	Write-DebugLog "Start: In Set-RCopyTargetWitness  - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting Set-RCopyTargetWitness  since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Set-RCopyTargetWitness since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}
	if($SubCommand)
	{
		$Scmd  = "create","start","stop","remove","check"
		if($Scmd -eq $SubCommand)
		{		
			if($SubCommand -eq "create")
			{
				if($Witness_ip -And $Target)
				{
					$cmd= "setrcopytarget witness $SubCommand"	
					if ($Remote)
					{
						$cmd += " -remote "
					}
					$cmd +=" $Witness_ip $Target"
					#write-host "$cmd"
					$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $cmd	
					write-debuglog "  Executing Set-RCopyTargetWitness Changes the name of the indicated target   " "INFO:" 
					if([string]::IsNullOrEmpty($Result))
					{
						return  "Success : Executing Set-RCopyTargetWitness Command`n$result "
					}
					else
					{
						return  "FAILURE : While Executing Set-RCopyTargetWitness`n$result "
					} 
				}		
				else
				{
					write-debugLog "witness_ip, target missing or anyone of them are missing." "ERR:" 
					return "FAILURE : witness_ip, target missing or anyone of them are missing."
				}
			}
			elseif($SubCommand -eq "start" -Or $SubCommand -eq "stop" -Or $SubCommand -eq "remove")
			{
				if($Target)
				{
					$cmd= "setrcopytarget witness $SubCommand"	
					if ($Remote)
					{
						$cmd += " -remote "
					}
					$cmd +=" $Target"
					#write-host "$cmd"
					$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $cmd	
					write-debuglog "  Executing Set-RCopyTargetWitness Changes the name of the indicated target   " "INFO:" 
					if([string]::IsNullOrEmpty($Result))
					{
						return  "Success : Executing Set-RCopyTargetWitness Command`n$result "
					}
					else
					{
						return  "FAILURE : While Executing Set-RCopyTargetWitness`n$result "
					} 
				}		
				else
				{
					write-debugLog "Target is missing." "ERR:" 
					return "FAILURE : Target is missing."
				}
			}
			elseif($SubCommand -eq "check")
			{
				if($Witness_ip)
				{
					$cmd= "setrcopytarget witness $SubCommand"	
					if ($Remote)
					{
						$cmd += " -remote "
					}
					if($Node_Id)
					{
						$cmd += " -node $Node_Id "
					}
					$cmd +=" $Witness_ip $Target"
					#write-host "$cmd"
					$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $cmd	
					write-debuglog "  Executing Set-RCopyTargetWitness Changes the name of the indicated target   " "INFO:" 
					if([string]::IsNullOrEmpty($Result))
					{
						return  "Success : Executing Set-RCopyTargetWitness Command`n$result "
					}
					else
					{
						return  "FAILURE : While Executing Set-RCopyTargetWitness`n$result "
					} 
				}		
				else
				{
					write-debugLog "Witness_ip is missing." "ERR:" 
					return "FAILURE : Witness_ip is missing."
				}
			}
			else
			{
				return "Invalid Sub Command, specify value as [witness create | start | stop | remove | check]"
			}
		}
		else
		{
			return "Sub Command should any one of this [witness create | start | stop | remove | check ]"
		}
	}
	else
	{
		return "Sub Command is missing, specify value as [witness create | start | stop | remove | check ]"
	}	
} # End Set-RCopyTargetWitness 

####################################################################################################################
## FUNCTION Show-RCopyTransport
####################################################################################################################
Function Show-RCopyTransport
{
<#
  .SYNOPSIS
    The Show-RCopyTransport command shows status and information about end-to-end transport for Remote Copy in the system.

  .DESCRIPTION
    The Show-RCopyTransport command shows status and information about end-to-end
    transport for Remote Copy in the system.
	
  .EXAMPLE
   Show-RCopyTransport -RCIP
 
  .EXAMPLE
   Show-RCopyTransport -RCFC
     
  .PARAMETER RCIP
	Show information about Ethernet end-to-end transport.

  .PARAMETER RCFC
	Show information about Fibre Channel end-to-end transport.
    
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  Show-RCopyTransport
    LASTEDIT: December 2019
    KEYWORDS: Show-RCopyTransport
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(	
		
		[Parameter(Position=0, Mandatory=$false)]
		[switch]
		$RCIP,
		
		[Parameter(Position=1, Mandatory=$false)]
		[switch]
		$RCFC,
						
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection       
		)	
	
	Write-DebugLog "Start: In Show-RCopyTransport   - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting Show-RCopyTransport since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Show-RCopyTransport since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}	
	
	$cmd= "showrctransport "
	
	if($RCIP)
	{	
		$cmd+=" -rcip "
	}
	if($RCFC)
	{	
		$cmd+=" -rcfc "
	}
			
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $cmd
	$LastItem = $Result.Count 
	write-host "result Count = $LastItem"
	if($LastItem -lt 2)
	{
		return $Result
	}
	write-debuglog " The Show-RCopyTransport command creates and admits physical disk definitions to enable the use of those disks  " "INFO:" 
	$tempFile = [IO.Path]::GetTempFileName()		
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
	
	if($Result -match "N:S:P")
	{
		return  " Success : Executing Show-RCopyTransport "
	}
	else
	{			
		return  $Result
	}
		
} # End Show-RCopyTransport

####################################################################################################################
## FUNCTION Start-RCopy
####################################################################################################################
Function Start-RCopy
{
<#
  .SYNOPSIS
   The Start-RCopy command starts the Remote Copy Service.
   
  .DESCRIPTION
     The Start-RCopy command starts the Remote Copy Service.
   
  .EXAMPLE  
	Start-RCopy 
     command starts the Remote Copy Service.
				
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  Start-RCopy
    LASTEDIT: December 2019
    KEYWORDS: Start-RCopy
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(

		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)			
	Write-DebugLog "Start: In Start-RCopy   - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting Start-RCopy since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Start-RCopysince no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}	
	$cmd= "startrcopy "	
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $cmd
	write-debuglog "  The Start-RCopy command disables the remote-copy functionality for any started remote-copy " "INFO:" 	
	if([string]::IsNullOrEmpty($Result))
	{
		return  "Success : Executing Start-RCopy Command `n $Result "
	}
	else
	{
		return  "FAILURE : While Executing Start-RCopy `n $Result "
	}
} # End Start-RCopy

####################################################################################################################
## FUNCTION Start-RCopyGroup
##################################################################################################################
Function Start-RCopyGroup
{
<#
  .SYNOPSIS
   The Start-RCopyGroup command enables remote copy for the specified remote-copy volume group.
   
 .DESCRIPTION
     The Start-RCopyGroup command enables remote copy for the specified remote-copy volume group.
	
 .EXAMPLE
	Start-RCopyGroup -NoSync -GroupName Group1
	This example starts remote copy for Group1.   
	
 .EXAMPLE  	
	Start-RCopyGroup -NoSync -GroupName Group2 -Volumes_Snapshots "vv1:sv1 vv2:sv2 vv3:sv3"
	This Example  starts Group2, which contains 4 virtual volumes, and specify starting snapshots, with vv4 starting from a full resynchronization.
	
 .PARAMETER NoSync	:	Prevents the initial synchronization and sets the virtual volumes to a synchronized state.
	
 .PARAMETER Wait	:	Specifies that the command blocks until the initial synchronization is complete. The system generates an event when the synchronization is complete.
		
 .PARAMETER Pat		:	Specifies that specified patterns are treated as glob-style patterns and that all remote-copy groups matching the specified pattern will be started.
	 
 .PARAMETER Target
	Indicates that only the group on the specified target is started. If this option is not used, by default,  	the New-RCopyGroup command will affect all of a group’s targets.
	
 .PARAMETER GroupName 
	The name of the remote-copy volume group.
	
  .PARAMETER Volumes_Snapshots 
	 Member volumes and snapshots can be specified by vv:sv syntax, where vv is
	the base volume name and sv is the snapshot volume name. To indicate a full
	resync, specify the starting, read-only snapshot with "-".

  
 .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
 .Notes
    NAME:  Start-RCopyGroup
    LASTEDIT: December 2019
    KEYWORDS: Start-RCopyGroup
   
 .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[switch]
		$NoSync,
		
		[Parameter(Position=1, Mandatory=$false)]
		[switch]
		$Wait,
		
		[Parameter(Position=2, Mandatory=$false)]
		[switch]
		$Pat,
		
		[Parameter(Position=3, Mandatory=$false)]
		[System.String]
		$TargetName,
		
		[Parameter(Position=4, Mandatory=$false)]
		[System.String]
		$GroupName,
		
		[Parameter(Position=5, Mandatory=$false)]
		[System.String]
		$Volumes_Snapshots,
		
		[Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)		
	Write-DebugLog "Start: In Start-RCopyGroup   - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting Start-RCopyGroup since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Start-RCopyGroup since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}		
	$cmd= "startrcopygroup "
	
	if ($NoSync)
	{
		$cmd+= "-nosync "
	}
	if ($Wait)
	{
		$cmd+= "-wait "
	}
	if ($Pat)
	{
		$cmd+= "-pat "
	}
	
	if ($TargetName )
	{
		$cmd+="-t $TargetName  "
	}			
	if ($GroupName)
	{
		$cmd+="$GroupName "
	}
	else
	{
		Write-DebugLog "Stop: GroupName is mandatory" $Debug
		return "Error :  -GroupName is mandatory. "
	}
	if ($Volumes_Snapshots)
	{			
		$cmd+="$Volumes_Snapshots "
	}
	if("startrcopygroup " -eq $cmd )
	{
		get-help Start-RCopyGroup
		return " "
	}	
	#write-host "$cmd"			
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $cmd	
	write-debuglog "  The Start-RCopyGroup command enables remote copy for the specified remote-copy volume group.using   " "INFO:"
	return $Result	
} # End Start-RCopyGroup

####################################################################################################################
## FUNCTION Stop-RCopy
####################################################################################################################
Function Stop-RCopy
{
<#
  .SYNOPSIS
   The Stop-RCopy command disables the remote-copy functionality for any started remote-copy
   
  .DESCRIPTION
     The Stop-RCopy command disables the remote-copy functionality for any started remote-copy
   
  .EXAMPLE  
	Stop-RCopy -StopGroups
   This example disables the remote-copy functionality of all primary remote-copy volume groups
 
  .PARAMETER StopGroups
	Specifies that any started remote-copy volume groups are stopped.
	
  .PARAMETER Clear
	Specifies that configuration entries affiliated with the stopped mode are deleted.
	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  Stop-RCopy
    LASTEDIT: December 2019
    KEYWORDS: Stop-RCopy
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		
		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
		$StopGroups,
		
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
		$Clear,
		
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)	
	Write-DebugLog "Start: In Stop-RCopy   - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting Stop-RCopy since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Stop-RCopysince no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}	
	$cmd= "stoprcopy -f "	
	if ($StopGroups)
	{	
		$cmd+=" -stopgroups "
	}
	if ($Clear)
	{	
		$cmd+=" -clear "
	}
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $cmd
	write-debuglog "  The Stop-RCopy command disables the remote-copy functionality for any started remote-copy " "INFO:" 	
	if($Result -match "Remote Copy config is not started")
	{
		Return "Command Execute Successfully :- Remote Copy config is not started"
	}
	else
	{
		return $Result
	}
} # End Stop-RCopy

####################################################################################################################
## FUNCTION Stop-RCopyGroup
####################################################################################################################
Function Stop-RCopyGroup
{
<#
  .SYNOPSIS
   The Stop-RCopyGroup command stops the remote-copy functionality for the specified remote-copy volume group.
   
  .DESCRIPTION
    The Stop-RCopyGroup command stops the remote-copy functionality for the specified remote-copy volume group.
  	   
  .EXAMPLE  
   Stop-RCopyGroup -NoSnap -GroupName RCFromRMC 	  
   
  .EXAMPLE  
	Stop-RCopyGroup -TargetName RCFC_Romulus_1 -GroupName RCFromRMC 	
 
  .PARAMETER NoSnap
	In synchronous mode, this option turns off the creation of snapshots.
  
  .PARAMETER TargetName
	Indicates that only the group on the specified target is started. If this option is not used, by default,  	the New-RCopyGroup command will affect all of a group’s targets.
	
  .PARAMETER GroupName 
	The name of the remote-copy volume group.
  
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  Stop-RCopyGroup
    LASTEDIT: December 2019
    KEYWORDS: Stop-RCopyGroup
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
		$NoSnap,
		
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$TargetName,
				
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$GroupName,		
		
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)	
	
	Write-DebugLog "Start: In Stop-RCopyGroup   - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting Stop-RCopyGroup since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Stop-RCopyGroup since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}	
	$cmd= "stoprcopygroup -f "
	
	if ($NoSnap)
	{
		$cmd+= " -nosnap "
	}	
	if ($TargetName)
	{
		$cmd+=" -t $TargetName  "
	}
	
	if ($GroupName)
	{
		$cmd1= "showrcopy"
		$Result1 = Invoke-CLICommand -Connection $SANConnection -cmds  $cmd1
		if ($Result1 -match $GroupName )
		{
			$cmd+="$GroupName "
		}
		else
		{
			Write-DebugLog "Stop: Exiting  Stop-RCopyGroup  GroupName in Not Available "
			Return "FAILURE : -GroupName $GroupName  is Not Available Try with a new Name. "				
		}		
	}
	else
	{	
		Write-DebugLog "Stop: GroupName is mandatory" $Debug
		return "Error :  -GroupName is mandatory. "
	}	
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $cmd
	write-debuglog "  The Stop-RCopyGroup command stops the remote-copy functionality for the specified remote-copy volume group. " "INFO:" 
	if([string]::IsNullOrEmpty($Result))
	{
		return  "Success : Executing Stop-RCopyGroup Command $Result"
	}
	else
	{
		return 	$Result
	}
} # End Stop-RCopyGroup

####################################################################################################################
## FUNCTION Sync-RCopy
####################################################################################################################
Function Sync-RCopy
{
<#
  .SYNOPSIS
   The Sync-RCopy command manually synchronizes remote-copy volume groups.
   
  .DESCRIPTION
    The Sync-RCopy command manually synchronizes remote-copy volume groups.
   
  .EXAMPLE
	Sync-RCopy -Wait -TargetName RCFC_Romulus_1 -GroupName AS_TEST1	   
	   
  .EXAMPLE  
	Sync-RCopy -N -TargetName RCFC_Romulus_1 -GroupName AS_TEST1	

  .PARAMETER Wait
	Wait for synchronization to complete before returning to a command prompt.
	
  .PARAMETER N
	Do not save resynchronization snapshot. This option is only relevant for asynchronous periodic mode volume groups.

  .PARAMETER Ovrd
	Force synchronization without prompting for confirmation, even if volumes are already synchronized.
	
  .PARAMETER TargetName
	Indicates that only the group on the specified target is started. If this option is not used, by default,  	the New-RCopyGroup command will affect all of a group’s targets.
	
  .PARAMETER GroupName 
	Specifies the name of the remote-copy volume group to be synchronized.
	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  Sync-RCopy
    LASTEDIT: December 2019
    KEYWORDS: Sync-RCopy
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
		$Wait,
		
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
		$N,
		
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
		$Ovrd,
		
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$TargetName,
		
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$GroupName,
				
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)		
	Write-DebugLog "Start: In Sync-RCopy   - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting Sync-RCopy  since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Sync-RCopysince no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}
	
	$cmd= "syncrcopy "
	
	if ($Wait)
	{
		$cmd+= " -w "
	}
	if ($N)
	{
		$cmd+= " -n "
	}
	if ($Ovrd)
	{
		$cmd+= " -ovrd "
	}
	if ($TargetName)
	{
		$cmd+=" -t $TargetName  "
	}			
	if ($GroupName)
	{		
		$cmd+="$GroupName "			
	}
	else
	{
		Write-DebugLog "Stop: GroupName is mandatory" $Debug
		return "Error :  -GroupName is mandatory. "			
	}			
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $cmd	
	write-debuglog "  The Sync-RCopy command manually synchronizes remote-copy volume groups.-->" "INFO:" 
	return $Result	
} # End Sync-RCopy

####################################################################################################################
## FUNCTION Test-RCopyLink
####################################################################################################################
Function Test-RCopyLink
{
<#checkrclink
  .SYNOPSIS
    The Test-RCopyLink command performs a connectivity, latency, and throughput test between two connected storage systems.

  .DESCRIPTION
    The Test-RCopyLink command performs a connectivity, latency, and throughput
    test between two connected storage systems.
	
  .EXAMPLE
	Test-RCopyLink -StartClient -NSP 0:5:4 -Dest_IP_Addr 1.1.1.1 -Time 20 -Port 1

  .EXAMPLE
	Test-RCopyLink -StartClient -TimeInSeconds 30 -NSP 0:5:4 -Dest_IP_Addr 1.1.1.1 -Time 20 -Port 1 
   
  .EXAMPLE
	Test-RCopyLink -StartClient -FCIP -NSP 0:5:4 -Dest_IP_Addr 1.1.1.1 -Time 20 -Port 1
   
  .EXAMPLE
	Test-RCopyLink -StopClient -NSP 0:5:4
   
  .EXAMPLE
	Test-RCopyLink -StartServer -NSP 0:5:4 
   
  .EXAMPLE
	Test-RCopyLink -StartServer -TimeInSeconds 30 -NSP 0:5:4 -Dest_IP_Addr 1.1.1.2 -Port 1
   
  .EXAMPLE
	Test-RCopyLink -StartServer -FCIP -NSP 0:5:4 -Dest_IP_Addr 1.1.1.2 -Port 1
     
  .EXAMPLE
	Test-RCopyLink -StopServer -NSP 0:5:4
   
  .EXAMPLE
	Test-RCopyLink -PortConn -NSP 0:5:4 
  
  .PARAMETER StartClient
   start the link test
  
  .PARAMETER StopClient
   stop the link test
  
  .PARAMETER StartServer
   start the server
  
  .PARAMETER StopServer
  stop the server
  
  .PARAMETER PortConn
    Uses the Cisco Discovery Protocol Reporter to show display information about devices that are connected to network ports.
  
  .PARAMETER NSP
	Specifies the interface from which to check the link, expressed as
	node:slot:port.
		
  .PARAMETER TimeInSeconds
    Specifies the number of seconds for the test to run using an integer
    from 300 to 172800.  If not specified this defaults to 172800
    seconds (48 hours).

  .PARAMETER FCIP
    Specifies if the link is running over fcip.
    Should only be supplied for FC interfaces.
		
  .PARAMETER Dest_IP_Addr
	Specifies the address of the target system (for example, the IP
	address).
  
  .PARAMETER Time
	Specifies the test duration in seconds.
	Specifies the number of seconds for the test to run using an integer
	from 300 to 172800.
  
  .PARAMETER Port
	Specifies the port on which to run the test. If this specifier is not
	used, the test automatically runs on port 3492.
	 
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  Test-RCopyLink
    LASTEDIT: December 2019
    KEYWORDS: Test-RCopyLink
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(		
		[Parameter(Position=0, Mandatory=$false)]
		[switch]
		$StartClient,
		
		[Parameter(Position=1, Mandatory=$false)]
		[switch]
		$StopClient,
		
		[Parameter(Position=2, Mandatory=$false)]
		[switch]
		$StartServer,
		
		[Parameter(Position=3, Mandatory=$false)]
		[switch]
		$StopServer,
		
		[Parameter(Position=4, Mandatory=$false)]
		[switch]
		$PortConn,
	
		[Parameter(Position=5, Mandatory=$false)]
		[System.String]
		$TimeInSeconds,	

		[Parameter(Position=6, Mandatory=$false)]
		[switch]
		$FCIP,
		
		[Parameter(Position=7, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$NSP,
		
		[Parameter(Position=8, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$Dest_IP_Addr,
		
		[Parameter(Position=9, Mandatory=$false)]
		[System.String]
		$Time,
		
		[Parameter(Position=10, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$Port,
				
		[Parameter(Position=11, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection       
	)	
	
	Write-DebugLog "Start: In Test-RCopyLink   - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting Test-RCopyLink since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Test-RCopyLink since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}
	
	$cmd= "checkrclink "
		
	if($StartClient)
	{
		$cmd += " startclient "
	}
	elseif($StopClient)
	{
		$cmd += " stopclient "
	}
	elseif($StartServer)
	{
		$cmd += " startserver "
	}
	elseif($StopServer)
	{
		$cmd += " stopserver "
	}
	elseif($PortConn)
	{
		$cmd += " portconn "
	}
	else
	{
		return "Please Select One of the subcommand from [ startclient | stopclient | startserver | stopserver | portconn] "
	}
	if($TimeInSeconds)
	{
		$cmd += " -time $TimeInSeconds "
	}
	if($FCIP)
	{
		$cmd += " -fcip "
	}
	if($NSP)
	{
		$cmd += " $NSP "
	}
	else
	{
		return "Specifies the interface from which to check the link, expressed as node:slot:port"
	}
	if($Dest_IP_Addr)
	{
		$cmd += " $Dest_IP_Addr "
	}
	else
	{
		if($StartClient)
		{
			return " Specifies the address of the target system Destination Address(for example, the IP address)"
		}
	}
	if($StartClient)
	{
		if($Time)
		{
			$cmd += " $Time "
		}
		else
		{
			return "Specifies the test duration in seconds Time"
		}
	}
	if($Port)
	{
		$cmd += " $Port "
	}
	
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $cmd
	write-debuglog " The Test-RCopyLink command creates and admits physical disk definitions to enable the use of those disks  " "INFO:" 
	return 	$Result	
} # End Test-RCopyLink

####################################################################################################################
## FUNCTION Remove-RCopyVvFromGroup
####################################################################################################################
Function Remove-RCopyVvFromGroup
{
<#
  .SYNOPSIS
   The Remove-RCopyVvFromGroup command removes a virtual volume from a remote-copy volume group.
   
  .DESCRIPTION
   The Remove-RCopyVvFromGroup command removes a virtual volume from a remote-copy volume group.
   
  .EXAMPLE
	Remove-RCopyVvFromGroup -VV_name vv1 -group_name Group1
	dismisses virtual volume vv1 from Group1:
   
  .EXAMPLE  
	Remove-RCopyVvFromGroup -Pat -VV_name testvv* -group_name Group1
	dismisses all virtual volumes that start with the name testvv from Group1:
   
  .EXAMPLE  
	Remove-RCopyVvFromGroup -KeepSnap -VV_name vv1 -group_name Group1
	dismisses volume vv1 from Group1 and removes the corresponding volumes of vv1 on all the target systems of Group1.
	
  .EXAMPLE 
	Remove-RCopyVvFromGroup -RemoveVV -VV_name vv2 -group_name Group1
	dismisses volume vv2 from Group2 and retains the resync snapshot associated with vv2 for this group.
	
  .PARAMETER Pat
	Specifies that specified patterns are treated as glob-style patterns and that all remote-copy volumes matching the specified pattern will be dismissed from the remote-copy group.
				
  .PARAMETER KeepSnap
	Specifies that the local volume's resync snapshot should be retained.
	
  .PARAMETER RemoveVV
	Remove remote sides' volumes.	
	    	
  .PARAMETER VVname
	The name of the volume to be removed. Volumes are added to a group with the admitrcopyvv command.	
	
  .PARAMETER GroupName      
	The name of the group that currently includes the target.

  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  Remove-RCopyVvFromGroup
    LASTEDIT: January 2020
    KEYWORDS: Remove-RCopyVvFromGroup
   
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
		$KeepSnap,
		
		[Parameter(Position=2, Mandatory=$false)]
		[switch]
		$RemoveVV,
				
		[Parameter(Position=3, Mandatory=$false)]
		[System.String]
		$VVname,
		
		[Parameter(Position=4, Mandatory=$false)]
		[System.String]
		$GroupName,
				
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)		
	
	Write-DebugLog "Start: In Remove-RCopyVvFromGroup  - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting Remove-RCopyVvFromGroup since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Remove-RCopyVvFromGroup since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}
	
	$cmd= "dismissrcopyvv -f "	
	
	if ($Pat)
	{
		$cmd+=" -pat "
	}
	if ($KeepSnap)
	{
		$cmd+=" -keepsnap "
	}
	if ($RemoveVV)
	{
		$cmd+=" -removevv "
	}
	if ($VVname)
	{
		$cmd+=" $VVname "
	}
	else
	{
		Write-DebugLog "Stop: VVname is mandatory" $Debug
		return "Error :  -VVname is mandatory. "
	}
	if ($GroupName)
	{
		$cmd1= "showrcopy"
		$Result1 = Invoke-CLICommand -Connection $SANConnection -cmds  $cmd1
		if ($Result1 -match $GroupName )
		{
			$cmd+=" $GroupName "
		}
		else
		{
			Write-DebugLog "Stop: Exiting  Remove-RCopyVvFromGroup  GroupName in unavailable "
			Return "FAILURE : -GroupName $GroupName  is Unavailable to execute. "
		}	
	}
	else
	{
		Write-DebugLog "Stop: GroupName is mandatory" $Debug
		return "Error :  -GroupName is mandatory. "		
	}
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $cmd
	write-debuglog "  Executing Remove-RCopyVvFromGroup  command removes a virtual volume from a remote-copy volume group.using cmd   " "INFO:" 
	return $Result
	
} # End Remove-RCopyVvFromGroup

####################################################################################################################
## FUNCTION Sync-RecoverDRRcopyGroup
####################################################################################################################
Function Sync-RecoverDRRcopyGroup
{
<#
  .SYNOPSIS
    The Sync-RecoverDRRcopyGroup command performs the following actions:
    Performs data synchronization from primary remote copy volume groups to secondary remote copy volume groups.
    Performs the complete recovery operation (synchronization and storage failover operation which performs role reversal to make secondary volumes as primary which becomes read-write) for the remote copy volume group in both planned migration and disaster scenarios.


  .DESCRIPTION
    The Sync-RecoverDRRcopyGroup command performs the following actions:
    Performs data synchronization from primary remote copy volume groups to secondary remote copy volume groups.
    Performs the complete recovery operation (synchronization and storage failover operation which performs role reversal to make secondary volumes as primary which becomes read-write) for the remote copy volume group in both planned migration and disaster scenarios.
	
  .EXAMPLE
   Sync-RecoverDRRcopyGroup  -Subcommand sync -Target_name test -Group_name Grp1

  .EXAMPLE
   Sync-RecoverDRRcopyGroup  -Subcommand recovery -Target_name test -Group_name Grp1
   
   EXAMPLE
   Sync-RecoverDRRcopyGroup  -Subcommand sync -Force -Group_name Grp1
   
   .EXAMPLE
   Sync-RecoverDRRcopyGroup  -Subcommand sync -Nowaitonsync -Group_name Grp1
   
   .EXAMPLE
   Sync-RecoverDRRcopyGroup  -Subcommand sync -Nosyncbeforerecovery -Group_name Grp1
   
   .EXAMPLE
   Sync-RecoverDRRcopyGroup  -Subcommand sync -Nofailoveronlinkdown -Group_name Grp1
   
   .EXAMPLE
   Sync-RecoverDRRcopyGroup  -Subcommand sync -Forceassecondary -Group_name Grp1
   
   .EXAMPLE
   Sync-RecoverDRRcopyGroup  -Subcommand sync -Waittime 60 -Group_name Grp1
 
  .PARAMETER Subcommand
	sync
	Performs the data synchronization from primary remote copy volume
	group to secondary remote copy volume group.
	
	recovery
	Performs complete recovery operation for the remote copy volume
	group in both planned migration and disaster scenarios.
		
  .PARAMETER Target_name <target_name>
	Specifies the target for the subcommand. This is optional for
	single target groups but is required for multi-target groups.
	
  .PARAMETER Force
	Does not ask for confirmation for this command.

  .PARAMETER Nowaitonsync
	Specifies that this command should not wait for data synchronization
	from primary remote copy volume groups to secondary remote copy
	volume groups.
	This option is valid only for the sync subcommand.

  .PARAMETER Nosyncbeforerecovery
	Specifies that this command should not perform data synchronization
	before the storage failover operation (performing role reversal to
	make secondary volumes as primary which becomes read-write). This
	option can be used if data synchronization is already done outside
	of this command and it is required to do only storage failover
	operation (performing role reversal to make secondary volumes as
	primary which becomes read-write).
	This option is valid only for the recovery subcommand.

  .PARAMETER Nofailoveronlinkdown
	Specifies that this command should not perform storage failover
	operation (performing role reversal to make secondary volumes as
	primary which becomes read-write) when the remote copy link is down.
	This option is valid only for the recovery subcommand.

  .PARAMETER Forceasprimary
	Specifies that this command does the storage failover operation
	(performing role reversal to make secondary volumes as primary
	which becomes read-write) and forces secondary role as primary
	irrespective of whether the data is current or not.
	This option is valid only for the recovery subcommand.
	The successful execution of this command must be immediately
	followed by the execution of the recovery subcommand with
	forceassecondary option on the other array. The incorrect use
	of this option can lead to the primary secondary volumes not
	being consistent. see the notes section for additional details.

  .PARAMETER Forceassecondary
	This option must be used after successful execution of recovery subcommand with forceasprimary option on the other array.
	Specifies that this changes the primary volume groups to secondary
	volume groups. The incorrect use of this option can lead to the
	primary secondary volumes not being consistent.
	This option is valid only for the recovery subcommand.

  .PARAMETER Nostart
	Specifies that this command does not start the group after storage failover operation is complete.
	This option is valid only for the recovery subcommand.

  .PARAMETER Waittime <timeout_value>
	Specifies the timeout value for this command.
	Specify the time in the format <time>{s|S|m|M}. Value is a positive
	integer with a range of 1 to 720 minutes (12 Hours).
	Default time is 720 minutes. 
		
  .PARAMETER Group_name
	Name of the Group
	 
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  Sync-RecoverDRRcopyGroup
    LASTEDIT: March 2020
    KEYWORDS: Sync-RecoverDRRcopyGroup
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
	
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$Subcommand,
	
		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$Target_name,
		
		[Parameter(Position=2, Mandatory=$false)]
		[Switch]
		$Nowaitonsync,
		
		[Parameter(Position=3, Mandatory=$false)]
		[Switch]
		$Nosyncbeforerecovery,
		
		[Parameter(Position=4, Mandatory=$false)]
		[Switch]
		$Nofailoveronlinkdown,

		[Parameter(Position=5, Mandatory=$false)]
		[Switch]
		$Forceasprimary,
		
		[Parameter(Position=6, Mandatory=$false)]
		[Switch]
		$Nostart,
		
		[Parameter(Position=7, Mandatory=$false)]
		[System.String]
		$Waittime,
		
		[Parameter(Position=8, Mandatory=$false)]
		[System.String]
		$Group_name,		
				
		[Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection       
	)	
	
	Write-DebugLog "Start: In Sync-RecoverDRRcopyGroup   - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting Sync-RecoverDRRcopyGroup since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Sync-RecoverDRRcopyGroup since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}		
	$cmd= "controldrrcopygroup "
	
	if ($Subcommand)
	{	
		$a = "sync","recovery"
		$l=$Subcommand
		if($a -eq $l)
		{
			$cmd+=" $Subcommand -f"							
		}
		else
		{ 
			Write-DebugLog "Stop: Exiting  Sync-RecoverDRRcopyGroup   since -Subcommand $Subcommand in incorrect "
			Return "FAILURE : -Subcommand :- $Subcommand is an Incorrect Subcommand  [ sync | recovery ]  can be used only . "
		}		
	}	
	else
	{
		return " FAILURE :  Subcommand is mandatory please select any one from sync/recovery "
	}
	if ($Target_name)
	{		
		$cmd+=" -target $Target_name "	
	}	
	if ($Nowaitonsync)
	{		
		$cmd+=" -nowaitonsync "	
	}
	if ($Nosyncbeforerecovery)
	{		
		$cmd+=" -nosyncbeforerecovery "	
	}
	if ($Nofailoveronlinkdown)
	{		
		$cmd+=" -nofailoveronlinkdown "	
	}
	if ($Forceasprimary)
	{		
		$cmd+=" -forceasprimary "	
	}
	if ($Nostart)
	{		
		$cmd+=" -nostart "	
	}
	if ($Waittime)
	{		
		$cmd+=" -waittime $Waittime "	
	}	
	if ($Group_name)
	{		
		$cmd+=" $Group_name "	
	}	
	else
	{
		return " FAILURE :  Group_name is mandatory to execute Sync-RecoverDRRcopyGroup command "
	}	
		
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $cmd
	write-debuglog " The Sync-RecoverDRRcopyGroup command creates and admits physical disk definitions to enable the use of those disks  " "INFO:" 
	return 	$Result	
} # End Sync-RecoverDRRcopyGroup

####################################################################################################################
## FUNCTION Set-AdmitRCopyHost
####################################################################################################################
Function Set-AdmitRCopyHost {
    <#
  .SYNOPSIS
    Add hosts to a remote copy group.
                                                                                                           .
  .DESCRIPTION
    The Set-AdmitRCopyHost command adds hosts to a remote copy group.

  .PARAMETER Proximity
    Valid values are:
        primary:   Hosts with Active/Optimized I/O paths to the local primary storage device
        secondary: Hosts with Active/Optimized I/O paths to the local secondary storage device
        all:       Hosts with Active/Optimized I/O paths to both storage devices

  .PARAMETER GroupName
        The group name, as specified with New-RCopyGroup cmdlet.

  .PARAMETER HostName
        The host name, as specified with New-Host cmldet.
   
  .EXAMPLES
    The following example adds host1 to group1 with Proximity primary:
    Set-AdmitRCopyHost -proximity primary group1 host1

    The following example shows the Active/Active groups with different proximities set:
    Get-HostSet -summary

         Id Name             HOST_Cnt VVOLSC Flashcache QoS RC_host
        552 RH2_Group0_1            1 NO     NO         NO  All
        555 RH0_Group0_0            1 NO     NO         NO  Pri
        556 RH1_Group0_2            1 NO     NO         NO  Sec

  .SUPPORTED ARRAY VERSIONS
     HPE Primera OS 4.3 onwards, HPE Alletra OS 9.3 onwards

  .NOTES
    This command is only supported for groups for which the active_active policy is set.
    The policy value can be seen in Get-HostSet -summary under the RC_host column.

    NAME:  Set-AdmitRCopyHost
    LASTEDIT: 25/04/2021
    KEYWORDS: Set-AdmitRCopyHost
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $false, ValueFromPipeline = $true)]
        [ValidateSet("primary", "secondary", "all")]
        [System.String]
        $Proximity,		

        [Parameter(Position = 1, Mandatory = $false, ValueFromPipeline = $true)]
        [System.String]
        $GroupName,

        [Parameter(Position = 2, Mandatory = $false, ValueFromPipeline = $true)]
        [System.String]
        $HostName,		
		
        [Parameter(Position = 3, Mandatory = $false, ValueFromPipeline = $true)]
        $SANConnection = $global:SANConnection 
       
    )	
	
    Write-DebugLog "Start: In Set-AdmitRCopyHost   - validating input values" $Debug 
    #check if connection object contents are null/empty
    if (!$SANConnection) {		
        #check if connection object contents are null/empty
        $Validate1 = Test-CLIConnection $SANConnection
        if ($Validate1 -eq "Failed") {
            #check if global connection object contents are null/empty
            $Validate2 = Test-CLIConnection $global:SANConnection
            if ($Validate2 -eq "Failed") {
                Write-DebugLog "Connection object is null/empty or the array address (FQDN/IP Address) or user credentials in the connection object are either null or incorrect.  Create a valid connection object using New-CLIConnection or New-PoshSshConnection" "ERR:"
                Write-DebugLog "Stop: Exiting Set-AdmitRCopyHost since SAN connection object values are null/empty" $Debug
                return "Unable to execute the cmdlet Set-AdmitRCopyHost since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
            }
        }
    }
    $plinkresult = Test-PARCli
    if ($plinkresult -match "FAILURE :") {
        write-debuglog "$plinkresult" "ERR:" 
        return $plinkresult
    }		
    $cmd = "admitrcopyhost  "
	
    if ($Proximity) {	
        $cmd += " -proximity $Proximity "		
    }	
    if ($GroupName) {	
        $cmd += " $GroupName "		
    }
    if ($HostName) {	
        $cmd += " $HostName "		
    }
	
    $Result = Invoke-CLICommand -Connection $SANConnection -cmds  $cmd

    write-debuglog " The Set-AdmitRCopyHost command Add hosts to a remote copy group" "INFO:" 
    return 	$Result	

} # End Set-AdmitRCopyHost

####################################################################################################################
## FUNCTION Remove-RCopyHost
####################################################################################################################
Function Remove-RCopyHost {
    <#
  .SYNOPSIS
    Dismiss/Remove hosts from a remote copy group.
                                                                                                           .
  .DESCRIPTION
    The Remove-RCopyHost command removes hosts from a remote copy group
 
  .PARAMETER F
    Specifies that the command is forced. If this option is not used, the
    command requires confirmation before proceeding with its operation.

  .PARAMETER GroupName
    The group name, as specified with New-RCopyGroup cmdlet.

  .PARAMETER HostName
    The host name, as specified with New-Host cmldet.
   
  .EXAMPLES
    The following example removes host1 from group1:
    Remove-RCopyHost group1 host1

  .SUPPORTED ARRAY VERSIONS
     HPE Primera OS 4.3 onwards, HPE Alletra OS 9.3 onwards

  .NOTES
    This command is only supported for groups for which the active_active policy is set.

    NAME:  Remove-RCopyHost
    LASTEDIT: 25/04/2021
    KEYWORDS: Remove-RCopyHost
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $false, ValueFromPipeline = $true)]
        [System.String]
        $F,

        [Parameter(Position = 1, Mandatory = $false, ValueFromPipeline = $true)]
        [System.String]
        $GroupName,

        [Parameter(Position = 2, Mandatory = $false, ValueFromPipeline = $true)]
        [System.String]
        $HostName,		
		
        [Parameter(Position = 3, Mandatory = $false, ValueFromPipeline = $true)]
        $SANConnection = $global:SANConnection        
    )	
	
    Write-DebugLog "Start: In Remove-RCopyHost   - validating input values" $Debug 
    #check if connection object contents are null/empty
    if (!$SANConnection) {
        #check if connection object contents are null/empty
        $Validate1 = Test-CLIConnection $SANConnection
        if ($Validate1 -eq "Failed") {
            #check if global connection object contents are null/empty
            $Validate2 = Test-CLIConnection $global:SANConnection
            if ($Validate2 -eq "Failed") {
                Write-DebugLog "Connection object is null/empty or the array address (FQDN/IP Address) or user credentials in the connection object are either null or incorrect.  Create a valid connection object using New-CLIConnection or New-PoshSshConnection" "ERR:"
                Write-DebugLog "Stop: Exiting Remove-RCopyHost since SAN connection object values are null/empty" $Debug
                return "Unable to execute the cmdlet Remove-RCopyHost since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
            }
        }
    }
    $plinkresult = Test-PARCli
    if ($plinkresult -match "FAILURE :") {
        write-debuglog "$plinkresult" "ERR:" 
        return $plinkresult
    }		
    $cmd = "dismissrcopyhost  "
	
    if ($F) {	
        $cmd += " -f "		
    }
    if ($GroupName) {	
        $cmd += " $GroupName "		
    }
    if ($HostName) {	
        $cmd += " $HostName "		
    }
	
    $Result = Invoke-CLICommand -Connection $SANConnection -cmds  $cmd

    write-debuglog " The Remove-RCopyHost command removes hosts from a remote copy group" "INFO:" 
    return 	$Result	

} # End Remove-RCopyHost

Export-ModuleMember Add-RCopyTarget , Add-RCopyVv , Add-RCopyLink , Disable-RCopylink , Disable-RCopyTarget , Disable-RCopyVv , Get-RCopy ,
Get-StatRCopy , Remove-RCopyGroup , Remove-RCopyTarget , Remove-RCopyTargetFromGroup , Set-RCopyGroupPeriod , Set-RCopyGroupPol , Set-RCopyTarget ,
Set-RCopyTargetName , Set-RCopyTargetPol , Set-RCopyTargetWitness , Show-RCopyTransport , Start-RCopy , Start-RCopyGroup , Stop-RCopy , 
Stop-RCopyGroup , Sync-RCopy , Test-RCopyLink , Remove-RCopyVvFromGroup , Sync-RecoverDRRcopyGroup , Set-AdmitRCopyHost , Remove-RCopyHost