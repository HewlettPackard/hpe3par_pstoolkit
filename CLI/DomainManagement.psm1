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
##	File Name:		DomainManagement.psm1
##	Description: 	Domain Management cmdlets 
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
######################### FUNCTION Get-Domain #########################
##########################################################################
Function Get-Domain()
{
<#
  .SYNOPSIS
   Get-Domain - Show information about domains in the system.

  .DESCRIPTION
   The Get-Domain command displays a list of domains in a system.

  .EXAMPLE

  .PARAMETER D
   Specifies that detailed information is displayed.

  .Notes
    NAME: Get-Domain
    LASTEDIT 19-11-2019 
    KEYWORDS: Get-Domain
  
  .Link
    http://www.hpe.com

 #Requires PS -Version 3.0
#>
[CmdletBinding()]
 param(
	[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
	[switch]
	$D,

	[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
	$SANConnection = $global:SANConnection
 )

 Write-DebugLog "Start: In Get-Domain - validating input values" $Debug 
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
			Write-DebugLog "Stop: Exiting Get-Domain since SAN connection object values are null/empty" $Debug 
			Return "Unable to execute the cmdlet Get-Domain since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
		}
	}
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
   write-debuglog "$plinkresult"
   Return $plinkresult
 }

 $Cmd = " showdomain "

 if($D)
 {
	$Cmd += " -d "
 }

 $Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd
 Write-DebugLog "Executing Function : Get-Domain Command -->" INFO: 
  
 if($Result.count -gt 1)
 {
	$Cnt = $Result.count
		
 	$tempFile = [IO.Path]::GetTempFileName()
	$LastItem = $Result.Count -2  
	
	foreach ($s in  $Result[0..$LastItem] )
	{		
		$s= [regex]::Replace($s,"^ ","")			
		$s= [regex]::Replace($s," +",",")	
		$s= [regex]::Replace($s,"-","")
		$s= $s.Trim() 
		$temp1 = $s -replace 'CreationTime','Date,Time,Zone'
		$s = $temp1		
		Add-Content -Path $tempfile -Value $s				
	}
	Import-Csv $tempFile 
	del $tempFile 	
 }
 else
 {
	return  $Result
 }
 
 if($Result.count -gt 1)
 {
	return  " Success : Executing Get-Domain"
 }
 else
 {			
	return  $Result
 } 
 
} ##  End-of Get-Domain

