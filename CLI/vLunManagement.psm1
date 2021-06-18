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
##	File Name:		vLunManagement.psm1
##	Description: 	vLUN Management cmdlets 
##		
##	Created:		January 2020
##	Last Modified:	May 2021
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

############################################################################################################################################
## FUNCTION Get-vLun
############################################################################################################################################
Function Get-vLun
{
<#
  .SYNOPSIS
    Get list of LUNs that are exported/ presented to hosts
  
  .DESCRIPTION
    Get list of LUNs that are exported/ presented to hosts
        
  .EXAMPLE
    Get-vLun 
	List all exported volumes

  .EXAMPLE	
	Get-vLun -vvName PassThru-Disk 
	List LUN number and hosts/host sets of LUN PassThru-Disk
	
  .PARAMETER vvName 
    Specify name of the volume to be exported. 
	If prefixed with 'set:', the name is a volume set name.
	

  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  Get-vLun  
    LASTEDIT: January 2020
    KEYWORDS: Get-vLun
   
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
		$PresentTo, 	
		
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)		
	
	Write-DebugLog "Start: In Get-vLun - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting Get-vLun since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Get-vLun since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli -SANConnection $SANConnection
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}	
	
	$ListofvLUNs = @()
	
	$GetvLUNCmd = "showvlun -t -showcols VVName,Lun,HostName,VV_WWN "
	if ($vvName)
	{
		$GetvLUNCmd += " -v $vvName"
	}
	
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $GetvLUNCmd
	write-debuglog "Get list of vLUN" "INFO:" 
	if($Result -match "Invalid vv name:")
	{
		return "FAILURE : No vv $vvName found"
	}
	
	$Result = $Result | where { ($_ -notlike '*total*') -and ($_ -notlike '*------*')} ## Eliminate summary lines
	if ($Result.Count -gt 1)
	{
		foreach ($s in  $Result[1..$Result.Count] )
		{
			
			$s= $s.Trim()
			$s= [regex]::Replace($s," +",",")			# Replace one or more spaces with comma to build CSV line
			$sTemp = $s.Split(',')
			
			$vLUN = New-Object -TypeName _vLUN
			$vLUN.Name = $sTemp[0]
			$vLUN.LunID = $sTemp[1]
			$vLUN.PresentTo = $sTemp[2]
			$vLUN.vvWWN = $sTemp[3]
			
			$ListofvLUNs += $vLUN			
		}
	}
	else
	{
		write-debuglog "LUN $vvName does not exist. Simply return" "INFO:"
		return "FAILURE : No vLUN $vvName found Error : $Result"
	}
	

	if ($PresentTo)
		{ $ListofVLUNs | where  {$_.PresentTo -like $PresentTo} }
	else
		{ $ListofVLUNs  }
	
} # End Get-vLun

