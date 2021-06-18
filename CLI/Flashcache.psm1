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
##	File Name:		Flashcache.psm1
##	Description: 	Flash cache cmdlets 
##		
##	Created:		November 2019
##	Last Modified:	November 2019
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

##########################################################################
######################### FUNCTION New-FlashCache ####################
##########################################################################
Function New-FlashCache()
{
<#
  .SYNOPSIS
   New-FlashCache - Creates flash cache for the cluster.

  .DESCRIPTION
   The New-FlashCache command creates flash cache of <size> for each node pair. The flash cache will be created from SSD drives.

  .EXAMPLE

  .PARAMETER Sim
   Specifies that the Adaptive Flash Cache will be run in simulator mode. The simulator mode does not require the use of SSD drives.

  .PARAMETER RAIDType
   Specifies the RAID type of the logical disks for Flash Cache; r0 for RAID-0 or r1 for RAID-1. If no RAID type is specified, the default is chosen by the storage system.

  .PARAMETER Size
	Specifies the size for the flash cache in MiB for each node pair. The flashcache size should be a multiple of 16384 (16GiB), and be an integer. 
	The minimum size of the flash cache is 64GiB. The maximum size of the flash cache is based on the node types, ranging from 768GiB up to 12288GiB (12TiB).
    An optional suffix (with no whitespace before the suffix) will modify the units to GiB (g or G suffix) or TiB (t or T suffix).
   
  .Notes
    NAME: New-FlashCache
    LASTEDIT 19/11/2019
    KEYWORDS: New-FlashCache
  
  .Link
    http://www.hpe.com

 #Requires PS -Version 3.0
#>
[CmdletBinding()]
 param(
	 [Parameter(Position=0, Mandatory=$false , ValueFromPipeline=$true)]
	 [switch]
	 $Sim,

	 [Parameter(Position=1, Mandatory=$false , ValueFromPipeline=$true)]
	 [System.String]
	 $RAIDType,

	 [Parameter(Position=2, Mandatory=$true , ValueFromPipeline=$true)]
	 [System.String]
	 $Size,

	 [Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
	 $SANConnection = $global:SANConnection
 )

 Write-DebugLog "Start: In New-FlashCache - validating input values" $Debug 
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
			Write-DebugLog "Stop: Exiting New-FlashCache since SAN connection object values are null/empty" $Debug 
			Return "Unable to execute the cmdlet New-FlashCache since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
		}
	}
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
   write-debuglog "$plinkresult"
   Return $plinkresult
 }

 $Cmd = " createflashcache "

 if($Sim)
 {
	$Cmd += " -sim "
 }

 if($RAIDType)
 {
	$Cmd += " -t $RAIDType "
 }

 if($Size)
 {
	$Cmd += " $Size "
 }

 $Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd
 Write-DebugLog "Executing Function : New-FlashCache Command -->" INFO: 
 
 Return $Result
} ##  End-of New-FlashCache


##########################################################################
######################### FUNCTION Set-FlashCache ####################
##########################################################################
Function Set-FlashCache()
{
<#
  .SYNOPSIS
   Set-FlashCache - Sets the flash cache policy for virtual volumes

  .DESCRIPTION
   The Set-FlashCache command allows you to set the policy of the flash cache for virtual volumes. The policy is set by using virtual volume sets(vvset). 
   The sys:all is used to enable the policy on all virtual volumes in the system.

  .EXAMPLE
   Set-FlashCache
   
  .PARAMETER Enable
	Will turn on the flash cache policy for the target object.
  
  .PARAMETER Disable
	Will turn off flash cache policy for the target object.
  
  .PARAMETER Clear
	Will turn off policy and can only be issued against the sys:all target.
  
  .PARAMETER vvSet
	vvSet refers to the target object name as listed in the showvvset command. Pattern is glob-style (shell-style) patterns (see help on sub,globpat).
	Note(set Name Should de is the same formate Ex:  vvset:vvset1 )
	
  .PARAMETER All
	The policy is applied to all virtual volumes.
  
  .Notes
    NAME: Set-FlashCache
    LASTEDIT 19/11/2019
    KEYWORDS: 3parVersion
  
  .Link
    http://www.hpe.com

 #Requires PS -Version 3.0
#>
[CmdletBinding()]
 param(
	 [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
	 [switch]
	 $Enable,

	 [Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
	 [switch]
	 $Disable,
	 
	 [Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
	 [switch]
	 $Clear,

	 [Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
	 [System.String]
	 $vvSet,
	 
	 [Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
	 [switch]
	 $All,

	 [Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
	 $SANConnection = $global:SANConnection
 )

 Write-DebugLog "Start: In Set-FlashCache - validating input values" $Debug 
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
			Write-DebugLog "Stop: Exiting Set-FlashCache since SAN connection object values are null/empty" $Debug 
			Return "Unable to execute the cmdlet Set-FlashCache since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
		}
	}
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
   write-debuglog "$plinkresult"
   Return $plinkresult
 }

 $Cmd = " setflashcache "

 if($Enable)
 {
	$Cmd += " enable "
 }
 elseif($Disable)
 {
	$Cmd += " disable "
 }

 elseif($Clear)
 {
	$Cmd += " clear "
 }
 else
 {
	return "Select at least one from [ Enable | Disable | Clear] "
 }
  
 if($vvSet)
 {
	$Cmd += " $vvSet "
 }
 
  if($All)
 {
	$Cmd += " sys:all "
 }

 $Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd
 Write-DebugLog "Executing Function : Set-FlashCache Command -->" INFO: 
 
 Return $Result
} ##  End-of Set-FlashCache

##########################################################################
######################### FUNCTION Remove-FlashCache #####################
##########################################################################
Function Remove-FlashCache()
{
<#
  .SYNOPSIS
   Remove-FlashCache - Removes flash cache from the cluster.

  .DESCRIPTION
   The Remove-FlashCache command removes the flash cache from the cluster and will stop use of the extended cache.

  .EXAMPLE
   Remove-FlashCache

  .PARAMETER F
   Specifies that the command is forced. If this option is not used, the command requires confirmation before proceeding with its operation.

  .Notes
    NAME: Remove-FlashCache
    LASTEDIT 19/11/2019
    KEYWORDS: Remove-FlashCache
  
  .Link
    http://www.hpe.com

 #Requires PS -Version 3.0
#>
[CmdletBinding()]
 param(
	 [Parameter(Position=0, Mandatory=$false)]
	 [switch]
	 $F,

	 [Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
	 $SANConnection = $global:SANConnection
 )

 Write-DebugLog "Start: In Remove-FlashCache - validating input values" $Debug 
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
			Write-DebugLog "Stop: Exiting Remove-FlashCache since SAN connection object values are null/empty" $Debug 
			Return "Unable to execute the cmdlet Remove-FlashCache since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
		}
	}
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
   write-debuglog "$plinkresult"
   Return $plinkresult
 }

 $Cmd = " removeflashcache "

 if($F)
 {
	$Cmd += " -f "
 }

 $Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd
 Write-DebugLog "Executing Function : Remove-FlashCache Command -->" INFO: 
 
 Return $Result
} ##  End-of Remove-FlashCache


Export-ModuleMember New-FlashCache , Set-FlashCache , Remove-FlashCache