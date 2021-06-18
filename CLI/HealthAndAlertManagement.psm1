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
##	File Name:		HealthandAlertManagement.psm1
##	Description: 	Health and Alert Management cmdlets 
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
######################### FUNCTION Get-Alert #########################
##########################################################################
Function Get-Alert()
{
<#
  .SYNOPSIS
   Get-Alert - Display system alerts.

  .DESCRIPTION
   The Get-Alert command displays the status of system alerts. When issued
   without options, all new customer alerts are displayed.

  .EXAMPLE
   Get-Alert -N
   
  .EXAMPLE
   Get-Alert -F
   
  .EXAMPLE
   Get-Alert -All
   
  .PARAMETER N
   Specifies that only new customer alerts are displayed.
   This is the default.

  .PARAMETER A
   Specifies that only acknowledged alerts are displayed.

  .PARAMETER F
   Specifies that only fixed alerts are displayed.

  .PARAMETER All
   Specifies that all customer alerts are displayed.
   
   
   The format of the alert display is controlled by the following options:

  .PARAMETER D
   Specifies that detailed information is displayed. Cannot be specified
   with the -oneline option.

  .PARAMETER Oneline
   Specifies that summary information is displayed in a tabular form with
   one line per alert. For customer alerts, the message text will be
   truncated if it is too long unless the -wide option is also specified.

  .PARAMETER Svc
   Specifies that only service alerts are displayed. This option can only be
   used with the -d or -oneline formatting options.

  .PARAMETER Wide
   Do not truncate the message text. Only valid for customer alerts and if the -oneline option is also specified.

  .Notes
    NAME: Get-Alert
    LASTEDIT 19/11/2019
    KEYWORDS: Get-Alert
  
  .Link
    http://www.hpe.com

 #Requires PS -Version 3.0
#>
[CmdletBinding()]
 param(
	[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
	[switch]
	$N,

	[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
	[switch]
	$A,

	[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
	[switch]
	$F,

	[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
	[switch]
	$All,

	[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
	[switch]
	$D,

	[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
	[switch]
	$Oneline,

	[Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
	[switch]
	$Svc,

	[Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
	[switch]
	$Wide,

	[Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
	$SANConnection = $global:SANConnection
 )

 Write-DebugLog "Start: In Get-Alert - validating input values" $Debug 
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
			Write-DebugLog "Stop: Exiting Get-Alert since SAN connection object values are null/empty" $Debug 
			Return "Unable to execute the cmdlet Get-Alert since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
		}
	}
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
   write-debuglog "$plinkresult"
   Return $plinkresult
 }

	$Cmd = " showalert "

 if($N)
 {
	$Cmd += " -n "
 }

 if($A)
 {
	$Cmd += " -a "
 }

 if($F)
 {
	$Cmd += " -f "
 }

 if($All)
 {
	$Cmd += " -all "
 }

 if($D)
 {
	$Cmd += " -d "
 }

 if($Svc)
 {
	$Cmd += " -svc "
 }

 if($Wide)
 {
	$Cmd += " -wide "
 }

 if($Oneline)
 {
	$Cmd += " -oneline "
 }

 $Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd
 Write-DebugLog "Executing Function : Get-Alert Command -->" INFO: 
 
 Return $Result
} ##  End-of Get-Alert

##########################################################################
######################### FUNCTION Get-EventLog ##########################
##########################################################################
Function Get-EventLog()
{
<#
  .SYNOPSIS
   Get-EventLog - Show the system event log.

  .DESCRIPTION
   The Get-EventLog command displays the current system event log.

  .EXAMPLE

  .PARAMETER Min
   Specifies that only events occurring within the specified number of
   minutes are shown. The <number> is an integer from 1 through 2147483647.

  .PARAMETER More
   Specifies that you can page through several events at a time.

  .PARAMETER Oneline
   Specifies that each event is formatted as one line.

  .PARAMETER D
   Specifies that detailed information is displayed.

  .PARAMETER Startt
   Specifies that only events after a specified time are to be shown. The
   time argument can be specified as either <timespec>, <datespec>, or
   both. If you would like to specify both a <timespec> and <datespec>, you must
   place quotation marks around them; for example, -startt "2012-10-29 00:00".
	   <timespec>
	   Specified as the hour (hh), as interpreted on a 24 hour clock, where
	   minutes (mm) and seconds (ss) can be optionally specified.
	   Acceptable formats are hh:mm:ss or hhmm.
	   <datespec>
	   Specified as the month (mm or month_name) and day (dd), where the
	   year (yy) can be optionally specified. Acceptable formats are
	   mm/dd/yy, month_name dd, dd month_name yy, or yy-mm-dd. If the
	   syntax yy-mm-dd is used, the year must be specified.

  .PARAMETER Endt
   Specifies that only events before a specified time are to be shown. The
   time argument can be specified as either <timespec>, <datespec>, or both.
   See -startt for descriptions of <timespec> and <datespec>.
   
   
   The <pattern> argument in the following options is a regular expression pattern that is used
   to match against the events each option produces.
   (See help on sub,regexpat.)
   
   For each option, the pattern argument can be specified multiple times by repeating the option
   and <pattern>. For example:
   
   showeventlog -type Disk.* -type <tpdtcl client> -sev Major
   The "-sev Major" displays all events of severity Major and with a type that matches either
   the regular expression Disk.* or <tpdtcl client>.

  .PARAMETER Sev
   Specifies that only events with severities that match the specified
   pattern(s) are displayed. The supported severities include Fatal,
   Critical, Major, Minor, Degraded, Informational and Debug

  .PARAMETER Nsev
   Specifies that only events with severities that do not match the
   specified pattern(s) are displayed. The supported severities
   include Fatal, Critical, Major, Minor, Degraded, Informational and
   Debug.

  .PARAMETER Class
   Specifies that only events with classes that match the specified
   pattern(s) are displayed.

  .PARAMETER Nclass
   Specifies that only events with classes that do not match the specified
   pattern(s) are displayed.

  .PARAMETER Node
   Specifies that only events from nodes that match the specified
   pattern(s) are displayed.

  .PARAMETER Nnode
   Specifies that only events from nodes that do not match the specified
   pattern(s) are displayed.

  .PARAMETER Type
   Specifies that only events with types that match the specified
   pattern(s) are displayed.

  .PARAMETER Ntype
   Specifies that only events with types that do not match the specified
   pattern(s) are displayed.

  .PARAMETER Msg
   Specifies that only events, whose messages match the specified
   pattern(s), are displayed.

  .PARAMETER Nmsg
   Specifies that only events, whose messages do not match the specified
   pattern(s), are displayed.

  .PARAMETER Comp
   Specifies that only events, whose components match the specified
   pattern(s), are displayed.

  .PARAMETER Ncomp
   Specifies that only events, whose components do not match the specified
   pattern(s), are displayed.

  .Notes
    NAME: Get-EventLog
    LASTEDIT 19/11/2019
    KEYWORDS: Get-EventLog
  
  .Link
    http://www.hpe.com

 #Requires PS -Version 3.0
#>
[CmdletBinding()]
 param(
	[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
	[System.String]
	$Min,

	[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
	[switch]
	$More,

	[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
	[switch]
	$Oneline,

	[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
	[switch]
	$D,

	[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
	[System.String]
	$Startt,

	[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
	[System.String]
	$Endt,

	[Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
	[System.String]
	$Sev,

	[Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
	[System.String]
	$Nsev,

	[Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
	[System.String]
	$Class,

	[Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
	[System.String]
	$Nclass,

	[Parameter(Position=10, Mandatory=$false, ValueFromPipeline=$true)]
	[System.String]
	$Node,

	[Parameter(Position=11, Mandatory=$false, ValueFromPipeline=$true)]
	[System.String]
	$Nnode,

	[Parameter(Position=12, Mandatory=$false, ValueFromPipeline=$true)]
	[System.String]
	$Type,

	[Parameter(Position=13, Mandatory=$false, ValueFromPipeline=$true)]
	[System.String]
	$Ntype,

	[Parameter(Position=14, Mandatory=$false, ValueFromPipeline=$true)]
	[System.String]
	$Msg,

	[Parameter(Position=15, Mandatory=$false, ValueFromPipeline=$true)]
	[System.String]
	$Nmsg,

	[Parameter(Position=16, Mandatory=$false, ValueFromPipeline=$true)]
	[System.String]
	$Comp,

	[Parameter(Position=17, Mandatory=$false, ValueFromPipeline=$true)]
	[System.String]
	$Ncomp,

	[Parameter(Position=18, Mandatory=$false, ValueFromPipeline=$true)]
	$SANConnection = $global:SANConnection
 )

 Write-DebugLog "Start: In Get-EventLog - validating input values" $Debug 
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
			Write-DebugLog "Stop: Exiting Get-EventLog since SAN connection object values are null/empty" $Debug 
			Return "Unable to execute the cmdlet Get-EventLog since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
		}
	}
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
   write-debuglog "$plinkresult"
   Return $plinkresult
 }

 $Cmd = " showeventlog "

 if($Min)
 {
	$Cmd += " -min $Min "
 }

 if($More)
 {
	$Cmd += " -more "
 }

 if($Oneline)
 {
	$Cmd += " -oneline "
 }

 if($D)
 {
	$Cmd += " -d "
 }

 if($Startt)
 {
	$Cmd += " -startt $Startt "
 }

 if($Endt)
 {
	$Cmd += " -endt $Endt "
 }

 if($Sev)
 {
	$Cmd += " -sev $Sev "
 }

 if($Nsev)
 {
	$Cmd += " -nsev $Nsev "
 }

 if($Class)
 {
	$Cmd += " -class $Class "
 }

 if($Nclass)
 {
	$Cmd += " -nclass $Nclass "
 }

 if($Node)
 {
	$Cmd += " -node $Node "
 }

 if($Nnode)
 {
	$Cmd += " -nnode $Nnode "
 }

 if($Type)
 {
	$Cmd += " -type $Type "
 }

 if($Ntype)
 {
	$Cmd += " -ntype $Ntype "
 }

 if($Msg)
 {
	$Cmd += " -msg $Msg "
 }

 if($Nmsg)
 {
	$Cmd += " -nmsg $Nmsg "
 }

 if($Comp)
 {
	$Cmd += " -comp $Comp "
 }

 if($Ncomp)
 {
	$Cmd += " -ncomp $Ncomp "
 }

 $Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd
 Write-DebugLog "Executing Function : Get-EventLog Command -->" INFO: 
 
 Return $Result
} ##  End-of Get-EventLog

##########################################################################
############################ FUNCTION Get-Health #########################
##########################################################################
Function Get-Health()
{
<#
  .SYNOPSIS
   Get-Health - Check the current health of the system.

  .DESCRIPTION
   The Get-Health command checks the status of system hardware and software components, and reports any issues

  .EXAMPLE
  
  .PARAMETER Component
	Indicates the component to check. Use -list option to get the list of components.
	
  .PARAMETER Lite
   Perform a minimal health check.

  .PARAMETER Svc
   Perform a thorough health check. This is the default option.

  .PARAMETER Full
   Perform the maximum health check. This option cannot be used with the -lite option.

  .PARAMETER List
   List all components that will be checked.

  .PARAMETER Quiet
   Do not display which component is currently being checked. Do not display the footnote with the -list option.

  .PARAMETER D
   Display detailed information regarding the status of the system.

  .Notes
    NAME: Get-Health
    LASTEDIT 19/11/2019
    KEYWORDS: Get-Health
  
  .Link
    http://www.hpe.com

 #Requires PS -Version 3.0
#>
[CmdletBinding()]
 param(
	[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
	[switch]
	$Lite,

	[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
	[switch]
	$Svc,

	[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
	[switch]
	$Full,

	[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
	[switch]
	$List,

	[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
	[switch]
	$Quiet,

	[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
	[switch]
	$D,

	[Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
	[System.String]
	$Component,

	[Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
	$SANConnection = $global:SANConnection
 )

 Write-DebugLog "Start: In Get-Health - validating input values" $Debug 
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
			Write-DebugLog "Stop: Exiting Get-Health since SAN connection object values are null/empty" $Debug 
			Return "Unable to execute the cmdlet Get-Health since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
		}
	}
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
   write-debuglog "$plinkresult"
   Return $plinkresult
 }

	$Cmd = " checkhealth "

 if($Lite)
 {
	$Cmd += " -lite "
 }

 if($Svc)
 {
	$Cmd += " -svc "
 }

 if($Full)
 {
	$Cmd += " -full "
 }

 if($List)
 {
	$Cmd += " -list "
 }

 if($Quiet)
 {
	$Cmd += " -quiet "
 }

 if($D)
 {
	$Cmd += " -d "
 }

 if($Component)
 {
	$Cmd += " $Component "
 }

 $Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd
 Write-DebugLog "Executing Function : Get-Health Command -->" INFO: 
 
 Return $Result
} ##  End-of Get-Health

##########################################################################
######################### FUNCTION Remove-Alerts #########################
##########################################################################
Function Remove-Alerts()
{
<#
  .SYNOPSIS
   Remove-Alerts - Remove one or more alerts.

  .DESCRIPTION
   The Remove-Alerts command removes one or more alerts from the system.

  .EXAMPLE

  .PARAMETER  Alert_ID
	Indicates a specific alert to be removed from the system. This specifier can be repeated to remove multiple alerts. If this specifier is not used, the -a option must be used.
  
  .PARAMETER All
   Specifies all alerts from the system and prompts removal for each alert.
   If this option is not used, then the <alert_ID> specifier must be used.

  .PARAMETER F
   Specifies that the command is forced. If this option is not used and
   there are alerts in the "new" state, the command requires confirmation
   before proceeding with the operation.

  .Notes
    NAME: Remove-Alerts
    LASTEDIT 19/11/2019
    KEYWORDS: Remove-Alerts
  
  .Link
    http://www.hpe.com

 #Requires PS -Version 3.0
#>
[CmdletBinding()]
 param(
	[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
	[switch]
	$All,

	[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
	[switch]
	$F,

	[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
	[System.String]
	$Alert_ID,

	[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
	$SANConnection = $global:SANConnection
 )

 Write-DebugLog "Start: In Remove-Alerts - validating input values" $Debug 
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
			Write-DebugLog "Stop: Exiting Remove-Alerts since SAN connection object values are null/empty" $Debug 
			Return "Unable to execute the cmdlet Remove-Alerts since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
		}
	}
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
   write-debuglog "$plinkresult"
   Return $plinkresult
 }

	$Cmd = " removealert "

 if($F)
 {
	$Cmd += " -f "
 }
 
 if($All)
 {
	$Cmd += " -a "
 }
 elseif($Alert_ID)
 {
	$Cmd += " $Alert_ID "
 }
 else
 {
	Return "Please Select At-least One from [ All | Alert_ID ]..."
 }

 $Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd
 Write-DebugLog "Executing Function : Remove-Alerts Command -->" INFO: 
 
 Return $Result
 
} ##  End-of Remove-Alerts

##########################################################################
######################### FUNCTION Set-Alert #########################
##########################################################################
Function Set-Alert()
{
<#
  .SYNOPSIS
   Set-Alert - Set the status of system alerts.

  .DESCRIPTION
   The Set-Alert command sets the status of system alerts.

  .EXAMPLE

  .PARAMETER Alert_ID
	Specifies that the status of a specific alert be set. This specifier
	can be repeated to indicate multiple specific alerts. Up to 99 alerts
	can be specified in one command. If not specified, the -a option must
	be specified on the command line.
  
  .PARAMETER All
   Specifies that the status of all alerts be set. If not specified, the Alert_ID specifier must be specified.

  .PARAMETER New
	Specifies that the alert(s), as indicated with the <alert_ID> specifier
	or with option -a, be set as "New"(new), "Acknowledged"(ack), or
	"Fixed"(fixed).

  .PARAMETER Ack
	Specifies that the alert(s), as indicated with the <alert_ID> specifier
	or with option -a, be set as "New"(new), "Acknowledged"(ack), or
	"Fixed"(fixed).

  .PARAMETER Fixed
	Specifies that the alert(s), as indicated with the <alert_ID> specifier
	or with option -a, be set as "New"(new), "Acknowledged"(ack), or
	"Fixed"(fixed).

   
  .Notes
    NAME: Set-Alert
    LASTEDIT 19/11/2019
    KEYWORDS: Set-Alert
  
  .Link
    http://www.hpe.com

 #Requires PS -Version 3.0
#>
[CmdletBinding()]
 param(
 
	[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
	[switch]
	$New,

	[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
	[switch]
	$Ack,

	[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
	[switch]
	$Fixed,

	[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
	[switch]
	$All,

	[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
	[System.String]
	$Alert_ID,

	[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
	$SANConnection = $global:SANConnection
 )

 Write-DebugLog "Start: In Set-Alert - validating input values" $Debug 
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
			Write-DebugLog "Stop: Exiting Set-Alert since SAN connection object values are null/empty" $Debug 
			Return "Unable to execute the cmdlet Set-Alert since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
		}
	}
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
   write-debuglog "$plinkresult"
   Return $plinkresult
 }

	$Cmd = " setalert "

 if($New)
 {
	$Cmd += " new "
 }
 elseif($Ack)
 {
	$Cmd += " ack "
 }
 elseif($Fixed)
 {
	$Cmd += " fixed "
 }
 else
 {
	Return "Please Select At-least One from [ New | Ack | Fixed ]..." 
 }

 if($All)
 {
	$Cmd += " -a "
 }
 elseif($Alert_ID)
 {
	$Cmd += " $Alert_ID "
 }
 else
 {
	Return "Please Select At-least One from [ All | Alert_ID ]..." 
 }

 $Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd
 Write-DebugLog "Executing Function : Set-Alert Command -->" INFO: 
 
 Return $Result
} ##  End-of Set-Alert

Export-ModuleMember Get-Alert , Get-EventLog , Get-Health , Remove-Alerts , Set-Alert