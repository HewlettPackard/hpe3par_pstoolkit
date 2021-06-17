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
##	File Name:		Vasa.psm1
##	Description: 	VASA cmdlets 
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

####################################################################################################################
## FUNCTION Show-vVolvm
####################################################################################################################
Function Show-vVolvm
{
<#
  .SYNOPSIS
    The Show-vVolvm command displays information about all virtual machines
    (VVol-based) or a specific virtual machine in a system.  This command
    can be used to determine the association between virtual machines and
    their associated virtual volumes. showvvolvm will also show the
    accumulation of space usage information for a virtual machine.

  .DESCRIPTION
    The Show-vVolvm command displays information about all virtual machines
    (VVol-based) or a specific virtual machine in a system.  This command
    can be used to determine the association between virtual machines and
    their associated virtual volumes. showvvolvm will also show the
    accumulation of space usage information for a virtual machine.

  .EXAMPLE
	Show-vVolvm -container_name XYZ -option listcols 
	
  .EXAMPLE
	Show-vVolvm -container_name XYZ -Detailed 
	
  .EXAMPLE
	Show-vVolvm -container_name XYZ -StorageProfiles
	
  .EXAMPLE
	Show-vVolvm -container_name XYZ -Summary 
	
  .EXAMPLE
	Show-vVolvm -container_name XYZ -Binding
	
  .EXAMPLE
	Show-vVolvm -container_name XYZ -VVAssociatedWithVM	
	
  .PARAMETER container_name
    The name of the virtual volume storage container. May be "sys:all" to display all VMs.
 
  .PARAMETER Listcols
	List the columns available to be shown in the -showcols option
	below (see "clihelp -col showvvolvm" for help on each column).

	By default with mandatory option -sc, (if none of the information selection options
	below are specified) the following columns are shown:
	VM_Name GuestOS VM_State Num_vv Physical Logical
    
  .PARAMETER Detailed
	Displays detailed information about the VMs. The following columns are shown:
	VM_Name UUID Num_vv Num_snap Physical Logical GuestOS VM_State UsrCPG SnpCPG Container CreationTime

  .PARAMETER StorageProfiles
	Shows the storage profiles with constraints associated with the VM.
	Often, all VVols associated with a VM will use the same storage profile.
	However, if vSphere has provisioned different VMDK volumes with different
	storage profiles, only the storage profile for the first virtual disk
	(VMDK) VVol will be displayed. In this case, use the -vv option to display
	storage profiles for individual volumes associated with the VM. Without
	the -vv option, the following columns are shown:
	VM_Name SP_Name SP_Constraint_List

  .PARAMETER Summary
	Shows the summary of virtual machines (VM) in the system, including
	the total number of the following: VMs, VVs, and total physical and
	exported space used. The following columns are shown:
	Num_vm Num_vv Physical Logical

  .PARAMETER Binding
	Shows the detailed binding information for the VMs. The binding could
	be PoweredOn, Bound (exported), or Unbound. When it is bound,
	showvvolvm displays host names to which it is bound. When it is bound
	and -vv option is used, showvvolvm displays the exported LUN templates
	for each volume, and the state for actively bound VVols. PoweredOn
	means the VM is powered on. Bound means the VM is not powered on,
	but either being created, modified, queried or changing powered state
	from on to off or off to on. Unbound means the VM is powered off.
	The following columns are shown:
	VM_Name VM_State Last_Host Last_State_Time Last_Pwr_Time

	With the -vv option, the following columns are shown:
	VM_Name VVol_Name VVol_Type VVol_State VVol_LunId Bind_Host Last_State_Time

  .PARAMETER VVAssociatedWithVM
	Shows all the VVs (Virtual Volumes) associated with the VM.
	The following columns are shown:
	VM_Name VV_ID VVol_Name VVol_Type Prov Physical Logical

	The columns displayed can change when used with other options.
	See the -binding option above.

  .PARAMETER RemoteCopy
	Shows the remote copy group name, sync status, role, and last sync time of the
	volumes associated with a VM. Note that if a VM does not report as synced, the
	last sync time for the VM DOES NOT represent a consistency point. True
	consistency points are only represented by the showrcopy LastSyncTime. This
	option may be combined with the -vv, -binding, -d, and -sp options.

  .PARAMETER AutoDismissed
	Shows only VMs containing automatically dismissed volumes. Shows only
	automatically dismissed volumes when combined with the -vv option.
		
  .PARAMETER VM_name 
	Specifies the VMs with the specified name (up to 80 characters in length).
	This specifier can be repeated to display information about multiple VMs.
	This specifier is not required. If not specified, showvvolvm displays
	information for all VMs in the specified storage container.
	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  Show-vVolvm
    LASTEDIT: January 2020
    KEYWORDS: Show-vVolvm
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
	
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$container_name,

		[Parameter(Position=1, Mandatory=$false)]
		[switch]
		$ListCols,

		[Parameter(Position=2, Mandatory=$false)]
		[System.String]
		$ShowCols,
		
		[Parameter(Position=3, Mandatory=$false)]
		[switch]
		$Detailed,
		
		[Parameter(Position=4, Mandatory=$false)]
		[switch]
		$StorageProfiles,
		
		[Parameter(Position=5, Mandatory=$false)]
		[switch]
		$Summary,
		
		[Parameter(Position=6, Mandatory=$false)]
		[switch]
		$Binding,
		
		[Parameter(Position=7, Mandatory=$false)]
		[switch]
		$VVAssociatedWithVM,
		
		[Parameter(Position=8, Mandatory=$false)]
		[switch]
		$RemoteCopy,
		
		[Parameter(Position=9, Mandatory=$false)]
		[switch]
		$AutoDismissed,
		
		[Parameter(Position=10, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$VM_name,
				
		[Parameter(Position=11, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection       
	)	
	
	Write-DebugLog "Start: In Show-vVolvm   - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting Show-vVolvm since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Show-vVolvm since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}

	$cmd = "showvvolvm "
	
	if($ListCols)
	{
		$cmd +=" -listcols "
		$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $cmd
		write-debuglog " The Show-vVolvm command creates and admits physical disk definitions to enable the use of those disks  " "INFO:" 
		return 	$Result	
	}
	if ($ShowCols)
	{		
		$cmd +=" -showcols $ShowCols "	
	}
	if ($Detailed)
	{		
		$cmd +=" -d "	
	}
	if ($StorageProfiles)
	{		
		$cmd +=" -sp "	
	}
	if ($Summary)
	{		
		$cmd +=" -summary "	
	}
	if ($Binding)
	{		
		$cmd +=" -binding "	
	}
	if ($VVAssociatedWithVM)
	{		
		$cmd +=" -vv "	
	}
	if ($RemoteCopy)
	{		
		$cmd +=" -rcopy "	
	}
	if ($AutoDismissed)
	{		
		$cmd +=" -autodismissed "	
	}	
	if ($container_name)
	{		
		$cmd+="  -sc $container_name "	
	}	
	else
	{
		return " FAILURE :  container_name is mandatory to execute Show-vVolvm command "
	}	
	if ($VM_name)
	{		
		$cmd+=" $VM_name "	
	}	
	
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $cmd
	write-debuglog " The Show-vVolvm command creates and admits physical disk definitions to enable the use of those disks " "INFO:" 
	return 	$Result	
} # End Show-vVolvm

####################################################################################################################
## FUNCTION Get-vVolSc
####################################################################################################################
Function Get-vVolSc
{
<#
  .SYNOPSIS
     The Get-vVolSc command displays VVol storage containers, used to contain
    VMware Volumes for Virtual Machines (VVols).

  .DESCRIPTION
     The Get-vVolSc command displays VVol storage containers, used to contain
    VMware Volumes for Virtual Machines (VVols).

  .EXAMPLE
	Get-vVolSc 
	
  .EXAMPLE
	Get-vVolSc -Detailed -SC_name test

  .PARAMETER Listcols
	List the columns available to be shown in the -showcols option described
	below.

  .PARAMETER Detailed
	Displays detailed information about the storage containers, including any
	VVols that have been auto-dismissed by remote copy DR operations.

		
  .PARAMETER SC_name  
	Storage Container
	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  Get-vVolSc
    LASTEDIT: January 2020
    KEYWORDS: Get-vVolSc
   
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
		$Listcols,
		
		[Parameter(Position=2, Mandatory=$false)]
		[System.String]
		$SC_name,
				
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection       
	)	
	
	Write-DebugLog "Start: In Get-vVolSc   - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting Get-vVolSc since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Get-vVolSc since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}		
	$cmd= "showvvolsc "	
		
	if ($Listcols)
	{	
		$cmd+=" -listcols "	
	}
	if ($Detailed)
	{	
		$cmd+=" -d "	
	}
	if ($SC_name)
	{		
		$cmd+=" $SC_name "	
	}	
	
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $cmd
	write-debuglog " The Get-vVolSc command creates and admits physical disk definitions to enable the use of those disks  " "INFO:" 
	return 	$Result	
} # End Get-vVolSc

####################################################################################################################
## FUNCTION Set-VVolSC
####################################################################################################################
Function Set-VVolSC
{
<#
  .SYNOPSIS
    Set-VVolSC can be used to create and remove storage containers for VMware Virtual Volumes (VVols).

    VVols are managed by the vSphere environment, and storage containers are
    used to maintain a logical collection of them. No physical space is
    pre-allocated for a storage container. Special VV sets (see showvvset) are 
	used to manage VVol storage containers.

  .DESCRIPTION    
    Set-VVolSC can be used to create and remove storage containers for
    VMware Virtual Volumes (VVols).

    VVols are managed by the vSphere environment, and storage containers are
    used to maintain a logical collection of them. No physical space is
    pre-allocated for a storage container. The special VV sets (see showvvset) 
	are used to manage VVol storage containers.

  .EXAMPLE
	Set-VVolSC -vvset XYZ (Note: set: already include in code please dont add with vvset)
	
  .EXAMPLE
	Set-VVolSC -Create -vvset XYZ

  .PARAMETER Create
	An empty existing <vvset> not already marked as a VVol Storage
	Container will be updated. The VV set should not contain any
	existing volumes (see -keep option below), must not be already
	marked as a storage container, nor may it be in use for other
	services, such as for remote copy groups, QoS, etc.

  .PARAMETER Remove
	If the specified VV set is a VVol storage container, this option will remove the VV set storage container and remove all of the associated volumes. The user will be asked to confirm that the associated volumes
	in this storage container should be removed.

  .PARAMETER Keep
	Used only with the -create option. If specified, allows a VV set with existing volumes to be marked as a VVol storage container.  However,
	this option should only be used if the existing volumes in the VV set
	are VVols.
	
  .PARAMETER vvset
	The Virtual Volume set (VV set) name, which is used, or to be used, as a VVol storage container.

  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME:  Set-VVolSC
    LASTEDIT: 03/08/2017
    KEYWORDS: Set-VVolSC
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(			
		
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$vvset,
		
		[Parameter(Position=1, Mandatory=$false)]
		[switch]
		$Create,
		
		[Parameter(Position=2, Mandatory=$false)]
		[switch]
		$Remove,
		
		[Parameter(Position=3, Mandatory=$false)]
		[switch]
		$Keep,
		
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection       
	)	
	
	Write-DebugLog "Start: In Set-VVolSC   - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting Set-VVolSC since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Set-VVolSC since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}		
	$cmd= " setvvolsc -f"
			
	if ($Create)
	{
		$cmd += " -create "
	}
	if ($Remove)
	{
		$cmd += " -remove "
	}
	if($Keep)
	{
		$cmd += " -keep "
	}
	if ($vvset)
	{		
		$cmd +="  set:$vvset "	
	}	
	else
	{
		return " FAILURE :  vvset is mandatory to execute Set-VVolSC command"
	}
	
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $cmd
	write-debuglog " The Set-VVolSC command creates and admits physical disk definitions to enable the use of those disks" "INFO:" 
	return 	$Result	
	
} # End Set-VVolSC

Export-ModuleMember Show-vVolvm , Get-vVolSc , Set-VVolSC