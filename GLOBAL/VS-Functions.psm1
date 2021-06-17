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
##
##	File Name:		VS-Functions.psm1
##	Description: 	Common Module functions.
##		
##	Pre-requisites: Needs HPE 3PAR cli.exe for New-CLIConnection
##					Needs POSH SSH Module for New-PoshSshConnection
##					WSAPI uses HPE 3PAR CLI commands to start, configure, and modify the WSAPI server.
##					For more information about using the CLI, see:
##					• HPE 3PAR Command Line Interface Administrator Guide
##					• HPE 3PAR Command Line Interface Reference
##
##					Starting the WSAPI server    : The WSAPI server does not start automatically.
##					Using the CLI, enter startwsapi to manually start the WSAPI server.
## 					Configuring the WSAPI server: To configure WSAPI, enter setwsapi in the CLI.
##
##	Created:		June 2015
##	Last Modified:	July 2020
##
##	History:		v1.0 - Created
##					v2.0 - Added support for HP3PAR CLI
##                     v2.1 - Added support for POSH SSH Module
##					v2.2 - Added support for WSAPI
##                  v2.3 - Added Support for all CLI cmdlets
##                     v2.3.1 - Added support for primara array with wsapi
##                  v3.0 - Added Support for wsapi 1.7 
##                  v3.0 - Modularization
##                  v3.0.1 (07/30/2020) - Fixed the Show-RequestException function to show the actual error message
##	
#####################################################################################

# Generic connection object 

add-type @" 

public struct _Connection{
public string SessionId;
public string Name;
public string IPAddress;
public string SystemVersion;
public string Model;
public string Serial;
public string TotalCapacityMiB;
public string AllocatedCapacityMiB;
public string FreeCapacityMiB;     
public string UserName;
public string epwdFile;
public string CLIDir;
public string CLIType;
}

"@

add-type @" 

public struct _SANConnection{
public string SessionId;
public string Name;
public string IPAddress;
public string SystemVersion;
public string Model;
public string Serial;
public string TotalCapacityMiB;
public string AllocatedCapacityMiB;
public string FreeCapacityMiB;     
public string UserName;
public string epwdFile;
public string CLIDir;
public string CLIType;
}

"@ 

add-type @" 

public struct _TempSANConn{
public string SessionId;
public string Name;
public string IPAddress;
public string SystemVersion;
public string Model;
public string Serial;
public string TotalCapacityMiB;
public string AllocatedCapacityMiB;
public string FreeCapacityMiB;     
public string UserName;
public string epwdFile;
public string CLIDir;
public string CLIType;
}

"@ 

add-type @" 
public struct _vHost {
	public string Id;
	public string Name;
	public string Persona;
	public string Address;
	public string Port;
}

"@

add-type @" 
public struct _vLUN {
		public string Name;
		public string LunID;
		public string PresentTo;
		public string vvWWN;
}

"@

add-type @"
public struct _Version{
		public string ReleaseVersionName;
		public string Patches;
		public string CliServer;
		public string CliClient;
		public string SystemManager;
		public string Kernel;
		public string TPDKernelCode;
		
}
"@

add-type @" 
public struct _vHostSet {
		public string ID;
		public string Name;
		public string Members;		
}

"@

add-type @" 
public struct _vHostSetSummary {
		public string ID;
		public string Name;
		public string HOST_Cnt;
		public string VVOLSC;
		public string Flashcache;
		public string QoS;
		public string RC_host;
}

"@

add-type @" 

public struct WSAPIconObject{
public string Id;
public string Name;
public string SystemVersion;
public string Patches;
public string IPAddress;
public string Model;
public string SerialNumber;
public string TotalCapacityMiB;
public string AllocatedCapacityMiB;
public string FreeCapacityMiB;
public string Key;
}

"@

$global:LogInfo = $true
$global:DisplayInfo = $true

$global:SANConnection = $null #set in HPE3PARPSToolkit.psm1 
$global:WsapiConnection = $null
$global:ArrayType = $null
$global:ArrayName = $null
$global:ConnectionType = $null

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

if (!$global:VSVersion) {
	$global:VSVersion = "v3.0"
}

if (!$global:ConfigDir) {
	$global:ConfigDir = $null 
}
$Info = "INFO:"
$Debug = "DEBUG:"

############################################################################################################################################
## FUNCTION Invoke-CLICommand
############################################################################################################################################

Function Invoke-CLICommand {
	<#
  	.SYNOPSIS
		Execute a command against a device using HP3PAR CLI

	.DESCRIPTION
		Execute a command against a device using HP3PAR CLI
 
		
	.PARAMETER Connection
		Pointer to an object that contains passwordfile, HP3parCLI installed path and IP address
		
	.PARAMETER Cmds
		Command to be executed
  	
	.EXAMPLE		
		Invoke-CLICommand -Connection $global:SANConnection -Cmds "showsysmgr"
		The command queries a array to get the system information
		$global:SANConnection is created wiith the cmdlet New-CLIConnection or New-PoshSshConnection
			
  .Notes
    NAME:  Invoke-CLICommand
    LASTEDIT: June 2012
    KEYWORDS: Invoke-CLICommand
   
  .Link
     http://www.hpe.com
 
 #Requires HP3PAR CLI -Version 3.2.2
 #>
 
	[CmdletBinding()]
	Param(	
		[Parameter(Mandatory = $true)]
		$Connection,
			
		[Parameter(Mandatory = $true)]
		[string]$Cmds  

	)

	Write-DebugLog "Start: In Invoke-CLICommand - validating input values" $Debug 

	#check if connection object contents are null/empty
	if (!$Connection) {	
		$connection = [_Connection]$Connection	
		#check if connection object contents are null/empty
		$Validate1 = Test-CLIConnection $Connection
		if ($Validate1 -eq "Failed") {
			Write-DebugLog "Connection object is null/empty or the array address (FQDN/IP Address) or user credentials in the connection object are either null or incorrect.  Create a valid connection object using New-*Connection and pass it as parameter" "ERR:"
			Write-DebugLog "Stop: Exiting Invoke-CLICommand since connection object values are null/empty" "ERR:"
			return
		}
	}
	#check if cmd is null/empty
	if (!$Cmds) {
		Write-DebugLog "No command is passed to the Invoke-CLICommand." "ERR:"
		Write-DebugLog "Stop: Exiting Invoke-CLICommand since command parameter is null/empty null/empty" "ERR:"
		return
	}
	$clittype = $Connection.cliType
	
	if ($clittype -eq "3parcli") {
		#write-host "In Invoke-CLICommand -> entered in clitype $clittype"
		Invoke-CLI  -DeviceIPAddress  $Connection.IPAddress -epwdFile $Connection.epwdFile -CLIDir $Connection.CLIDir -cmd $Cmds
	}
	elseif ($clittype -eq "SshClient") {		
		$Result = Invoke-SSHCommand -Command $Cmds -SessionId $Connection.SessionId
		if ($Result.ExitStatus -eq 0) {
			return $Result.Output
		}
		else {
			$ErrorString = "Error :-" + $Result.Error + $Result.Output			    
			return $ErrorString
		}		
	}
	else {
		return "FAILURE : Invalid cliType option selected/chosen"
	}

}# End Invoke-CLICommand

############################################################################################################################################
## FUNCTION SET-DEBUGLOG
############################################################################################################################################

