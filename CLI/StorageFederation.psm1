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
##	File Name:		StorageFederation.psm1
##	Description: 	Storage Federation cmdlets 
##		
##	Created:		March 2020
##	Last Modified:	March 2020
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
## FUNCTION Join-Federation
######################################################################################################################
Function Join-Federation
{
<#
  .SYNOPSIS  
	The Join-Federation command makes the StoreServ system a member of the Federation identified by the specified name and UUID.
   
  .DESCRIPTION
	The Join-Federation command makes the StoreServ system a member
	of the Federation identified by the specified name and UUID.
   
  .EXAMPLE
	Join-Federation -FedName test -UUID 12345
	
  .EXAMPLE
	Join-Federation -Comment hello -UUID 12345
		
  .EXAMPLE
	Join-Federation -Comment hello -UUID 12345 -FedName test
		
  .EXAMPLE
	Join-Federation -Setkv 10 -UUID 12345 -FedName test
		
  .EXAMPLE
	Join-Federation -Setkvifnotset 20  -UUID 12345 -FedName test
 
  .PARAMETER Force
	If the StoreServ system is already a member of a Federation, the option
	forcefully removes the system from the current Federation and makes it a
	member of the new Federation identified by the specified name and UUID.
 
  .PARAMETER Comment
	Specifies any additional textual information.

  .PARAMETER Setkv
	Sets or resets key/value pairs on the federation.
	<key> is a string of alphanumeric characters.
	<value> is a string of characters other than "=", "," or ".".

  .PARAMETER Setkvifnotset
	Sets key/value pairs on the federation if not already set.
	A key/value pair is not reset on a federation if it already
	exists.  If a key already exists, it is not treated as an error
	and the value is left as it is.

  .PARAMETER UUID
	Specifies the UUID of the Federation to be joined.

  .PARAMETER FedName
	Specifies the name of the Federation to be joined.

  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
	NAME: Join-Federation  
	LASTEDIT: March 2020
	KEYWORDS: Join-Federation
   
	.Link
		http://www.hpe.com
 
 #Requires PS -Version 3.0
 #>
[CmdletBinding()]
	param(
	
		[Parameter(Position=1, Mandatory=$false)]
		[Switch]
		$Force ,
	
		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$UUID ,
		
		[Parameter(Position=2, Mandatory=$false)]
		[System.String]
		$FedName ,
		
		[Parameter(Position=3, Mandatory=$false)]
		[System.String]
		$Comment ,
		
		[Parameter(Position=4, Mandatory=$false)]
		[System.String]
		$Setkv ,
		
		[Parameter(Position=5, Mandatory=$false)]
		[System.String]
		$Setkvifnotset ,
				
		[Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)		
	
	Write-DebugLog "Start: In Join-Federation - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting Join-Federation since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Join-Federation since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli -SANConnection $SANConnection
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}
	if($FedName )
	{	
		if($UUID )
		{
			$Cmd = "joinfed "
			
			if($Force)
			{
				$Cmd+= " -force "						
			}
			if($Comment)
			{
				$Cmd+= " -comment $Comment"						
			}
			if($Setkv)
			{
				$Cmd+= " -setkv $Setkv"						
			}
			if($Setkvifnotset)
			{
				$Cmd+= " -setkvifnotset $Setkvifnotset"						
			}
				
			$Cmd += " $UUID $FedName "
			#write-host "Command = 	$Cmd"
			$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $Cmd
			write-debuglog "  Executing Join-Federation Command.--> " "INFO:" 
			return  "$Result"	
		}
		else
		{
			write-debugLog "UUID Not specified." "ERR:" 
			return "FAILURE : UUID Not specified."
		}
	}
	else
	{
		write-debugLog "Federation Name Not specified ." "ERR:" 
		return "FAILURE : Federation Name Not specified"
	}
} ##  End-of  Join-Federation 