##########################################################################
######################### FUNCTION Get-DomainSet #########################
##########################################################################
Function Get-DomainSet()
{
<#
  .SYNOPSIS
   Get-DomainSet - show domain set information

  .DESCRIPTION
   The Get-DomainSet command lists the domain sets defined on the system and
   their members.

  .EXAMPLE
   Get-DomainSet -D

  .PARAMETER D
   Show a more detailed listing of each set.

  .PARAMETER Domain
   Show domain sets that contain the supplied domains or patterns

  .PARAMETER SetOrDomainName
	specify either Domain Set name or domain name (member of Domain set)
   
  .Notes
    NAME: Get-DomainSet
    LASTEDIT 19-11-2019
    KEYWORDS: Get-DomainSet
  
  .Link
    http://www.hpe.com

 #Requires PS -Version 3.0
#>
[CmdletBinding()]
 param(
	[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
	[switch]
	$D,

	[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
	[switch]
	$Domain, 

	[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
	[System.String]
	$SetOrDomainName,

	[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
	$SANConnection = $global:SANConnection
 )

 Write-DebugLog "Start: In Get-DomainSet - validating input values" $Debug 
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
			Write-DebugLog "Stop: Exiting Get-DomainSet since SAN connection object values are null/empty" $Debug 
			Return "Unable to execute the cmdlet Get-DomainSet since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
		}
	}
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
   write-debuglog "$plinkresult"
   Return $plinkresult
 }

 $Cmd = " showdomainset "

 if($D)
 {
  $Cmd += " -d "
 }

 if($Domain)
 {
  $Cmd += " -domain "
 } 

 if($SetOrDomainName)
 {
  $Cmd += " $SetOrDomainName "
 }

 $Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd
 Write-DebugLog "Executing Function : Get-DomainSet Command -->" INFO:
 
 <#
 if($Result.count -gt 1)
 {
	$Cnt = $Result.count
		
 	$tempFile = [IO.Path]::GetTempFileName()
	$LastItem = $Result.Count -2  
	
	foreach ($s in  $Result[0..$LastItem] )
	{
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
 #>
 if($Result.count -gt 1)
 {
	#return  " Success : Executing Get-DomainSet"
	return  $Result
 }
 else
 {			
	return  $Result
 }
 
} ##  End-of Get-DomainSet

##########################################################################
######################### FUNCTION Move-Domain #########################
##########################################################################
Function Move-Domain()
{
<#
  .SYNOPSIS
   Move-Domain - Move objects from one domain to another, or into/out of domains

  .DESCRIPTION
   The Move-Domain command moves objects from one domain to another.

  .EXAMPLE
  
  .PARAMETER ObjName
	Specifies the name of the object to be moved.
  
  .PARAMETER DomainName
	Specifies the domain or domain set to which the specified object is moved. 
	The domain set name must start with "set:". To remove an object from any domain, specify the string "-unset" for the domain name or domain set specifier.
  
  .PARAMETER Vv
   Specifies that the object is a virtual volume.

  .PARAMETER Cpg
   Specifies that the object is a common provisioning group (CPG).

  .PARAMETER Host
   Specifies that the object is a host.

  .PARAMETER F
   Specifies that the command is forced. If this option is not used, the
   command requires confirmation before proceeding with its operation.

  .Notes
    NAME: Move-Domain
    LASTEDIT 19-11-2019
    KEYWORDS: Move-Domain
  
  .Link
    http://www.hpe.com

 #Requires PS -Version 3.0
#>
[CmdletBinding()]
 param(
 [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
 [switch]
 $vv,

 [Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
 [switch]
 $Cpg,

 [Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
 [switch]
 $Host,

 [Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
 [switch]
 $F,

 [Parameter(Position=4, Mandatory=$true, ValueFromPipeline=$true)]
 [System.String]
 $ObjName,

 [Parameter(Position=5, Mandatory=$true, ValueFromPipeline=$true)]
 [System.String]
 $DomainName,

 [Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
 $SANConnection = $global:SANConnection
 )

 Write-DebugLog "Start: In Move-Domain - validating input values" $Debug 
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
			Write-DebugLog "Stop: Exiting Move-Domain since SAN connection object values are null/empty" $Debug 
			Return "Unable to execute the cmdlet Move-Domain since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
		}
	}
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
   write-debuglog "$plinkresult"
   Return $plinkresult
 }

 $Cmd = " movetodomain "

 if($Vv)
 {
	$Cmd += " -vv "
 }

 if($Cpg)
 {
	$Cmd += " -cpg "
 }

 if($Host)
 {
	$Cmd += " -host "
 }

 if($F)
 {
	$Cmd += " -f "
 }
	
 if($ObjName)
 {
	$Cmd += " $ObjName "
 }
 
 if($DomainName)
 {
	$Cmd += " $DomainName "
 }

 $Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd
 Write-DebugLog "Executing Function : Move-Domain Command -->" INFO: 
 
 if($Result -match "Id")
 {
	$Cnt = $Result.count
		
 	$tempFile = [IO.Path]::GetTempFileName()
	$LastItem = $Result.Count -1  
	
	foreach ($s in  $Result[0..$LastItem] )
	{		
		$s= [regex]::Replace($s,"^ ","")			
		$s= [regex]::Replace($s," +",",")	
		$s= [regex]::Replace($s,"-","")
		$s= $s.Trim()
		Add-Content -Path $tempfile -Value $s				
	}
	Import-Csv $tempFile 
	del $tempFile 	
 }
 
 if($Result -match "Id")
 {
	return  " Success : Executing Move-Domain"
 }
 else
 {			
	return "FAILURE : While Executing Move-Domain `n $Result"
 }
 
} ##  End-of Move-Domain

##########################################################################
######################### FUNCTION New-Domain #########################
##########################################################################
Function New-Domain()
{
<#
  .SYNOPSIS
   New-Domain : Create a domain.

  .DESCRIPTION
   The New-Domain command creates system domains.

  .EXAMPLE
	New-Domain -Domain_name xxx
  
  .EXAMPLE
	New-Domain -Domain_name xxx -Comment "Hello"

  .PARAMETER Domain_name
	Specifies the name of the domain you are creating. The domain name can be no more than 31 characters. The name "all" is reserved.
	
  .PARAMETER Comment
   Specify any comments or additional information for the domain. The comment can be up to 511 characters long. Unprintable characters are not allowed. 
   The comment must be placed inside quotation marks if it contains spaces.

  .PARAMETER Vvretentiontimemax
   Specify the maximum value that can be set for the retention time of a volume in this domain. <time> is a positive integer value and in the range of 0 - 43,800 hours (1825 days).
   Time can be specified in days or hours providing either the 'd' or 'D' for day and 'h' or 'H' for hours following the entered time value.
   To disable setting the volume retention time in the domain, enter 0 for <time>.

  .Notes
    NAME: New-Domain
    LASTEDIT 19-11-2019 
    KEYWORDS: New-Domain
  
  .Link
    http://www.hpe.com

 #Requires PS -Version 3.0
#>
[CmdletBinding()]
 param(
	[Parameter(Position=0, Mandatory=$false , ValueFromPipeline=$true)]
	[System.String]
	$Comment,

	[Parameter(Position=1, Mandatory=$false , ValueFromPipeline=$true)]
	[System.String]
	$Vvretentiontimemax,

	[Parameter(Position=2, Mandatory=$true , ValueFromPipeline=$true)]
	[System.String]
	$Domain_name,

	[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
	$SANConnection = $global:SANConnection
 )

 Write-DebugLog "Start: In New-Domain - validating input values" $Debug 
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
        Write-DebugLog "Stop: Exiting New-Domain since SAN connection object values are null/empty" $Debug 
        Return "Unable to execute the cmdlet New-Domain since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
    }
  }
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
   write-debuglog "$plinkresult"
   Return $plinkresult
 }

 $Cmd = " createdomain "


 if($Comment)
 {
	$Cmd += " -comment " + '" ' + $Comment +' "'	
 }
 
 if($Vvretentiontimemax)
 {
	$Cmd += " -vvretentiontimemax $Vvretentiontimemax "
 } 

 if($Domain_name)
 {
	$Cmd += " $Domain_name "
 }
 else
 {
	return "Domain Required.."
 }
  
 #write-host "CMD = $cmd"
  
 $Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd
 Write-DebugLog "Executing Function : New-Domain Command -->" INFO: 
 
 Return $Result

 
 if ([string]::IsNullOrEmpty($Result))
 {
    Return $Result = "Domain : $Domain_name Created Successfully."
 }
 else
 {
	 Return $Result
 }
} ##  End-of New-Domain

##########################################################################
######################### FUNCTION New-DomainSet #########################
##########################################################################
Function New-DomainSet()
{
<#
  .SYNOPSIS
   New-DomainSet : create a domain set or add domains to an existing set

  .DESCRIPTION
   The New-DomainSet command defines a new set of domains and provides the option of assigning one or more existing domains to that set. 
   The command also allows the addition of domains to an existing set by use of the -add option.

  .EXAMPLE
   New-DomainSet -SetName xyz 

  .PARAMETER SetName
	Specifies the name of the domain set to create or add to, using up to 27 characters in length.
  
  .PARAMETER Add
   Specifies that the domains listed should be added to an existing set. At least one domain must be specified.

  .PARAMETER Comment
   Specifies any comment or additional information for the set. The comment can be up to 255 characters long. Unprintable characters are not allowed.

  .Notes
    NAME: New-DomainSet
    LASTEDIT 19-11-2019
    KEYWORDS: New-DomainSet
  
  .Link
    http://www.hpe.com

 #Requires PS -Version 3.0
#>
[CmdletBinding()]
 param(
 
	[Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
	[System.String]
	$SetName,
	
	[Parameter(Position=1, Mandatory=$false , ValueFromPipeline=$true)]
	[switch]
	$Add,

	[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
	[System.String]
	$Comment,	
	
	[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
	$SANConnection = $global:SANConnection
 )

 Write-DebugLog "Start: In New-DomainSet - validating input values" $Debug 
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
			Write-DebugLog "Stop: Exiting New-DomainSet since SAN connection object values are null/empty" $Debug 
			Return "Unable to execute the cmdlet New-DomainSet since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
		}
	}
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
	write-debuglog "$plinkresult"
	Return $plinkresult
 }

 $Cmd = " createdomainset " 
 
 if($Add)
 {
	$Cmd += " -add "
 }

 if($Comment)
 {
	$Cmd += " -comment " + '" ' + $Comment +' "'
 }
 
 if($SetName)
 {
	$Cmd += " $SetName "
 }

 $Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd
 Write-DebugLog "Executing Function : New-DomainSet Command -->" INFO: 
 
 Return $Result
} ##  End-of New-DomainSet

##########################################################################
######################### FUNCTION Remove-Domain #########################
##########################################################################
Function Remove-Domain()
{
<#
  .SYNOPSIS
   Remove-Domain - Remove a domain

  .DESCRIPTION
   The Remove-Domain command removes an existing domain from the system.

  .EXAMPLE
   Remove-Domain -DomainName xyz

  .PARAMETER DomainName
	Specifies the domain that is removed. If the -pat option is specified the DomainName will be treated as a glob-style pattern, and multiple domains will be considered.

  .PARAMETER Pat
   Specifies that names will be treated as glob-style patterns and that all domains matching the specified pattern are removed.

  .Notes
    NAME: Remove-Domain
    LASTEDIT 19-11-2019
    KEYWORDS: Remove-Domain
  
  .Link
    http://www.hpe.com

 #Requires PS -Version 3.0
#>
[CmdletBinding()]
 param(
	[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
	[switch]
	$Pat,

	[Parameter(Position=2, Mandatory=$true, ValueFromPipeline=$true)]
	[System.String]
	$DomainName,

	[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
	$SANConnection = $global:SANConnection
 )

 Write-DebugLog "Start: In Remove-Domain - validating input values" $Debug 
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
			Write-DebugLog "Stop: Exiting Remove-Domain since SAN connection object values are null/empty" $Debug 
			Return "Unable to execute the cmdlet Remove-Domain since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
		}
	}
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
   write-debuglog "$plinkresult"
   Return $plinkresult
 }

 $Cmd = " removedomain -f "

 if($Pat)
 {
	$Cmd += " -pat "
 }

 if($DomainName)
 {
	$Cmd += " $DomainName "
 }

 $Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd
 Write-DebugLog "Executing Function : Remove-Domain Command -->" INFO: 
 Return $Result
 
} ##  End-of Remove-Domain

##########################################################################
######################### FUNCTION Remove-DomainSet #########################
##########################################################################
Function Remove-DomainSet()
{
<#
  .SYNOPSIS
   Remove-DomainSet : remove a domain set or remove domains from an existing set

  .DESCRIPTION
   The Remove-DomainSet command removes a domain set or removes domains from an existing set.

  .EXAMPLE
	Remove-DomainSet -SetName xyz
	
  .PARAMETER SetName
	Specifies the name of the domain set. If the -pat option is specified the setname will be treated as a glob-style pattern, and multiple domain sets will be considered.

  .PARAMETER Domain
	Optional list of domain names that are members of the set.
	If no <Domain>s are specified, the domain set is removed, otherwise the specified <Domain>s are removed from the domain set. 
	If the -pat option is specified the domain will be treated as a glob-style pattern, and multiple domains will be considered.
  
  .PARAMETER F
   Specifies that the command is forced. If this option is not used, the command requires confirmation before proceeding with its operation.

  .PARAMETER Pat
   Specifies that both the set name and domains will be treated as glob-style patterns.

  .Notes
    NAME: Remove-DomainSet
    LASTEDIT 19-11-2019
    KEYWORDS: Remove-DomainSet
  
  .Link
    http://www.hpe.com

 #Requires PS -Version 3.0
#>
[CmdletBinding()]
 param(
 [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
 [switch]
 $F,

 [Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
 [switch]
 $Pat,

 [Parameter(Position=2, Mandatory=$true, ValueFromPipeline=$true)]
 [System.String]
 $SetName,

 [Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
 [System.String]
 $Domain,

 [Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
 $SANConnection = $global:SANConnection
 )

 Write-DebugLog "Start: In Remove-DomainSet - validating input values" $Debug 
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
			Write-DebugLog "Stop: Exiting Remove-DomainSet since SAN connection object values are null/empty" $Debug 
			Return "Unable to execute the cmdlet Remove-DomainSet since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
		}
	}
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
   write-debuglog "$plinkresult"
   Return $plinkresult
 }

 $Cmd = " removedomainset "

 if($F)
 {
  $Cmd += " -f "
 }

 if($Pat)
 {
  $Cmd += " -pat "
 }

 if($SetName)
 {
  $Cmd += " $SetName "
 }

 if($Domain)
 {
  $Cmd += " $Domain "
 }

 $Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd
 Write-DebugLog "Executing Function : Remove-DomainSet Command -->" INFO: 
 
 Return $Result
} ##  End-of Remove-DomainSet

##########################################################################
######################### FUNCTION Set-Domain #########################
##########################################################################
Function Set-Domain()
{
<#
  .SYNOPSIS
   Set-Domain Change current domain CLI environment parameter.

  .DESCRIPTION
   The Set-Domain command changes the current domain CLI environment parameter.

  .EXAMPLE
   Set-Domain
   
  .EXAMPLE
   Set-Domain -Domain "XXX"
   
  .PARAMETER Domain
	Name of the domain to be set as the working domain for the current CLI session.  
	If the <domain> parameter is not present or is equal to -unset then the working domain is set to no current domain.
	

  .Notes
    NAME: Set-Domain
    LASTEDIT 19-11-2019
    KEYWORDS: Set-Domain
  
  .Link
    http://www.hpe.com

 #Requires PS -Version 3.0
#>
 [CmdletBinding()]
 param(
	[Parameter(Position=0, Mandatory=$false)]
	[System.String]
	$Domain,

	[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
	$SANConnection = $global:SANConnection
 )

 Write-DebugLog "Start: In Set-Domain - validating input values" $Debug 
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
        Write-DebugLog "Stop: Exiting Set-Domain since SAN connection object values are null/empty" $Debug 
        Return "Unable to execute the cmdlet Set-Domain since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
    }
  }
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
   write-debuglog "$plinkresult"
   Return $plinkresult
 }

 $Cmd = " changedomain "

 if($Domain)
 {
	$Cmd += " $Domain "
 }

 $Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd
 Write-DebugLog "Executing Function : Set-Domain Command" INFO: 
 
 if([System.String]::IsNullOrEmpty($Domain))
 {
	$Result = "Working domain is unset to current domain."
	Return $Result
 }
 else
 {
	if([System.String]::IsNullOrEmpty($Result))
	 {
		$Result = "Domain : $Domain to be set as the working domain for the current CLI session."
		Return $Result
	 }
	 else
	 {
		Return $Result
	 }	
 }
 
} ##  End-of Set-Domain

##########################################################################
######################### FUNCTION Update-Domain #########################
##########################################################################
Function Update-Domain()
{
<#
  .SYNOPSIS
   Update-Domain : Set parameters for a domain.

  .DESCRIPTION
   The Update-Domain command sets the parameters and modifies the properties of a
   domain.

  .EXAMPLE
   Update-Domain -DomainName xyz
 
  .PARAMETER DomainName
	Indicates the name of the domain.(Existing Domain Name)

  .PARAMETER NewName
   Changes the name of the domain.

  .PARAMETER Comment
   Specifies comments or additional information for the domain. The comment can be up to 511 characters long and must be enclosed in quotation
   marks. Unprintable characters are not allowed within the <comment> specifier.

  .PARAMETER Vvretentiontimemax
   Specifies the maximum value that can be set for the retention time of
   a volume in this domain. <time> is a positive integer value and in the
   range of 0 - 43,800 hours (1825 days). Time can be specified in days or
   hours providing either the 'd' or 'D' for day and 'h' or 'H' for hours
   following the entered time value.
   To remove the maximum volume retention time for the domain, enter
   '-vvretentiontimemax ""'. As a result, the maximum volume retention
   time for the system is used instead.
   To disable setting the volume retention time in the domain, enter 0
   for <time>.

  .Notes
    NAME: Update-Domain
    LASTEDIT 19-11-2019
    KEYWORDS: Update-Domain
  
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
	$Comment,

	[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
	[System.String]
	$Vvretentiontimemax,

	[Parameter(Position=3, Mandatory=$true, ValueFromPipeline=$true)]
	[System.String]
	$DomainName,

	[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
	$SANConnection = $global:SANConnection
 )

 Write-DebugLog "Start: In Update-Domain - validating input values" $Debug 
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
			Write-DebugLog "Stop: Exiting Update-Domain since SAN connection object values are null/empty" $Debug 
			Return "Unable to execute the cmdlet Update-Domain since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
		}
	}
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
   write-debuglog "$plinkresult"
   Return $plinkresult
 }

	$Cmd = " setdomain "

 if($NewName)
 {
	$Cmd += " -name $NewName "
 }

 if($Comment)
 {
	$Cmd += " -comment " + '" ' + $Comment +' "'
 }

 if($Vvretentiontimemax)
 {
	$Cmd += " -vvretentiontimemax $Vvretentiontimemax "
 }

 if($DomainName)
 {
	$Cmd += " $DomainName "
 }

 $Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd
 Write-DebugLog "Executing Function : Update-Domain Command -->" INFO: 
 
 Return $Result
} ##  End-of Update-Domain