Function Set-DebugLog {
	<#
  .SYNOPSIS
    Enables creating debug logs.
  
  .DESCRIPTION
	Creates Log folder and debug log files in the directory structure where the current modules are running.
        
  .EXAMPLE
    Set-DebugLog -LogDebugInfo $true -Display $true
	Set-DEbugLog -LogDebugInfo $true -Display $false
    
  .PARAMETER LogDebugInfo 
    Specify the LogDebugInfo value to $true to see the debug log files to be created or $false if no debug log files are needed.
	
   .PARAMETER Display 
    Specify the value to $true. This will enable seeing messages on the PS console. This switch is set to true by default. Turn it off by setting it to $false. Look at examples.
	
  .Notes
    NAME:  Set-DebugLog
    LASTEDIT: 04/18/2012
    KEYWORDS: DebugLog
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0
 
 #>
 [CmdletBinding()]
	param(
		[Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
		[System.Boolean]
		$LogDebugInfo = $false,		
		[parameter(Position = 2, Mandatory = $true, ValueFromPipeline = $true)]
		[System.Boolean]
		$Display = $true
	)

	$global:LogInfo = $LogDebugInfo
	$global:DisplayInfo = $Display	
	Write-DebugLog "Exiting function call Set-DebugLog. The value of logging debug information is set to $global:LogInfo and the value of Display on console is $global:DisplayInfo" $Debug
}

############################################################################################################################################
## FUNCTION Invoke-CLI
############################################################################################################################################

Function Invoke-CLI {
	<#
  .SYNOPSIS
    This is private method not to be used. For internal use only.
  
  .DESCRIPTION
    Executes 3par cli command with the specified paramaeters to get data from the specified virtual Connect IP Address 
   
  .EXAMPLE
    Invoke-CLI -DeviceIPAddress "DeviceIPAddress" -CLIDir "Full Installed Path of cli.exe" -epwdFile "C:\loginencryptddetails.txt"  -cmd "show server $serverID"
    
   
  .PARAMETER DeviceIPAddress 
    Specify the IP address for Virtual Connect(VC) or Onboard Administrator(OA) or Storage or any other device
    
  .PARAMETER CLIDir 
    Specify the absolute path of HP3PAR CLI's cli.exe
    
   .PARAMETER epwdFIle 
    Specify the encrypted password file location
	
  .PARAMETER cmd 
    Specify the command to be run for Virtual Connect
        
  .Notes
    NAME:  Invoke-CLI    
    LASTEDIT: 04/04/2012
    KEYWORDS: 3parCLI
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0
 
 #>
 
 [CmdletBinding()]
	param(
		[Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
		[System.String]
		$DeviceIPAddress = $null,
		[Parameter(Position = 1)]
		[System.String]
		#$CLIDir="C:\Program Files (x86)\Hewlett-Packard\HP 3PAR CLI\bin",
		$CLIDir = "C:\Program Files (x86)\Hewlett Packard Enterprise\HPE 3PAR CLI\bin",
		[Parameter(Position = 2)]
		[System.String]
		$epwdFile = "C:\HP3PARepwdlogin.txt",
		[Parameter(Position = 3)]
		[System.String]
		$cmd = "show -help"
	)
	#write-host  "Password in Invoke-CLI = ",$password	
	Write-DebugLog "start:In function Invoke-CLI. Validating PUTTY path." $Debug
	if (Test-Path -Path $CLIDir) {
		$clifile = $CLIDir + "\cli.exe"
		if ( -not (Test-Path $clifile)) {
			
			Write-DebugLog "Stop: HP3PAR cli.exe file not found. Make sure the cli.exe file present in $CLIDir." "ERR:"			
			return "HP3PAR cli.exe file not found. Make sure the cli.exe file present in $CLIDir. "
		}
	}
	else {
		$SANCObj = $global:SANConnection
		$CLIDir = $SANCObj.CLIDir
	}
	if (-not (Test-Path -Path $CLIDir )) {
		Write-DebugLog "Stop: HP3PAR cli.exe not found. Make sure the HP3PAR CLI installed" "ERR:"			
		return "FAILURE : HP3PAR cli.exe not found. Make sure the HP3PAR CLI installed"
	}	
	Write-DebugLog "Running: Calling function Invoke-CLI. Calling Test Network with IP Address $DeviceIPAddress" $Debug	
	$Status = Test-Network $DeviceIPAddress

	if ($null -eq $Status) {
		Write-DebugLog "Stop: Calling function Invoke-CLI. Invalid IP Address"  "ERR:"
		Throw "Invalid IP Address"
		
	}
	if ($Status -eq "Failed") {
		Write-DebugLog "Stop:Calling function Invoke-CLI. Unable to ping the device with IP $DeviceIPAddress. Check the IP address and try again."  "ERR:"
		Throw "Unable to ping the device with IP $DeviceIPAddress. Check the IP address and try again."
	}
	
	Write-DebugLog "Running: Calling function Invoke-CLI. Check the Test Network with IP Address = $DeviceIPAddress. Invoking the HP3par cli...." $Debug
	
	try {

		#if(!($global:epwdFile)){
		#	Write-DebugLog "Stop:Please create encrpted password file first using New-CLIConnection"  "ERR:"
		#	return "`nFAILURE : Please create encrpted password file first using New-CLIConnection"
		#}	
		#write-host "encrypted password file is $epwdFile"
		$pwfile = $epwdFile
		$test = $cmd.split(" ")
		#$test = [regex]::split($cmd," ")
		$fcmd = $test[0].trim()
		$count = $test.count
		$fcmd1 = $test[1..$count]
		#$cmdtemp= [regex]::Replace($fcmd1,"\n"," ")
		#$cmd2 = $fcmd+".bat"
		#$cmdFinal = " $cmd2 -sys $DeviceIPAddress -pwf $pwfile $fcmd1"
		#write-host "Command is  : $cmdFinal"
		#Invoke-Expression $cmdFinal	
		$CLIDir = "$CLIDir\cli.exe"
		$path = "$CLIDir\$fcmd"
		#write-host "command is 1:  $cmd2  $fcmd1 -sys $DeviceIPAddress -pwf $pwfile"
		& $CLIDir -sys $DeviceIPAddress -pwf $pwfile $fcmd $fcmd1
		if (!($?	)) {
			return "FAILURE : FATAL ERROR"
		}	
	}
	catch {
		$msg = "Calling function Invoke-CLI -->Exception Occured. "
		$msg += $_.Exception.ToString()			
		Write-Exception $msg -error
		Throw $msg
	}	
	Write-DebugLog "End:Invoke-CLI called. If no errors reported on the console, the HP3par cli with the cmd = $cmd for user $username completed Successfully" $Debug
}

############################################################################################################################################
## FUNCTION TEST-NETWORK
############################################################################################################################################

Function Test-Network ([string]$IPAddress) {
	<#
  .SYNOPSIS
    Pings the given IP Adress.
  
  .DESCRIPTION
	Pings the IP address to test for connectivity.
        
  .EXAMPLE
    Test-Network -IPAddress 10.1.1.
	
   .PARAMETER IPAddress 
    Specify the IP address which needs to be pinged.
	   	
  .Notes
    NAME:  Test-Network 
	LASTEDITED: May 9 2012
    KEYWORDS: Test-Network
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0
 
 #>

	$Status = Test-IPFormat $IPAddress
	if ($Status -eq $null) {
		return $Status 
	}

	try {
		$Ping = new-object System.Net.NetworkInformation.Ping
		$result = $ping.Send($IPAddress)
		$Status = $result.Status.ToString()
	}
	catch [Exception] {
		## Server does not exist - skip it
		$Status = "Failed"
	}
	                
	return $Status
				
}

############################################################################################################################################
## FUNCTION TEST-IPFORMAT
############################################################################################################################################

Function Test-IPFormat {
	<#
  .SYNOPSIS
    Validate IP address format
  
  .DESCRIPTION
	Validates the given value is in a valid IP address format.
        
  .EXAMPLE
    Test-IPFormat -Address
	    
  .PARAMETER Address 
    Specify the Address which will be validated to check if its a valid IP format.
	
  .Notes
    NAME:  Test-IPFormat
    LASTEDIT: 05/09/2012
    KEYWORDS: Test-IPFormat
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0
 
 #>

	param([string]$Address = $(throw "Missing IP address parameter"))
	trap { $false; continue; }
	[bool][System.Net.IPAddress]::Parse($Address);
}


############################################################################################################################################
## FUNCTION Test-WSAPIConnection
############################################################################################################################################
Function Test-WSAPIConnection {
	[CmdletBinding()]
	Param(
  [Parameter(Position = 0, Mandatory = $false, ValueFromPipeline = $true)]
  $WsapiConnection = $global:WsapiConnection
	)
	Write-DebugLog "Request: Test-WSAPIConnection to Test if the session key exists." $Debug  
	Write-DebugLog "Running: Validate the session key" $Debug  
  
	$Validate = "Success"
	
	if (($null -eq $WsapiConnection) -or (-not ($WsapiConnection.IPAddress)) -or (-not ($WsapiConnection.Key))) {
		Write-DebugLog "Stop: No active WSAPI connection to an HPE Alletra 9000 or Primera or 3PAR storage system or the current session key is expired. Use New-WSAPIConnection cmdlet to connect back."
      
		Write-Host
		Write-Host "Stop: No active WSAPI connection to an HPE Alletra 9000 or Primera or 3PAR storage system or the current session key is expired. Use New-WSAPIConnection cmdlet to connect back." -foreground yellow
		Write-Host
	  
		throw 
	}
	else {
		Write-DebugLog " End: Connected" $Info
	}
	Write-DebugLog "End: Test-WSAPIConnection" $Debug  
}

#END Test-WSAPIConnection

############################################################################################################################################
## FUNCTION Invoke-WSAPI
############################################################################################################################################
function Invoke-WSAPI {
	[CmdletBinding()]
	Param (
		[parameter(Position = 0, Mandatory = $true, HelpMessage = "Enter the resource URI (ex. /volumes)")]
		[ValidateScript( { if ($_.startswith('/')) { $true } else { throw "-URI must begin with a '/' (eg. /volumes) in its value. Correct the value and try again." } })]
		[string]
		$uri,
		
		[parameter(Position = 1, Mandatory = $true, HelpMessage = "Enter request type (GET POST DELETE)")]
		[string]
		$type,
		
		[parameter(Position = 2, Mandatory = $false, HelpMessage = "Body of the message")]
		[array]
		$body,
		
		[Parameter(Position = 0, Mandatory = $false, ValueFromPipeline = $true)]
		$WsapiConnection = $global:WsapiConnection
	)
    
	Write-DebugLog "Request: Request Invoke-WSAPI URL : $uri TYPE : $type " $Debug  
	
	$ip = $WsapiConnection.IPAddress
	$key = $WsapiConnection.Key
	$arrtyp = $global:ArrayType
	
	if ($arrtyp.ToLower() -eq "3par") {
		$APIurl = 'https://' + $ip + ':8080/api/v1' 	
	}
	Elseif (($arrtyp.ToLower() -eq "primera") -or ($arrtyp.ToLower() -eq "alletra9000")) {
		$APIurl = 'https://' + $ip + ':443/api/v1'	
	}
	else {
		return "Array type is Null."
	}
	
	$url = $APIurl + $uri
	
	#Construct header
	Write-DebugLog "Running: Constructing header." $Debug
	$headers = @{}
	$headers["Accept"] = "application/json"
	$headers["Accept-Language"] = "en"
	$headers["Content-Type"] = "application/json"
	$headers["X-HP3PAR-WSAPI-SessionKey"] = $key

	$data = $null

	#write-host "url = $url"
	
	# Request
	If ($type -eq 'GET') {
		Try {
			Write-DebugLog "Request: Invoke-WebRequest for Data, Request Type : $type" $Debug
          
			if ($PSEdition -eq 'Core') {    
				$data = Invoke-WebRequest -Uri "$url" -Headers $headers -Method $type -UseBasicParsing -SkipCertificateCheck
			} 
			else {    
				$data = Invoke-WebRequest -Uri "$url" -Headers $headers -Method $type -UseBasicParsing 
			}
			return $data
		}
		Catch {
			Write-DebugLog "Stop: Exception Occurs" $Debug
			Show-RequestException -Exception $_
			return
		}
	}
	If (($type -eq 'POST') -or ($type -eq 'PUT')) {
		Try {
		
			Write-DebugLog "Request: Invoke-WebRequest for Data, Request Type : $type" $Debug
			$json = $body | ConvertTo-Json  -Compress -Depth 10	
		
			#write-host "Invoke json = $json"		       
			if ($PSEdition -eq 'Core') {    
				$data = Invoke-WebRequest -Uri "$url" -Body $json -Headers $headers -Method $type -UseBasicParsing -SkipCertificateCheck
			} 
			else {    
				$data = Invoke-WebRequest -Uri "$url" -Body $json -Headers $headers -Method $type -UseBasicParsing 
			}
			return $data
		}
		Catch {
			Write-DebugLog "Stop: Exception Occurs" $Debug
			Show-RequestException -Exception $_
			return
		}
	}
	If ($type -eq 'DELETE') {
		Try {
			Write-DebugLog "Request: Invoke-WebRequest for Data, Request Type : $type" $Debug
        
			if ($PSEdition -eq 'Core') {    
				$data = Invoke-WebRequest -Uri "$url" -Headers $headers -Method $type -UseBasicParsing -SkipCertificateCheck
			} 
			else {    
				$data = Invoke-WebRequest -Uri "$url" -Headers $headers -Method $type -UseBasicParsing 
			}
			return $data
		}
		Catch {
			Write-DebugLog "Stop: Exception Occurs" $Debug
			Show-RequestException -Exception $_
			return
		}
	}
	Write-DebugLog "End: Invoke-WSAPI" $Debug
}
#END Invoke-WSAPI

############################################################################################################################################
## FUNCTION Format-Result
############################################################################################################################################
function Format-Result {
	[CmdletBinding()]
	Param (
		[parameter(Mandatory = $true)]
		$dataPS,
		[parameter(Mandatory = $true)]
		[string]$TypeName
	)

	Begin { $AlldataPS = @() }

	Process {
		# Add custom type to the resulting oject for formating purpose	 
		Foreach ($data in $dataPS) {	  
			If ($data) {		  
				$data.PSObject.TypeNames.Insert(0, $TypeName)
			}		
			$AlldataPS += $data
		}
	}

	End { return $AlldataPS }
}
#END Format-Result

############################################################################################################################################
## FUNCTION Show-RequestException 
############################################################################################################################################
Function Show-RequestException {
	[CmdletBinding()]
	Param(
		[parameter(Mandatory = $true)]
		$Exception
	)

	#Exception catch when there's a connectivity problem with the array
	If ($Exception.Exception.InnerException) {
		Write-Host "Please verify the connectivity with the array. Retry with the parameter -Verbose for more informations" -foreground yellow
		Write-Host
		Write-Host "Status: $($Exception.Exception.Status)" -foreground yellow
		Write-Host "Error code: $($Exception.Exception.Response.StatusCode.value__)" -foreground yellow
		Write-Host "Message: $($Exception.Exception.InnerException.Message)" -foreground yellow
		Write-Host
	
		Write-DebugLog "Stop: Please verify the connectivity with the array. Retry with the parameter -Verbose for more informations." $Debug
		Write-DebugLog "Stop: Status: $($Exception.Exception.Status)" $Debug
		Write-DebugLog "Stop: Error code: $($Exception.Exception.Response.StatusCode.value__)" $Debug
		Write-DebugLog "Stop: Message: $($Exception.Exception.InnerException.Message)" $Debug

		Return $Exception.Exception.Status
	}

	#Exception catch when the rest request return an error
	If ($_.Exception.Response) {		
		$result = ConvertFrom-Json -InputObject $Exception.ErrorDetails.Message
		
		Write-Host "The array sends an error message: $($result.desc)." -foreground yellow 
		Write-Host
		Write-Host "Status: $($Exception.Exception.Status)" -foreground yellow
		Write-Host "Error code: $($result.code)" -foreground yellow
		Write-Host "HTTP Error code: $($Exception.Exception.Response.StatusCode.value__)" -foreground yellow
		Write-Host "Message: $($result.desc)" -foreground yellow
		Write-Host
	
		Write-DebugLog "Stop:The array sends an error message: $($Exception.Exception.Message)." $Debug
		Write-DebugLog "Stop: Status: $($Exception.Exception.Status)" $Debug
		Write-DebugLog "Stop: Error code: $($result.code)" $Debug
		Write-DebugLog "Stop: HTTP Error code: $($Exception.Exception.Response.StatusCode.value__)" $Debug
		Write-DebugLog "Stop: Message: $($result.desc)" $Debug

		Return $result.code
	}
	Write-DebugLog "End: Show-RequestException" $Debug
}
#END Show-RequestException 

############################################################################################################################################
## FUNCTION TEST-FILEPATH
############################################################################################################################################

Function Test-FilePath ([String[]]$ConfigFiles) {
	<#
  .SYNOPSIS
    Validate an array of file paths. For Internal Use only.
  
  .DESCRIPTION
	Validates if a path specified in the array is valid.
        
  .EXAMPLE
    Test-FilePath -ConfigFiles
	    
  .PARAMETER -ConfigFiles 
    Specify an array of config files which need to be validated.
	
  .Notes
    NAME:  Test-FilePath
    LASTEDIT: 05/30/2012
    KEYWORDS: Test-FilePath
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0
 
 #>
 
	Write-DebugLog "Start: Entering function Test-FilePath." $Debug
	$Validate = @()	
	if (-not ($global:ConfigDir)) {
		Write-DebugLog "STOP: Configuration Directory path is not set. Run scripts Init-PS-Session.ps1 OR import module VS-Functions.psm1 and run cmdlet Set-ConfigDirectory" "ERR:"
		$Validate = @("Configuration Directory path is not set. Run scripts Init-PS-Session.ps1 OR import module VS-Functions.psm1 and run cmdlet Set-ConfigDirectory.")
		return $Validate
	}
	foreach ($argConfigFile in $ConfigFiles) {			
		if (-not (Test-Path -Path $argConfigFile )) {
				
			$FullPathConfigFile = $global:ConfigDir + $argConfigFile
			if (-not (Test-Path -Path $FullPathConfigFile)) {
				$Validate = $Validate + @(, "Path $FullPathConfigFile not found.")					
			}				
		}
	}	
	
	Write-DebugLog "End: Leaving function Test-FilePath." $Debug
	return $Validate
}

Function Test-PARCLi {
	<#
  .SYNOPSIS
    Test-PARCli object path

  .EXAMPLE
    Test-PARCli t
	
  .Notes
    NAME:  Test-PARCli
    LASTEDIT: 06/16/2015
    KEYWORDS: Test-PARCli
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0
 
 #> 
 [CmdletBinding()]
	param 
	(
		[Parameter(Position = 0, Mandatory = $false, ValueFromPipeline = $true)]
		$SANConnection = $global:SANConnection 
	)
	$SANCOB = $SANConnection 
	$clittype = $SANCOB.CliType
	Write-DebugLog "Start : in Test-PARCli function " "INFO:"
	if ($clittype -eq "3parcli") {
		Test-PARCliTest -SANConnection $SANConnection
	}
	elseif ($clittype -eq "SshClient") {
		Test-SSHSession -SANConnection $SANConnection
	}
	else {
		return "FAILURE : Invalid cli type"
	}	

}

Function Test-SSHSession {
	<#
  .SYNOPSIS
    Test-SSHSession   
	
  .PARAMETER pathFolder
    Test-SSHSession

  .EXAMPLE
    Test-SSHSession -SANConnection $SANConnection
	
  .Notes
    NAME:  Test-SSHSession
    LASTEDIT: 14/03/2017
    KEYWORDS: Test-SSHSession
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0
 
 #> 
 [CmdletBinding()]
	param 
	(	
		[Parameter(Position = 1, Mandatory = $false, ValueFromPipeline = $true)]
		$SANConnection = $global:SANConnection 
	)
	
	$Result = Get-SSHSession | fl
	
	if ($Result.count -gt 1) {
	}
	else {
		return "`nFAILURE : FATAL ERROR : Please check your connection and try again"
	}
	
}

Function Test-PARCliTest {
	<#
  .SYNOPSIS
    Test-PARCli pathFolder
  
	
  .PARAMETER pathFolder
    Specify the names of the HP3par cli path

  .EXAMPLE
    Test-PARCli path -pathFolder c:\test
	
  .Notes
    NAME:  Test-PARCliTest
    LASTEDIT: 06/16/2015
    KEYWORDS: Test-PARCliTest
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0
 
 #> 
 [CmdletBinding()]
	param 
	(
		[Parameter(Position = 0, Mandatory = $false)]
		[System.String]
		#$pathFolder = "C:\Program Files (x86)\Hewlett-Packard\HP 3PAR CLI\bin\",
		$pathFolder = "C:\Program Files (x86)\Hewlett Packard Enterprise\HPE 3PAR CLI\bin",
		[Parameter(Position = 1, Mandatory = $false, ValueFromPipeline = $true)]
		$SANConnection = $global:SANConnection 
	)
	$SANCOB = $SANConnection 
	$DeviceIPAddress = $SANCOB.IPAddress
	Write-DebugLog "Start : in Test-PARCli function " "INFO:"
	#Write-host "Start : in Test-PARCli function "
	$CLIDir = $pathFolder
	if (Test-Path -Path $CLIDir) {
		$clitestfile = $CLIDir + "\cli.exe"
		if ( -not (Test-Path $clitestfile)) {					
			return "FAILURE : HP3PAR cli.exe file was not found. Make sure you have cli.exe file under $CLIDir "
		}
		$pwfile = $SANCOB.epwdFile
		$cmd2 = "help.bat"
		#$cmdFinal = "$cmd2 -sys $DeviceIPAddress -pwf $pwfile"
		& $cmd2 -sys $DeviceIPAddress -pwf $pwfile
		#Invoke-Expression $cmdFinal
		if (!($?)) {
			return "`nFAILURE : FATAL ERROR"
		}
	}
	else {
		$SANCObj = $SANConnection
		$CLIDir = $SANCObj.CLIDir	
		$clitestfile = $CLIDir + "\cli.exe"
		if (-not (Test-Path $clitestfile )) {					
			return "FAILURE : HP3PAR cli.exe was not found. Make sure you have cli.exe file under $CLIDir "
		}
		$pwfile = $SANCObj.epwdFile
		$cmd2 = "help.bat"
		#$cmdFinal = "$cmd2 -sys $DeviceIPAddress -pwf $pwfile"
		#Invoke-Expression $cmdFinal
		& $cmd2 -sys $DeviceIPAddress -pwf $pwfile
		if (!($?)) {
			return "`nFAILURE : FATAL ERROR"
		}
	}
	Write-DebugLog "Stop : in Test-PARCli function " "INFO:"
}

############################################################################################################################################
## FUNCTION Test-CLIConnection
############################################################################################################################################

Function Test-CLIConnection ($SANConnection) {
	<#
  .SYNOPSIS
    Validate CLI connection object. For Internal Use only.
  
  .DESCRIPTION
	Validates if CLI connection object for VC and OA are null/empty
        
  .EXAMPLE
    Test-CLIConnection -SANConnection
	    
  .PARAMETER -SANConnection 
    Specify the VC or OA connection object. Ideally VC or Oa connection object is obtained by executing New-VCConnection or New-OAConnection.
	
  .Notes
    NAME:  Test-CLIConnection
    LASTEDIT: 05/09/2012
    KEYWORDS: Test-CLIConnection
   
  .Link
     http://www.hpe.com
 
 #Requires PS -Version 3.0
 
 #>
	$Validate = "Success"
	if (($SANConnection -eq $null) -or (-not ($SANConnection.AdminName)) -or (-not ($SANConnection.Password)) -or (-not ($SANConnection.IPAddress)) -or (-not ($SANConnection.SSHDir))) {
		#Write-DebugLog "Connection object is null/empty or username, password,IP address are null/empty. Create a valid connection object and retry" "ERR:"
		$Validate = "Failed"		
	}
	return $Validate
}

Export-ModuleMember Test-IPFormat , Test-WSAPIConnection , Invoke-WSAPI , Format-Result , Show-RequestException , Test-SSHSession , Set-DebugLog , Test-Network , Invoke-CLI , Invoke-CLICommand , Test-FilePath , Test-PARCli , Test-PARCliTest, Test-CLIConnection


# SIG # Begin signature block
# MIInTQYJKoZIhvcNAQcCoIInPjCCJzoCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBvwonzMQEI+hFU
# rPR+31FheuWLWxk0xHC2zb/SmBqRG6CCFikwggVMMIIDNKADAgECAhMzAAAANdjV
# WVsGcUErAAAAAAA1MA0GCSqGSIb3DQEBBQUAMH8xCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xKTAnBgNVBAMTIE1pY3Jvc29mdCBDb2RlIFZlcmlm
# aWNhdGlvbiBSb290MB4XDTEzMDgxNTIwMjYzMFoXDTIzMDgxNTIwMzYzMFowbzEL
# MAkGA1UEBhMCU0UxFDASBgNVBAoTC0FkZFRydXN0IEFCMSYwJAYDVQQLEx1BZGRU
# cnVzdCBFeHRlcm5hbCBUVFAgTmV0d29yazEiMCAGA1UEAxMZQWRkVHJ1c3QgRXh0
# ZXJuYWwgQ0EgUm9vdDCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBALf3
# GjPm8gAELTngTlvtH7xsD821+iO2zt6bETOXpClMfZOfvUq8k+0DGuOPz+VtUFrW
# lymUWoCwSXrbLpX9uMq/NzgtHj6RQa1wVsfwTz/oMp50ysiQVOnGXw94nZpAPA6s
# YapeFI+eh6FqUNzXmk6vBbOmcZSccbNQYArHE504B4YCqOmoaSYYkKtMsE8jqzpP
# hNjfzp/haW+710LXa0Tkx63ubUFfclpxCDezeWWkWaCUN/cALw3CknLa0Dhy2xSo
# RcRdKn23tNbE7qzNE0S3ySvdQwAl+mG5aWpYIxG3pzOPVnVZ9c0p10a3CitlttNC
# bxWyuHv77+ldU9U0WicCAwEAAaOB0DCBzTATBgNVHSUEDDAKBggrBgEFBQcDAzAS
# BgNVHRMBAf8ECDAGAQH/AgECMB0GA1UdDgQWBBStvZh6NLQm9/rEJlTvA73gJMtU
# GjALBgNVHQ8EBAMCAYYwHwYDVR0jBBgwFoAUYvsKIVt/Q24R2glUUGv10pZx8Z4w
# VQYDVR0fBE4wTDBKoEigRoZEaHR0cDovL2NybC5taWNyb3NvZnQuY29tL3BraS9j
# cmwvcHJvZHVjdHMvTWljcm9zb2Z0Q29kZVZlcmlmUm9vdC5jcmwwDQYJKoZIhvcN
# AQEFBQADggIBADYrovLhMx/kk/fyaYXGZA7Jm2Mv5HA3mP2U7HvP+KFCRvntak6N
# NGk2BVV6HrutjJlClgbpJagmhL7BvxapfKpbBLf90cD0Ar4o7fV3x5v+OvbowXvT
# gqv6FE7PK8/l1bVIQLGjj4OLrSslU6umNM7yQ/dPLOndHk5atrroOxCZJAC8UP14
# 9uUjqImUk/e3QTA3Sle35kTZyd+ZBapE/HSvgmTMB8sBtgnDLuPoMqe0n0F4x6GE
# NlRi8uwVCsjq0IT48eBr9FYSX5Xg/N23dpP+KUol6QQA8bQRDsmEntsXffUepY42
# KRk6bWxGS9ercCQojQWj2dUk8vig0TyCOdSogg5pOoEJ/Abwx1kzhDaTBkGRIywi
# pacBK1C0KK7bRrBZG4azm4foSU45C20U30wDMB4fX3Su9VtZA1PsmBbg0GI1dRtI
# uH0T5XpIuHdSpAeYJTsGm3pOam9Ehk8UTyd5Jz1Qc0FMnEE+3SkMc7HH+x92DBdl
# BOvSUBCSQUns5AZ9NhVEb4m/aX35TUDBOpi2oH4x0rWuyvtT1T9Qhs1ekzttXXya
# Pz/3qSVYhN0RSQCix8ieN913jm1xi+BbgTRdVLrM9ZNHiG3n71viKOSAG0DkDyrR
# fyMVZVqsmZRDP0ZVJtbE+oiV4pGaoy0Lhd6sjOD5Z3CfcXkCMfdhoinEMIIFYTCC
# BEmgAwIBAgIQJl6ULMWyOufq8fQJzRxR/TANBgkqhkiG9w0BAQsFADB8MQswCQYD
# VQQGEwJHQjEbMBkGA1UECBMSR3JlYXRlciBNYW5jaGVzdGVyMRAwDgYDVQQHEwdT
# YWxmb3JkMRgwFgYDVQQKEw9TZWN0aWdvIExpbWl0ZWQxJDAiBgNVBAMTG1NlY3Rp
# Z28gUlNBIENvZGUgU2lnbmluZyBDQTAeFw0xOTA0MjYwMDAwMDBaFw0yMDA0MjUy
# MzU5NTlaMIHSMQswCQYDVQQGEwJVUzEOMAwGA1UEEQwFOTQzMDQxCzAJBgNVBAgM
# AkNBMRIwEAYDVQQHDAlQYWxvIEFsdG8xHDAaBgNVBAkMEzMwMDAgSGFub3ZlciBT
# dHJlZXQxKzApBgNVBAoMIkhld2xldHQgUGFja2FyZCBFbnRlcnByaXNlIENvbXBh
# bnkxGjAYBgNVBAsMEUhQIEN5YmVyIFNlY3VyaXR5MSswKQYDVQQDDCJIZXdsZXR0
# IFBhY2thcmQgRW50ZXJwcmlzZSBDb21wYW55MIIBIjANBgkqhkiG9w0BAQEFAAOC
# AQ8AMIIBCgKCAQEAvxp2KuPOGop6ObVmKZ17bhP+oPpH4ZdDHwiaCP2KKn1m13Wd
# 5YuMcYOmF6xxb7rK8vcFRRf72MWwPvI05bKGZ1hKilh4UQZ8IpDZ6PlVF6cOFRKv
# PVt3r1nzA3fpEptdNmK54HktcfQIlTBNa0gBAzuWD5nwXckfwTujfa9bxT3ZLfNV
# V6rA9oMmsIUCF5rKQBnlwYGP5ceFFW0KBfdDNOZSLI5/96AbWO7Kh7+lfFjYYYyp
# j9a/+BdgxeLAUAc3wwtspxPui0FPDpmFAFs3Mj/eLSBjlBwd+Gb1OzQvgE+fagoy
# Kh6MB8xO4dueEdwJBEyNqNQIatE+klCMAS3L/QIDAQABo4IBhjCCAYIwHwYDVR0j
# BBgwFoAUDuE6qFM6MdWKvsG7rWcaA4WtNA4wHQYDVR0OBBYEFPqXMYWJeByh5r0Z
# 7Cfmb6MYpSExMA4GA1UdDwEB/wQEAwIHgDAMBgNVHRMBAf8EAjAAMBMGA1UdJQQM
# MAoGCCsGAQUFBwMDMBEGCWCGSAGG+EIBAQQEAwIEEDBABgNVHSAEOTA3MDUGDCsG
# AQQBsjEBAgEDAjAlMCMGCCsGAQUFBwIBFhdodHRwczovL3NlY3RpZ28uY29tL0NQ
# UzBDBgNVHR8EPDA6MDigNqA0hjJodHRwOi8vY3JsLnNlY3RpZ28uY29tL1NlY3Rp
# Z29SU0FDb2RlU2lnbmluZ0NBLmNybDBzBggrBgEFBQcBAQRnMGUwPgYIKwYBBQUH
# MAKGMmh0dHA6Ly9jcnQuc2VjdGlnby5jb20vU2VjdGlnb1JTQUNvZGVTaWduaW5n
# Q0EuY3J0MCMGCCsGAQUFBzABhhdodHRwOi8vb2NzcC5zZWN0aWdvLmNvbTANBgkq
# hkiG9w0BAQsFAAOCAQEAfggdDqfErm1J/WVBlc2H1wSKATk/d/vgypGsrFU1uOqv
# 3qJrz9X51HMMh/7zn5J6pKonnj5Gn9unqYPbBjyEZTYPDPfmFZNC9zZC+vhxO0mV
# PCiV9wd1f1sJjF4GBcNi/eUbCSXsXeiDWxRs1ISFj5pDp+sefNEpyMx6ryObuZ/G
# 0m3TsvMwgFy/oRKB7rcL8tACN+K4lotiuFDYjy0+vB7VuorM0fmvs9BIAnatbCz7
# begsrw0tRhw9A3tB3fEtgEZAOHsK1vg+CqFnB1vbNX3XLHw4znn7+fYdjlL1ZRo+
# zoGO6MGPIrILnlQnsldwpwYYd619q1aVkMZ8GycvojCCBXcwggRfoAMCAQICEBPq
# KHBb9OztDDZjCYBhQzYwDQYJKoZIhvcNAQEMBQAwbzELMAkGA1UEBhMCU0UxFDAS
# BgNVBAoTC0FkZFRydXN0IEFCMSYwJAYDVQQLEx1BZGRUcnVzdCBFeHRlcm5hbCBU
# VFAgTmV0d29yazEiMCAGA1UEAxMZQWRkVHJ1c3QgRXh0ZXJuYWwgQ0EgUm9vdDAe
# Fw0wMDA1MzAxMDQ4MzhaFw0yMDA1MzAxMDQ4MzhaMIGIMQswCQYDVQQGEwJVUzET
# MBEGA1UECBMKTmV3IEplcnNleTEUMBIGA1UEBxMLSmVyc2V5IENpdHkxHjAcBgNV
# BAoTFVRoZSBVU0VSVFJVU1QgTmV0d29yazEuMCwGA1UEAxMlVVNFUlRydXN0IFJT
# QSBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eTCCAiIwDQYJKoZIhvcNAQEBBQADggIP
# ADCCAgoCggIBAIASZRc2DsPbCLPQrFcNdu3NJ9NMrVCDYeKqIE0JLWQJ3M6Jn8w9
# qez2z8Hc8dOx1ns3KBErR9o5xrw6GbRfpr19naNjQrZ28qk7K5H44m/Q7BYgkAk+
# 4uh0yRi0kdRiZNt/owbxiBhqkCI8vP4T8IcUe/bkH47U5FHGEWdGCFHLhhRUP7wz
# /n5snP8WnRi9UY41pqdmyHJn2yFmsdSbeAPAUDrozPDcvJ5M/q8FljUfV1q3/875
# PbcstvZU3cjnEjpNrkyKt1yatLcgPcp/IjSufjtoZgFE5wFORlObM2D3lL5TN5Bz
# Q/Myw1Pv26r+dE5px2uMYJPexMcM3+EyrsyTO1F4lWeL7j1W/gzQaQ8bD/MlJmsz
# bfduR/pzQ+V+DqVmsSl8MoRjVYnEDcGTVDAZE6zTfTen6106bDVc20HXEtqpSQvf
# 2ICKCZNijrVmzyWIzYS4sT+kOQ/ZAp7rEkyVfPNrBaleFoPMuGfi6BOdzFuC00yz
# 7Vv/3uVzrCM7LQC/NVV0CUnYSVgaf5I25lGSDvMmfRxNF7zJ7EMm0L9BX0CpRET0
# medXh55QH1dUqD79dGMvsVBlCeZYQi5DGky08CVHWfoEHpPUJkZKUIGy3r54t/xn
# FeHJV4QeD2PW6WK61l9VLupcxigIBCU5uA4rqfJMlxwHPw1S9e3vL4IPAgMBAAGj
# gfQwgfEwHwYDVR0jBBgwFoAUrb2YejS0Jvf6xCZU7wO94CTLVBowHQYDVR0OBBYE
# FFN5v1qqK0rPVIDh2JvAnfKyA2bLMA4GA1UdDwEB/wQEAwIBhjAPBgNVHRMBAf8E
# BTADAQH/MBEGA1UdIAQKMAgwBgYEVR0gADBEBgNVHR8EPTA7MDmgN6A1hjNodHRw
# Oi8vY3JsLnVzZXJ0cnVzdC5jb20vQWRkVHJ1c3RFeHRlcm5hbENBUm9vdC5jcmww
# NQYIKwYBBQUHAQEEKTAnMCUGCCsGAQUFBzABhhlodHRwOi8vb2NzcC51c2VydHJ1
# c3QuY29tMA0GCSqGSIb3DQEBDAUAA4IBAQCTZfY3g5UPXsOCHB/Wd+c8isCqCfDp
# Cybx4MJqdaHHecm5UmDIKRIO8K0D1gnEdt/lpoGVp0bagleplZLFto8DImwzd8F7
# MhduB85aFEE6BSQb9hQGO6glJA67zCp13blwQT980GM2IQcfRv9gpJHhZ7zeH34Z
# FMljZ5HqZwdrtI+LwG5DfcOhgGyyHrxThX3ckKGkvC3vRnJXNQW/u0a7bm03mbb/
# I5KRxm5A+I8pVupf1V8UU6zwT2Hq9yLMp1YL4rg0HybZexkFaD+6PNQ4BqLT5o8O
# 47RxbUBCxYS0QJUr9GWgSHn2HYFjlp1PdeD4fOSOqdHyrYqzjMchzcLvMIIF9TCC
# A92gAwIBAgIQHaJIMG+bJhjQguCWfTPTajANBgkqhkiG9w0BAQwFADCBiDELMAkG
# A1UEBhMCVVMxEzARBgNVBAgTCk5ldyBKZXJzZXkxFDASBgNVBAcTC0plcnNleSBD
# aXR5MR4wHAYDVQQKExVUaGUgVVNFUlRSVVNUIE5ldHdvcmsxLjAsBgNVBAMTJVVT
# RVJUcnVzdCBSU0EgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkwHhcNMTgxMTAyMDAw
# MDAwWhcNMzAxMjMxMjM1OTU5WjB8MQswCQYDVQQGEwJHQjEbMBkGA1UECBMSR3Jl
# YXRlciBNYW5jaGVzdGVyMRAwDgYDVQQHEwdTYWxmb3JkMRgwFgYDVQQKEw9TZWN0
# aWdvIExpbWl0ZWQxJDAiBgNVBAMTG1NlY3RpZ28gUlNBIENvZGUgU2lnbmluZyBD
# QTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAIYijTKFehifSfCWL2MI
# Hi3cfJ8Uz+MmtiVmKUCGVEZ0MWLFEO2yhyemmcuVMMBW9aR1xqkOUGKlUZEQauBL
# Yq798PgYrKf/7i4zIPoMGYmobHutAMNhodxpZW0fbieW15dRhqb0J+V8aouVHltg
# 1X7XFpKcAC9o95ftanK+ODtj3o+/bkxBXRIgCFnoOc2P0tbPBrRXBbZOoT5Xax+Y
# vMRi1hsLjcdmG0qfnYHEckC14l/vC0X/o84Xpi1VsLewvFRqnbyNVlPG8Lp5UEks
# 9wO5/i9lNfIi6iwHr0bZ+UYc3Ix8cSjz/qfGFN1VkW6KEQ3fBiSVfQ+noXw62oY1
# YdMCAwEAAaOCAWQwggFgMB8GA1UdIwQYMBaAFFN5v1qqK0rPVIDh2JvAnfKyA2bL
# MB0GA1UdDgQWBBQO4TqoUzox1Yq+wbutZxoDha00DjAOBgNVHQ8BAf8EBAMCAYYw
# EgYDVR0TAQH/BAgwBgEB/wIBADAdBgNVHSUEFjAUBggrBgEFBQcDAwYIKwYBBQUH
# AwgwEQYDVR0gBAowCDAGBgRVHSAAMFAGA1UdHwRJMEcwRaBDoEGGP2h0dHA6Ly9j
# cmwudXNlcnRydXN0LmNvbS9VU0VSVHJ1c3RSU0FDZXJ0aWZpY2F0aW9uQXV0aG9y
# aXR5LmNybDB2BggrBgEFBQcBAQRqMGgwPwYIKwYBBQUHMAKGM2h0dHA6Ly9jcnQu
# dXNlcnRydXN0LmNvbS9VU0VSVHJ1c3RSU0FBZGRUcnVzdENBLmNydDAlBggrBgEF
# BQcwAYYZaHR0cDovL29jc3AudXNlcnRydXN0LmNvbTANBgkqhkiG9w0BAQwFAAOC
# AgEATWNQ7Uc0SmGk295qKoyb8QAAHh1iezrXMsL2s+Bjs/thAIiaG20QBwRPvrjq
# iXgi6w9G7PNGXkBGiRL0C3danCpBOvzW9Ovn9xWVM8Ohgyi33i/klPeFM4MtSkBI
# v5rCT0qxjyT0s4E307dksKYjalloUkJf/wTr4XRleQj1qZPea3FAmZa6ePG5yOLD
# CBaxq2NayBWAbXReSnV+pbjDbLXP30p5h1zHQE1jNfYw08+1Cg4LBH+gS667o6XQ
# hACTPlNdNKUANWlsvp8gJRANGftQkGG+OY96jk32nw4e/gdREmaDJhlIlc5KycF/
# 8zoFm/lv34h/wCOe0h5DekUxwZxNqfBZslkZ6GqNKQQCd3xLS81wvjqyVVp4Pry7
# bwMQJXcVNIr5NsxDkuS6T/FikyglVyn7URnHoSVAaoRXxrKdsbwcCtp8Z359Luko
# TBh+xHsxQXGaSynsCz1XUNLK3f2eBVHlRHjdAd6xdZgNVCT98E7j4viDvXK6yz06
# 7vBeF5Jobchh+abxKgoLpbn0nu6YMgWFnuv5gynTxix9vTp3Los3QqBqgu07SqqU
# EKThDfgXxbZaeTMYkuO1dfih6Y4KJR7kHvGfWocj/5+kUZ77OYARzdu1xKeogG/l
# U9Tg46LC0lsa+jImLWpXcBw8pFguo/NbSwfcMlnzh6cabVgxghB6MIIQdgIBATCB
# kDB8MQswCQYDVQQGEwJHQjEbMBkGA1UECBMSR3JlYXRlciBNYW5jaGVzdGVyMRAw
# DgYDVQQHEwdTYWxmb3JkMRgwFgYDVQQKEw9TZWN0aWdvIExpbWl0ZWQxJDAiBgNV
# BAMTG1NlY3RpZ28gUlNBIENvZGUgU2lnbmluZyBDQQIQJl6ULMWyOufq8fQJzRxR
# /TANBglghkgBZQMEAgEFAKB8MBAGCisGAQQBgjcCAQwxAjAAMBkGCSqGSIb3DQEJ
# AzEMBgorBgEEAYI3AgEEMBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMC8G
# CSqGSIb3DQEJBDEiBCCLeWhJKuQod/8eN1VMLXA7VccwJeIjPh5z59qPqMVC9TAN
# BgkqhkiG9w0BAQEFAASCAQCnbuoLxCj1/WEgUj9Q4IglLiAk3sCk5ZiUsf5tryvc
# UjR3ORu9sU3iLTD0Wg4lilxDTgKnmE8SO3t7PERRqXkGtxMwuv/ZPtKYD1Vmjpes
# 6relFa4ZhMrsoFaSn4M8t/HFZN2GiFaakB/Pjf5vD+/QpeXZcTuAee9uCvyaSljJ
# YXS8/3Gsv1vTWp7WA9fbDYl8IGxEsSvdkYJY79zzjTdlCQJn2dbFepJm2XTkasIB
# 6HuPpcywFDptBjvahDDAn/2AJZWaT3WwhwKhmy3bFSL02IsoVy9Mgv4TsKnX5fOO
# C1Wss+oFEtGFUZR/+wxiSRoRKZ74/Fs8uoVw+8NBcfqMoYIOPDCCDjgGCisGAQQB
# gjcDAwExgg4oMIIOJAYJKoZIhvcNAQcCoIIOFTCCDhECAQMxDTALBglghkgBZQME
# AgEwggEOBgsqhkiG9w0BCRABBKCB/gSB+zCB+AIBAQYLYIZIAYb4RQEHFwMwMTAN
# BglghkgBZQMEAgEFAAQgk0nnzmQQno4Z+gF+kW2AssxuTEkNBdnUEjUkxfcBvkwC
# FDQtSPbY0Sw2kmAD9HngB46gOojqGA8yMDE5MDgyMjEwNTUyNFowAwIBHqCBhqSB
# gzCBgDELMAkGA1UEBhMCVVMxHTAbBgNVBAoTFFN5bWFudGVjIENvcnBvcmF0aW9u
# MR8wHQYDVQQLExZTeW1hbnRlYyBUcnVzdCBOZXR3b3JrMTEwLwYDVQQDEyhTeW1h
# bnRlYyBTSEEyNTYgVGltZVN0YW1waW5nIFNpZ25lciAtIEczoIIKizCCBTgwggQg
# oAMCAQICEHsFsdRJaFFE98mJ0pwZnRIwDQYJKoZIhvcNAQELBQAwgb0xCzAJBgNV
# BAYTAlVTMRcwFQYDVQQKEw5WZXJpU2lnbiwgSW5jLjEfMB0GA1UECxMWVmVyaVNp
# Z24gVHJ1c3QgTmV0d29yazE6MDgGA1UECxMxKGMpIDIwMDggVmVyaVNpZ24sIElu
# Yy4gLSBGb3IgYXV0aG9yaXplZCB1c2Ugb25seTE4MDYGA1UEAxMvVmVyaVNpZ24g
# VW5pdmVyc2FsIFJvb3QgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkwHhcNMTYwMTEy
# MDAwMDAwWhcNMzEwMTExMjM1OTU5WjB3MQswCQYDVQQGEwJVUzEdMBsGA1UEChMU
# U3ltYW50ZWMgQ29ycG9yYXRpb24xHzAdBgNVBAsTFlN5bWFudGVjIFRydXN0IE5l
# dHdvcmsxKDAmBgNVBAMTH1N5bWFudGVjIFNIQTI1NiBUaW1lU3RhbXBpbmcgQ0Ew
# ggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQC7WZ1ZVU+djHJdGoGi61Xz
# sAGtPHGsMo8Fa4aaJwAyl2pNyWQUSym7wtkpuS7sY7Phzz8LVpD4Yht+66YH4t5/
# Xm1AONSRBudBfHkcy8utG7/YlZHz8O5s+K2WOS5/wSe4eDnFhKXt7a+Hjs6Nx23q
# 0pi1Oh8eOZ3D9Jqo9IThxNF8ccYGKbQ/5IMNJsN7CD5N+Qq3M0n/yjvU9bKbS+GI
# mRr1wOkzFNbfx4Dbke7+vJJXcnf0zajM/gn1kze+lYhqxdz0sUvUzugJkV+1hHk1
# inisGTKPI8EyQRtZDqk+scz51ivvt9jk1R1tETqS9pPJnONI7rtTDtQ2l4Z4xaE3
# AgMBAAGjggF3MIIBczAOBgNVHQ8BAf8EBAMCAQYwEgYDVR0TAQH/BAgwBgEB/wIB
# ADBmBgNVHSAEXzBdMFsGC2CGSAGG+EUBBxcDMEwwIwYIKwYBBQUHAgEWF2h0dHBz
# Oi8vZC5zeW1jYi5jb20vY3BzMCUGCCsGAQUFBwICMBkaF2h0dHBzOi8vZC5zeW1j
# Yi5jb20vcnBhMC4GCCsGAQUFBwEBBCIwIDAeBggrBgEFBQcwAYYSaHR0cDovL3Mu
# c3ltY2QuY29tMDYGA1UdHwQvMC0wK6ApoCeGJWh0dHA6Ly9zLnN5bWNiLmNvbS91
# bml2ZXJzYWwtcm9vdC5jcmwwEwYDVR0lBAwwCgYIKwYBBQUHAwgwKAYDVR0RBCEw
# H6QdMBsxGTAXBgNVBAMTEFRpbWVTdGFtcC0yMDQ4LTMwHQYDVR0OBBYEFK9j1sqj
# ToVy4Ke8QfMpojh/gHViMB8GA1UdIwQYMBaAFLZ3+mlIR59TEtXC6gcydgfRlwcZ
# MA0GCSqGSIb3DQEBCwUAA4IBAQB16rAt1TQZXDJF/g7h1E+meMFv1+rd3E/zociB
# iPenjxXmQCmt5l30otlWZIRxMCrdHmEXZiBWBpgZjV1x8viXvAn9HJFHyeLojQP7
# zJAv1gpsTjPs1rSTyEyQY0g5QCHE3dZuiZg8tZiX6KkGtwnJj1NXQZAv4R5NTtzK
# EHhsQm7wtsX4YVxS9U72a433Snq+8839A9fZ9gOoD+NT9wp17MZ1LqpmhQSZt/gG
# V+HGDvbor9rsmxgfqrnjOgC/zoqUywHbnsc4uw9Sq9HjlANgCk2g/idtFDL8P5dA
# 4b+ZidvkORS92uTTw+orWrOVWFUEfcea7CMDjYUq0v+uqWGBMIIFSzCCBDOgAwIB
# AgIQe9Tlr7rMBz+hASMEIkFNEjANBgkqhkiG9w0BAQsFADB3MQswCQYDVQQGEwJV
# UzEdMBsGA1UEChMUU3ltYW50ZWMgQ29ycG9yYXRpb24xHzAdBgNVBAsTFlN5bWFu
# dGVjIFRydXN0IE5ldHdvcmsxKDAmBgNVBAMTH1N5bWFudGVjIFNIQTI1NiBUaW1l
# U3RhbXBpbmcgQ0EwHhcNMTcxMjIzMDAwMDAwWhcNMjkwMzIyMjM1OTU5WjCBgDEL
# MAkGA1UEBhMCVVMxHTAbBgNVBAoTFFN5bWFudGVjIENvcnBvcmF0aW9uMR8wHQYD
# VQQLExZTeW1hbnRlYyBUcnVzdCBOZXR3b3JrMTEwLwYDVQQDEyhTeW1hbnRlYyBT
# SEEyNTYgVGltZVN0YW1waW5nIFNpZ25lciAtIEczMIIBIjANBgkqhkiG9w0BAQEF
# AAOCAQ8AMIIBCgKCAQEArw6Kqvjcv2l7VBdxRwm9jTyB+HQVd2eQnP3eTgKeS3b2
# 5TY+ZdUkIG0w+d0dg+k/J0ozTm0WiuSNQI0iqr6nCxvSB7Y8tRokKPgbclE9yAmI
# Jgg6+fpDI3VHcAyzX1uPCB1ySFdlTa8CPED39N0yOJM/5Sym81kjy4DeE035EMmq
# ChhsVWFX0fECLMS1q/JsI9KfDQ8ZbK2FYmn9ToXBilIxq1vYyXRS41dsIr9Vf2/K
# Bqs/SrcidmXs7DbylpWBJiz9u5iqATjTryVAmwlT8ClXhVhe6oVIQSGH5d600yay
# e0BTWHmOUjEGTZQDRcTOPAPstwDyOiLFtG/l77CKmwIDAQABo4IBxzCCAcMwDAYD
# VR0TAQH/BAIwADBmBgNVHSAEXzBdMFsGC2CGSAGG+EUBBxcDMEwwIwYIKwYBBQUH
# AgEWF2h0dHBzOi8vZC5zeW1jYi5jb20vY3BzMCUGCCsGAQUFBwICMBkaF2h0dHBz
# Oi8vZC5zeW1jYi5jb20vcnBhMEAGA1UdHwQ5MDcwNaAzoDGGL2h0dHA6Ly90cy1j
# cmwud3Muc3ltYW50ZWMuY29tL3NoYTI1Ni10c3MtY2EuY3JsMBYGA1UdJQEB/wQM
# MAoGCCsGAQUFBwMIMA4GA1UdDwEB/wQEAwIHgDB3BggrBgEFBQcBAQRrMGkwKgYI
# KwYBBQUHMAGGHmh0dHA6Ly90cy1vY3NwLndzLnN5bWFudGVjLmNvbTA7BggrBgEF
# BQcwAoYvaHR0cDovL3RzLWFpYS53cy5zeW1hbnRlYy5jb20vc2hhMjU2LXRzcy1j
# YS5jZXIwKAYDVR0RBCEwH6QdMBsxGTAXBgNVBAMTEFRpbWVTdGFtcC0yMDQ4LTYw
# HQYDVR0OBBYEFKUTAamfhcwbbhYeXzsxqnk2AHsdMB8GA1UdIwQYMBaAFK9j1sqj
# ToVy4Ke8QfMpojh/gHViMA0GCSqGSIb3DQEBCwUAA4IBAQBGnq/wuKJfoplIz6gn
# SyHNsrmmcnBjL+NVKXs5Rk7nfmUGWIu8V4qSDQjYELo2JPoKe/s702K/SpQV5oLb
# ilRt/yj+Z89xP+YzCdmiWRD0Hkr+Zcze1GvjUil1AEorpczLm+ipTfe0F1mSQcO3
# P4bm9sB/RDxGXBda46Q71Wkm1SF94YBnfmKst04uFZrlnCOvWxHqcalB+Q15OKmh
# Dc+0sdo+mnrHIsV0zd9HCYbE/JElshuW6YUI6N3qdGBuYKVWeg3IRFjc5vlIFJ7l
# v94AvXexmBRyFCTfxxEsHwA/w0sUxmcczB4Go5BfXFSLPuMzW4IPxbeGAk5xn+lm
# RT92MYICWjCCAlYCAQEwgYswdzELMAkGA1UEBhMCVVMxHTAbBgNVBAoTFFN5bWFu
# dGVjIENvcnBvcmF0aW9uMR8wHQYDVQQLExZTeW1hbnRlYyBUcnVzdCBOZXR3b3Jr
# MSgwJgYDVQQDEx9TeW1hbnRlYyBTSEEyNTYgVGltZVN0YW1waW5nIENBAhB71OWv
# uswHP6EBIwQiQU0SMAsGCWCGSAFlAwQCAaCBpDAaBgkqhkiG9w0BCQMxDQYLKoZI
# hvcNAQkQAQQwHAYJKoZIhvcNAQkFMQ8XDTE5MDgyMjEwNTUyNFowLwYJKoZIhvcN
# AQkEMSIEIDRr86tL2tBcMIQlaopynL/bUwSvYzWYdfmeGGReYAwlMDcGCyqGSIb3
# DQEJEAIvMSgwJjAkMCIEIMR0znYAfQI5Tg2l5N58FMaA+eKCATz+9lPvXbcf32H4
# MAsGCSqGSIb3DQEBAQSCAQCXPcJYwDlaCIA5JEKCxUMuN3wTQdz421hohgPXlEd2
# TCzqkZYCSagqYfyLgqXUaPReN7DVABK+cTpO4iP7VMlzyLlF+XuaZyFxaXl1NCDD
# g+0tXqvw82GlFaV6F0TkRO0T7yjxQRCEosWKnVdWkEumZd5jgRVS++7m/fcqdKEX
# j3qoHneO0wodyyheqnaojb9jebsyGt6CQeEp1mIc04fTfhEoTD/7EHmRsuJrOxe7
# C8Sdz7SyK4CBCKfzKkUxEnEEn+KqwVXJ7pZvS6ngNsffCbGExAXgFA44+lbdLuxP
# wQaEqkeX/Ce3V9mE2F+MtRjtQHpXVBD8scXZwEFem9/u
# SIG # End signature block