######################################################################################################################
## FUNCTION New-Federation
######################################################################################################################
Function New-Federation
{
<#
  .SYNOPSIS
   The New-Federation command generates a UUID for the named Federation and makes the StoreServ system a member of that Federation.
   
  .DESCRIPTION
   The New-Federation command generates a UUID for the named Federation
    and makes the StoreServ system a member of that Federation.
   
  .EXAMPLE
	New-Federation -Fedname XYZ
	
  .EXAMPLE
	New-Federation –CommentString XYZ -Fedname XYZ
	
  .EXAMPLE
	New-Federation -Setkv TETS -Fedname XYZ

  .EXAMPLE
	New-Federation -Setkvifnotset TETS -Fedname XYZ
 
  .PARAMETER comment
	Specifies any additional textual information.

  .PARAMETER Setkv 
	Sets or resets key/value pairs on the federation.
	<key> is a string of alphanumeric characters.
	<value> is a string of characters other than "=", "," or ".".

  .PARAMETER Setkvifnotset
	Sets key/value pairs on the federation if not already set.
	A key/value pair is not reset on a federation if it already
	exists.
		
  .PARAMETER Fedname
	Specifies the name of the Federation to be created.
	The name must be between 1 and 31 characters in length
	and must contain only letters, digits, or punctuation
	characters '_', '-', or '.'
	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
    NAME: New-Federation  
    LASTEDIT: March 2020
    KEYWORDS: New-Federation 
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0
 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$Fedname ,
		
		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$Comment ,
		
		[Parameter(Position=2, Mandatory=$false)]
		[System.String]
		$Setkv ,
		
		[Parameter(Position=3, Mandatory=$false)]
		[System.String]
		$Setkvifnotset ,
		
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)		
	
	Write-DebugLog "Start: In New-Federation - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting New-Federation since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet New-Federation since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli -SANConnection $SANConnection
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}
	if($Fedname)
	{		
		$cmd = "createfed"
		
		if($Comment)
		{
			$cmd+= " -comment $Comment"						
		}
		if($Setkv)
		{
			$cmd+= " -setkv $Setkv"						
		}
		if($Setkvifnotset)
		{
			$cmd+= " -setkvifnotset $Setkvifnotset"						
		}
		
		$cmd += " $Fedname"
		$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $cmd
		write-debuglog "  Executing New-Federation Command.--> " "INFO:" 
		return  "$Result"				
	}
	else
	{
		write-debugLog "No Federation Name specified ." "ERR:" 
		return "FAILURE : No Federation name specified"
	}
} ##  End-of  New-Federation

######################################################################################################################
## FUNCTION Set-Federation
######################################################################################################################
Function Set-Federation
{
<#
  .SYNOPSIS
	 The Set-Federation command modifies name, comment, or key/value attributes of the Federation of which the StoreServ system is member.
   
  .DESCRIPTION 
	 The Set-Federation command modifies name, comment, or key/value attributes of the Federation of which the StoreServ system is member.
   
  .EXAMPLE
	Set-Federation -FedName test
	
  .EXAMPLE
	Set-Federation -Comment hello
		
  .EXAMPLE
	Set-Federation -ClrAllKeys
	
  .EXAMPLE
	Set-Federation -Setkv 1

  .PARAMETER Comment
		Specifies any additional textual information.

  .PARAMETER Setkv
	Sets or resets key/value pairs on the federation.
	<key> is a string of alphanumeric characters.
	<value> is a string of characters other than "=", "," or ".".

  .PARAMETER Setkvifnotset
	Sets key/value pairs on the federation if not already set.
	A key/value pair is not reset on a federation if it already
	exists.  If a key already exists, it is not treated as an error
	and the value is left as it is.

  .PARAMETER ClrallKeys
		Clears all key/value pairs on the federation.

  .PARAMETER ClrKey
	Clears key/value pairs, regardless of the value.
	If a specified key does not exist, this is not
	treated as an error.

  .PARAMETER ClrKV
	Clears key/value pairs only if the value matches the given key.
	Mismatches or keys that do not exist are not treated as errors.

  .PARAMETER IfKV
	Checks whether given key/value pairs exist. If not, any subsequent
	key/value options on the command line will be ignored for the
	federation.
			
  .PARAMETER FedName
	 Specifies the new name of the Federation.
		 
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
	NAME: Set-Federation  
	LASTEDIT: March 2020
	KEYWORDS: Set-Federation

	.Link
		http://www.hpe.com
 
 #Requires PS -Version 3.0
 #>
[CmdletBinding()]
	param(		
		
		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$FedName ,
		
		[Parameter(Position=2, Mandatory=$false)]
		[System.String]
		$Comment ,
		
		[Parameter(Position=3, Mandatory=$false)]
		[System.String]
		$Setkv ,	
		
		[Parameter(Position=4, Mandatory=$false)]
		[System.String]
		$Setkvifnotset ,
		
		[Parameter(Position=5, Mandatory=$false)]
		[switch]
		$ClrAllKeys ,
		
		[Parameter(Position=6, Mandatory=$false)]
		[System.String]
		$ClrKey ,
		
		[Parameter(Position=7, Mandatory=$false)]
		[System.String]
		$ClrKV ,
		
		[Parameter(Position=8, Mandatory=$false)]
		[System.String]
		$IfKV ,
				
		[Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)		
	
	Write-DebugLog "Start: In Set-Federation - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting Set-Federation since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Set-Federation since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli -SANConnection $SANConnection
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}		
	
	$cmd = "setfed"	

	if($FedName)
	{
		$cmd += " -name $FedName "	
	}
	if($Comment)
	{
		$cmd += " -comment $Comment "	
	}
	if($Setkv)
	{
		$cmd += " -setkv $Setkv "	
	}
	if($Setkvifnotset)
	{
		$cmd += " -setkvifnotset $Setkvifnotset "	
	}
	if($ClrAllKeys)
	{
		$cmd += "  -clrallkeys "	
	}
	if($ClrKey)
	{
		$cmd += " -clrkey $ClrKey "	
	}
	if($ClrKV)
	{
		$cmd += " -clrkv $ClrKV "	
	}
	if($IfKV)
	{
		$cmd += " -ifkv $IfKV "	
	}
	
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $cmd
	write-debuglog "  Executing Set-Federation Command.-->  " "INFO:" 
	if([string]::IsNullOrEmpty($Result))
	{
		return "Success : Set-Federation command executed successfully."
	}
	else
	{
		return $Result
	}
	
} ##  End-of  Set-Federation 