##########################################################################
######################### FUNCTION Update-DomainSet #########################
##########################################################################
Function Update-DomainSet()
{
<#
  .SYNOPSIS
   Update-DomainSet : set parameters for a domain set

  .DESCRIPTION
   The Update-DomainSet command sets the parameters and modifies the properties of
   a domain set.

  .EXAMPLE
   Update-DomainSet -DomainSetName xyz
  
  .PARAMETER DomainSetName
	Specifies the name of the domain set to modify.
	
  .PARAMETER Comment
   Specifies any comment or additional information for the set. The
   comment can be up to 255 characters long. Unprintable characters are
   not allowed.

  .PARAMETER NewName
   Specifies a new name for the domain set, using up to 27 characters in length.

  .Notes
    NAME: Update-DomainSet
    LASTEDIT 19-11-2019
    KEYWORDS: Update-DomainSet
  
  .Link
    http://www.hpe.com

 #Requires PS -Version 3.0
#>
[CmdletBinding()]
 param(
 [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
 [System.String]
 $Comment,

 [Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
 [System.String]
 $NewName,

 [Parameter(Position=2, Mandatory=$true, ValueFromPipeline=$true)]
 [System.String]
 $DomainSetName,

 [Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
 $SANConnection = $global:SANConnection
 )

 Write-DebugLog "Start: In Update-DomainSet - validating input values" $Debug 
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
			Write-DebugLog "Stop: Exiting Update-DomainSet since SAN connection object values are null/empty" $Debug 
			Return "Unable to execute the cmdlet Update-DomainSet since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
		}
	}
 }

 $plinkresult = Test-PARCli -SANConnection $SANConnection
 if($plinkresult -match "FAILURE :")
 {
   write-debuglog "$plinkresult"
   Return $plinkresult
 }

 $Cmd = " setdomainset "

 if($Comment)
 {
	$Cmd += " -comment " + '" ' + $Comment +' "'
 }

 if($NewName)
 {
  $Cmd += " -name $NewName "
 }

 if($DomainSetName)
 {
  $Cmd += " $DomainSetName "
 }

 $Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd
 Write-DebugLog "Executing Function : Update-DomainSet Command -->" INFO: 
 
 Return $Result
 
} ##  End-of Update-DomainSet


Export-ModuleMember Get-Domain , Get-DomainSet , Move-Domain , New-Domain , New-DomainSet , Remove-Domain , Remove-DomainSet , Set-Domain , Update-Domain , Update-DomainSet