##############################################################################
########################### FUNCTION Show-vLun ###############################
##############################################################################
Function Show-vLun
{
<#
  .SYNOPSIS
    Get list of LUNs that are exported/ presented to hosts
  
  .DESCRIPTION
    Get list of LUNs that are exported/ presented to hosts
        
  .EXAMPLE
    Show-vLun 
	List all exported volumes

  .EXAMPLE	
	Show-vLun -vvName XYZ 
	List LUN number and hosts/host sets of LUN XYZ
	
  .EXAMPLE	
	Show-vLun -Listcols
	
  .EXAMPLE	
	Show-vLun -Nodelist 1
	
  .EXAMPLE	
	Show-vLun -DomainName Aslam_D	
	
  .PARAMETER vvName 
    Specify name of the volume to be exported. 
	If prefixed with 'set:', the name is a volume set name.
	
  .PARAMETER Listcols
	List the columns available to be shown in the -showcols option
	described below (see 'clihelp -col showvlun' for help on each column).

  .PARAMETER Showcols <column>[,<column>...]
	Explicitly select the columns to be shown using a comma-separated list
	of column names.  For this option the full column names are shown in
	the header.
	Run 'showvlun -listcols' to list the available columns.
	Run 'clihelp -col showvlun' for a description of each column.

  .PARAMETER ShowWWN
	Shows the WWN of the virtual volume associated with the VLUN.

  .PARAMETER ShowsPathSummary
	Shows path summary information for active VLUNs

  .PARAMETER Hostsum
	Shows mount point, Bytes per cluster, capacity information from Host Explorer
	and user reserved space, VV size from showvv.

  .PARAMETER ShowsActiveVLUNs
	Shows only active VLUNs.

  .PARAMETER ShowsVLUNTemplates
	Shows only VLUN templates.

  .PARAMETER Hostname {<hostname>|<pattern>|<hostset>}...
	Displays only VLUNs exported to hosts that match <hostname> or
	glob-style patterns, or to the host sets that match <hostset> or
	glob-style patterns(see help on sub,globpat). The host set name must
	start with "set:". Multiple host names, host sets or patterns can
	be repeated using a comma-separated list.

  .PARAMETER VV_name {<VV_name>|<pattern>|<VV_set>}...
	Displays only VLUNs of virtual volumes that match <VV_name> or
	glob-style patterns, or to the vv sets that match <VV-set> or glob-style
	patterns (see help on sub,globpat). The VV set name must start
	with "set:". Multiple volume names, vv sets or patterns can be
	repeated using a comma-separated list (for example -v <VV_name>,
	<VV_name>...).

  .PARAMETER LUN
	Specifies that only exports to the specified LUN are displayed. This
	specifier can be repeated to display information for multiple LUNs.

  .PARAMETER Nodelist
	Requests that only VLUNs for specific nodes are displayed. The node list
	is specified as a series of integers separated by commas (for example
	0,1,2). The list can also consist of a single integer (for example 1).
	
  .PARAMETER Slotlist
	Requests that only VLUNs for specific slots are displayed. The slot list
	is specified as a series of integers separated by commas (for example
	0,1,2). The list can also consist of a single integer (for example 1).

  .PARAMETER Portlist
	Requests that only VLUNs for specific ports are displayed. The port list
	is specified as a series of integers separated by commas ((for example
	1,2). The list can also consist of a single integer (for example 1).

  .PARAMETER Domain_name  
	Shows only the VLUNs whose virtual volumes are in domains with names
	that match one or more of the <domainname_or_pattern> options. This
	option does not allow listing objects within a domain of which the user
	is not a member. Multiple domain names or patterns can be repeated using
	a comma-separated list.

  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  Show-vLun  
    LASTEDIT: January 2020
    KEYWORDS: Show-vLun
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[switch]
		$Listcols,
		
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$Showcols, 
		
		[Parameter(Position=2, Mandatory=$false)]
		[switch]
		$ShowsWWN,
		
		[Parameter(Position=3, Mandatory=$false)]
		[switch]
		$ShowsPathSummary,
		
		[Parameter(Position=4, Mandatory=$false)]
		[switch]
		$Hostsum,
		
		[Parameter(Position=5, Mandatory=$false)]
		[switch]
		$ShowsActiveVLUNs,
		
		[Parameter(Position=6, Mandatory=$false)]
		[switch]
		$ShowsVLUNTemplates,
		
		[Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$Hostname,
		
		[Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$VV_name,
		
		[Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$LUN,
		
		[Parameter(Position=10, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$Nodelist,
		
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$Slotlist,
		
		[Parameter(Position=11, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$Portlist,
		
		[Parameter(Position=12, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$DomainName,
		
		[Parameter(Position=13, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)		
	
	Write-DebugLog "Start: In Show-vLun - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting Show-vLun since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Show-vLun since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli -SANConnection $SANConnection
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}	
	
	$cmd = "showvlun "
	
	if($Listcols)
	{
		$cmd += " -listcols " 
	}
	if($Showcols)
	{
		$cmd += " -showcols $Showcols" 
	}
	if($ShowsWWN)
	{
		$cmd += " -lvw " 
	}
	if($ShowsPathSummary)
	{
		$cmd += " -pathsum " 
	}
	if($Hostsum)
	{
		$cmd += " -hostsum " 
	}
	if($ShowsActiveVLUNs)
	{
		$cmd += " -a " 
	}
	if($ShowsVLUNTemplates)
	{
		$cmd += " -t " 
	}
	if($Hostname)
	{
		$cmd += " -host $Hostname" 
	}
	if($VV_name)
	{
		$cmd += " -v $VV_name" 
	}
	if($LUN)
	{
		$cmd += " -l $LUN" 
	}
	if($Nodelist)
	{
		$cmd += " -nodes $Nodelist" 
	}
	if($Slotlist)
	{
		$cmd += " -slots $Slotlist" 
	}
	if($Portlist)
	{
		$cmd += " -ports $Portlist" 
	}
	if($DomainName)
	{
		$cmd += " -domain $DomainName" 
	}
	
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $cmd
	write-debuglog "Get list of vLUN" "INFO:" 
	
	write-host ""
	return $Result
	
} # End Show-vLun

################################################################################
########################### FUNCTION New-vLun ##################################
################################################################################

Function New-vLun
{
<#
  .SYNOPSIS
    The New-vLun command creates a VLUN template that enables export of a
    Virtual Volume as a SCSI VLUN to a host or hosts. A SCSI VLUN is created when the
    current system state matches the rule established by the VLUN template
  
  .DESCRIPTION
	The New-vLun command creates a VLUN template that enables export of a
    Virtual Volume as a SCSI VLUN to a host or hosts. A SCSI VLUN is created when the
    current system state matches the rule established by the VLUN template.

    There are four types of VLUN templates:
        Port presents - created when only the node:slot:port are specified. The
        VLUN is visible to any initiator on the specified port.

        Host set - created when a host set is specified. The VLUN is visible to
        the initiators of any host that is a member of the set.

        Host sees - created when the hostname is specified. The VLUN is visible
        to the initiators with any of the host's WWNs.

        Matched set - created when both hostname and node:slot:port are
        specified. The VLUN is visible to initiators with the host's WWNs only
        on the specified port.

    Conflicts between overlapping VLUN templates are resolved using
    prioritization, with port presents templates having the lowest priority and
    matched set templates having the highest.
        
  .EXAMPLE
    New-vLun -vvName xyz -LUN 1 -HostName xyz

  .EXAMPLE
    New-vLun -vvSet set:xyz -NoVcn -LUN 2 -HostSet set:xyz
	
  .PARAMETER vvName 
	Specifies the virtual volume or virtual volume set name, using up to 31 characters in length.
	The volume name is provided in the syntax of basename.int.  The VV set
	name must start with "set:".
	
  .PARAMETER vvSet 
	Specifies the virtual volume or virtual volume set name, using up to 31 characters in length.
	The volume name is provided in the syntax of basename.int.  The VV set
	name must start with "set:".
	
  .PARAMETER LUN
	Specifies the LUN as an integer from 0 through 16383. Alternatively
	n+ can be used to indicate a LUN should be auto assigned, but be
	a minimum of n, or m-n to indicate that a LUN should be chosen in the
	range m to n. In addition the keyword auto may be used and is treated
	as 0+.

  .PARAMETER HostName
	Specifies the host where the LUN is exported, using up to 31 characters.

  .PARAMETER HostSet
	Specifies the host set where the LUN is exported, using up to 31
	characters in length. The set name must start with "set:".

  .PARAMETER NSP
	Specifies the system port of the virtual LUN export.
	node
		Specifies the system node, where the node is a number from 0
		through 7.
	slot
		Specifies the PCI bus slot in the node, where the slot is a
		number from 0 through 5.
	port
		Specifies the port number on the FC card, where the port number
		is 1 through 4.

  .PARAMETER Cnt
	Specifies that a sequence of VLUNs, as specified by the num argument,
	are exported to the same system port and host that is created. The num
	argument can be specified as any integer. For each VLUN created, the
	.int suffix of the VV_name specifier and LUN are incremented by one.

  .PARAMETER NoVcn
	Specifies that a VLUN Change Notification (VCN) not be issued after
	export. For direct connect or loop configurations, a VCN consists of a
	Fibre Channel Loop Initialization Primitive (LIP). For fabric
	configurations, a VCN consists of a Registered State Change
	Notification (RSCN) that is sent to the fabric controller.

  .PARAMETER Ovrd
	Specifies that existing lower priority VLUNs will be overridden, if
	necessary. Can only be used when exporting to a specific host.

	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  	  New-vLun  
    LASTEDIT: January 2020
    KEYWORDS: New-vLun
   
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
		[System.String]
		$vvSet,
		
		[Parameter(Position=2, Mandatory=$false)]
		[System.String]
		$LUN,
		
		[Parameter(Position=3, Mandatory=$false)]
		[System.String]
		$NSP,
		
		[Parameter(Position=4, Mandatory=$false)]
		[System.String]
		$HostSet,
		
		[Parameter(Position=5, Mandatory=$false)]
		[System.String]
		$HostName,
		
		[Parameter(Position=6, Mandatory=$false)]
		[System.String]
		$Cnt,
		
		[Parameter(Position=7, Mandatory=$false)]
		[switch]
		$NoVcn,
		
		[Parameter(Position=8, Mandatory=$false)]
		[switch]
		$Ovrd,
		
		[Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)		
	
	Write-DebugLog "Start: In New-vLun - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting New-vLun since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet New-vLun since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli -SANConnection $SANConnection
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}
	
	$cmdVlun = " createvlun -f"
	
	if($Cnt)
	{
		$cmdVlun += " -cnt $Cnt "
	}
	if($NoVcn)
	{
		$cmdVlun += " -novcn "
	}
	if($Ovrd)
	{
		$cmdVlun += " -ovrd "
	}	
	
	###Added v2.1 : checking the parameter values if vvName or present to empty simply return
	if ($vvName -Or $vvSet)
	{
		if($vvName)
		{
			$cmdVlun += " $vvName "
		}
		else
		{
			if ($vvSet -match "^set:")	
			{
				$cmdVlun += " $vvSet "
			}
			else
			{
				return "Please make sure The VV set name must start with set: Ex:- set:xyz"
			}
		}
		
	}
	else
	{
		Write-DebugLog "No values specified for the parameters vvname. so simply exiting " "INFO:"
		Get-help New-vLun
		return
	}
	
	if($LUN)
	{
		$cmdVlun += " $LUN "
	}
	else
	{
		return " Specifies the LUN as an integer from 0 through 16383."
	}
	
	if($NSP)
	{
		$cmdVlun += " $NSP "
	}
	elseif($HostSet)
	{
		if ($HostSet -match "^set:")	
		{
			$cmdVlun += " $HostSet "
		}
		else
		{
			return "Please make sure The set name must start with set: Ex:- set:xyz"
		}
	}
	elseif($HostName)
	{
		$cmdVlun += " $HostName "
	}
	else
	{
		return "Please select atlist any one from NSP | HostSet | HostName"
	}
	
	$Result1 = Invoke-CLICommand -Connection $SANConnection -cmds  $cmdVlun
	write-debuglog "Presenting $vvName to server $item with the command --> $cmdVlun" "INFO:" 
	if($Result1 -match "no active paths")
	{
		$successmsg += $Result1
	}
	elseif([string]::IsNullOrEmpty($Result1))
	{
		$successmsg += "Success : $vvName exported to host $objName`n"
	}
	else
	{
		$successmsg += "FAILURE : While exporting vv $vvName to host $objName Error : $Result1`n"
	}		
	
	return $successmsg
	
} # End New-vLun

############################################################################
########################### FUNCTION Remove-vLun ###########################
############################################################################

Function Remove-vLun
{
<#
  .SYNOPSIS
    Unpresent virtual volumes 
  
  .DESCRIPTION
    Unpresent  virtual volumes 
        
  .EXAMPLE
	Remove-vLun -vvName PassThru-Disk -force
	Unpresent the virtual volume PassThru-Disk to all hosts
	
  .EXAMPLE	
	Remove-vLun -vvName PassThru-Disk -whatif 
	Dry-run of deleted operation on vVolume named PassThru-Disk
	
  .EXAMPLE		
	Remove-vLun -vvName PassThru-Disk -PresentTo INF01  -force
	Unpresent the virtual volume PassThru-Disk only to host INF01.
	all other presentations of PassThru-Disk remain intact.
	
  .EXAMPLE	
	Remove-vLun -PresentTo INF01 -force
	Remove all LUNS presented to host INF01
	
  .EXAMPLE	
	Remove-vLun -vvName CSV* -PresentTo INF01 -force
	Remove all LUNS started with CSV* and presented to host INF01
	
  .EXAMPLE
	Remove-vLun -vvName vol2 -force -Novcn
   
  .EXAMPLE
	Remove-vLun -vvName vol2 -force -Pat
   
  .EXAMPLE
	Remove-vLun -vvName vol2 -force -Remove_All   
	It removes all vluns associated with a VVOL Container.
	
  .PARAMETER whatif
    If present, perform a dry run of the operation and no VLUN is removed	

  .PARAMETER force
	If present, perform forcible delete operation
	
  .PARAMETER vvName 
    Specify name of the volume to be exported. 
	
  .PARAMETER PresentTo 
    Specify name of the hosts where vLUns are presented to.
	
  .PARAMETER Novcn
	Specifies that a VLUN Change Notification (VCN) not be issued after removal of the VLUN.
		
  .PARAMETER Pat
	Specifies that the <VV_name>, <LUN>, <node:slot:port>, and <host_name> specifiers are treated as glob-style patterns and that all VLUNs matching the specified pattern are removed.
	
  .PARAMETER Remove_All
	It removes all vluns associated with a VVOL Container.
		
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  Remove-vLun  
    LASTEDIT: January 2020
    KEYWORDS: Remove-vLun
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$force, 
		
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$whatif, 		
		
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$vvName,
		
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$PresentTo, 		
		
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$Novcn,
		
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$Pat,
		
		[Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$Remove_All,
		
		[Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)		
	
	Write-DebugLog "Start: In Remove-vLun - validating input values" $Debug 
	 
	if (!(($vvName) -or ($PresentTo)))
	{
		Write-DebugLog "Action required: no vv or no host mentioned - simply exiting " $Debug
		Get-help Remove-vLun
		return
	}
	if(!(($force) -or ($whatif)))
	{
		write-debuglog "no -force or -whatif option selected to remove/dry run of VLUN, Exiting...." "INFO:"
		Get-help Remove-vLun
		return "FAILURE : no -force or -whatif option selected to remove/dry run of VLUN"
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
				Write-DebugLog "Stop: Exiting Remove-vLun since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Remove-vLun since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli -SANConnection $SANConnection
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}
	if($PresentTo)
	{
		$ListofvLuns = Get-vLun -vvName $vvName -PresentTo $PresentTo -SANConnection $SANConnection
	}
	else
	{
		$ListofvLuns = Get-vLun -vvName $vvName -SANConnection $SANConnection
	}
	if($ListofvLuns -match "FAILURE")
	{
		return "FAILURE : No vLUN $vvName found"
	}
	$ActionCmd = "removevlun "
	if ($whatif)
	{
		$ActionCmd += "-dr "
	}
	else
	{
		if($force)
		{
			$ActionCmd += "-f "
		}		
	}	
	if ($Novcn)
	{
		$ActionCmd += "-novcn "
	}
	if ($Pat)
	{
		$ActionCmd += "-pat "
	}
	if($Remove_All)
	{
		$ActionCmd += " -set "
	}
	if ($ListofvLuns)
	{
		foreach ($vLUN in $ListofvLuns)
		{
			$vName = $vLUN.Name
			if ($vName)
			{
				$RemoveCmds = $ActionCmd + " $vName $($vLun.LunID) $($vLun.PresentTo)"
				$Result1 = Invoke-CLICommand -Connection $SANConnection -cmds  $RemoveCmds
				write-debuglog "Removing Virtual LUN's with command $RemoveCmds" "INFO:" 
				if ($Result1 -match "Issuing removevlun")
				{
					$successmsg += "Success: Unexported vLUN $vName from $($vLun.PresentTo)"
				}
				elseif($Result1 -match "Dry run:")
				{
					$successmsg += $Result1
				}
				else
				{
					$successmsg += "FAILURE : While unexporting vLUN $vName from $($vLun.PresentTo) "
				}				
			}
		}
		return $successmsg
	}
	
	else
	{
		Write-DebugLog "no vLUN found for $vvName presented to host $PresentTo." $Info
		return "FAILURE : no vLUN found for $vvName presented to host $PresentTo"
	}
	

} # END Remove-vLun

Export-ModuleMember Get-vLun , Show-vLun , New-vLun , Remove-vLun