######################################################################################################################
## FUNCTION Remove-Federation
######################################################################################################################
Function Remove-Federation
{
<#
  .SYNOPSIS
	The Remove-Federation command removes the StoreServ system from Federation membership.
   
  .DESCRIPTION 
	The Remove-Federation command removes the StoreServ system from Federation membership.
   
  .EXAMPLE	
	Remove-Federation	
	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
	NAME: Remove-Federation  
	LASTEDIT: March 2020
	KEYWORDS: Remove-Federation
   
	.Link
		http://www.hpe.com
 
 #Requires PS -Version 3.0
 #>
[CmdletBinding()]
	param(	
		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)		
	
	Write-DebugLog "Start: In Remove-Federation - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting Remove-Federation since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Remove-Federation since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli -SANConnection $SANConnection
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}	
	$cmd = " removefed -f"
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $cmd
	write-debuglog "  Executing Remove-Federation Command.-->  " "INFO:" 
	return  "$Result"				
	
} ##  End-of  Remove-Federation 

######################################################################################################################
## FUNCTION Show-Federation
######################################################################################################################
Function Show-Federation
{
<#
  .SYNOPSIS 
	The Show-Federation command displays the name, UUID, and comment of the Federation of which the StoreServ system is member.
   
  .DESCRIPTION 
	The Show-Federation command displays the name, UUID, and comment
	of the Federation of which the StoreServ system is member.
   
  .EXAMPLE	
	Show-Federation	
	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-CLIConnection or New-PoshSshConnection
	
  .Notes
	NAME: Show-Federation  
	LASTEDIT: March 2020
	KEYWORDS: Show-Federation

	.Link
		http://www.hpe.com
 
 #Requires PS -Version 3.0
 #>
[CmdletBinding()]
	param(	
		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)		
	
	Write-DebugLog "Start: In Show-Federation - validating input values" $Debug 
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
				Write-DebugLog "Stop: Exiting Show-Federation since SAN connection object values are null/empty" $Debug
				return "Unable to execute the cmdlet Show-Federation since no active storage connection session exists. `nUse New-PoshSSHConnection or New-CLIConnection to start a new storage connection session."
			}
		}
	}
	$plinkresult = Test-PARCli -SANConnection $SANConnection
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}	
	$cmd = " showfed"
	$Result = Invoke-CLICommand -Connection $SANConnection -cmds  $cmd
	write-debuglog "  Executing Show-Federation Command.--> " "INFO:"
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
	if($Result -match "Name")
	{	
		return  " Success : Executing Show-Federation "		
	}
	else
	{
		return $Result		 		
	}		
	
} ##  End-of  Show-Federation 

Export-ModuleMember Join-Federation , New-Federation , Remove-Federation , Set-Federation , Show-Federation