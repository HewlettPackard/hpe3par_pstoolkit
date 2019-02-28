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
##	Pre-requisites: Needs HPE 3PAR cli.exe for New-3parCLIConnection
##					Needs POSH SSH Module for New-3parPoshSshConnection
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
##	Last Modified:	January 2019
##
##	History:		v1.0 - Created
##					v2.0 - Added support for HP3PAR CLI
##                     v2.1 - Added support for POSH SSH Module
##					v2.2 - Added support for WSAPI
##	
#####################################################################################

# Generic connection object 

add-type @" 

public struct _Connection{
public string SessionId;
public string IPAddress;
public string UserName;
public string epwdFile;
public string CLIDir;
public string CLIType;
}

"@


$global:LogInfo = $true
$global:DisplayInfo = $true
#$global:SANConnection = New-Object System.Collections.ArrayList #set in HPE3PARPSToolkit.psm1 
$global:SANConnection = $null #set in HPE3PARPSToolkit.psm1 
$global:WsapiConnection = $null

#[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

if(!$global:VSVersion)
{
	$global:VSVersion = "VS3 V2.0"
}

if(!$global:ConfigDir) 
{
	$global:ConfigDir = $null 
}
$Info = "INFO:"
$Debug = "DEBUG:"

Import-Module "$global:VSLibraries\Logger.psm1"

############################################################################################################################################
## FUNCTION Invoke-3parCLICMD
############################################################################################################################################

Function Invoke-3parCLICmd
{
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
		
		Invoke-3parCLICmd -Connection $global:SANConnection -Cmds "showsysmgr"
		The command queries a 3PAR array to get information on the 3PAr system
		$global:SANConnection is created wiith the cmdlet New-SANConnection
			
  .Notes
    NAME:  Invoke-3parCLICmd
    LASTEDIT: June 2012
    KEYWORDS: Invoke-3parCLICmd
   
  .Link
     Http://www.hp.com
 
 #Requires HP3PAR CLI -Version 3.2.2
 #>
 
[CmdletBinding()]
	Param(	
			[Parameter(Mandatory=$true)]
			$Connection,
			
			[Parameter(Mandatory=$true)]
			[string]$Cmds  

		)

Write-DebugLog "Start: In Invoke-3parCLICmd - validating input values" $Debug 

	#check if connection object contents are null/empty
	if(!$Connection)
	{	
		$connection = [_Connection]$Connection	
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $Connection
		if($Validate1 -eq "Failed")
		{
			Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-*Connection and pass it as parameter" "ERR:"
			Write-DebugLog "Stop: Exiting Invoke-3parCLICmd since connection object values are null/empty" "ERR:"
			return
		}
	}
	#check if cmd is null/empty
	if (!$Cmds)
	{
		Write-DebugLog "No command is passed to the Invoke-3parCLICmd." "ERR:"
		Write-DebugLog "Stop: Exiting Invoke-3parCLICmd since command parameter is null/empty null/empty" "ERR:"
		return
	}
	$clittype = $Connection.cliType
	
	if($clittype -eq "3parcli")
	{
		#write-host "In invoke-3parclicmd -> entered in clitype $clittype"
		Invoke-3parCLI  -DeviceIPAddress  $Connection.IPAddress -epwdFile $Connection.epwdFile -CLIDir $Connection.CLIDir -cmd $Cmds
	}
	elseif($clittype -eq "SshClient")
	{
		
		$Result = Invoke-SSHCommand -Command $Cmds -SessionId $Connection.SessionId
		if($Result.ExitStatus -eq 0)
		{
			return $Result.Output
		}
		else
		{
			$Error = "Error :-"+ $Result.Error + $Result.Output			    
			return $Error
		}
		
	}
	else
	{
		return "FAILURE : Invalid cliType option"
	}

}# End Invoke-3parCLICMD

############################################################################################################################################
## FUNCTION SET-DEBUGLOG
############################################################################################################################################

Function Set-DebugLog
{
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
     http://www.hp.com
 
 #Requires PS -Version 3.0
 
 #>
 [CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory= $true, ValueFromPipeline=$true)]
		[System.Boolean]
        $LogDebugInfo=$false,		
		[parameter(Position=2, Mandatory = $true, ValueFromPipeline=$true)]
    	[System.Boolean]
   		$Display = $true
		 
	)

$global:LogInfo = $LogDebugInfo
$global:DisplayInfo = $Display	
Write-DebugLog "Exiting function call Set-DebugLog. The value of logging debug information is set to $global:LogInfo and the value of Display on console is $global:DisplayInfo" $Debug
}

############################################################################################################################################
## FUNCTION Invoke-3parCLI
############################################################################################################################################

Function Invoke-3parCLI 
{
<#
  .SYNOPSIS
    This is private method not to be used. For internal use only.
  
  .DESCRIPTION
    Executes 3par cli command with the specified paramaeters to get data from the specified virtual Connect IP Address 
   
  .EXAMPLE
    Invoke-3parCLI -DeviceIPAddress "DeviceIPAddress" -CLIDir "Full Installed Path of cli.exe" -epwdFile "C:\loginencryptddetails.txt"  -cmd "show server $serverID"
    
   
  .PARAMETER DeviceIPAddress 
    Specify the IP address for Virtual Connect(VC) or Onboard Administrator(OA) or Storage or any other device
    
  .PARAMETER CLIDir 
    Specify the absolute path of HP3PAR CLI's cli.exe
    
   .PARAMETER epwdFIle 
    Specify the encrypted password file location
	
  .PARAMETER cmd 
    Specify the command to be run for Virtual Connect
        
  .Notes
    NAME:  Invoke-3parCLI    
    LASTEDIT: 04/04/2012
    KEYWORDS: 3parCLI
   
  .Link
     Http://www.hp.com
 
 #Requires PS -Version 3.0
 
 #>
 
 [CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
		[System.String]
        $DeviceIPAddress=$null,
		[Parameter(Position=1)]
		[System.String]
        #$CLIDir="C:\Program Files (x86)\Hewlett-Packard\HP 3PAR CLI\bin",
		$CLIDir="C:\Program Files (x86)\Hewlett Packard Enterprise\HPE 3PAR CLI\bin",
		[Parameter(Position=2)]
		[System.String]
        $epwdFile="C:\HP3PARepwdlogin.txt",
        [Parameter(Position=3)]
		[System.String]
        $cmd="show -help"
	)
	#write-host  "Password in Invoke-3parCLI = ",$password	
	Write-DebugLog "start:In function Invoke-3parCLI. Validating PUTTY path." $Debug
	if(Test-Path -Path $CLIDir)
	{
		$clifile = $CLIDir + "\cli.exe"
		if( -not (Test-Path $clifile))
		{
			
			Write-DebugLog "Stop: HP3PAR cli.exe file was not found. Make sure you have cli.exe file under $CLIDir." "ERR:"			
			return "FAILURE : HP3PAR cli.exe file was not found. Make sure you have cli.exe file under $CLIDir. "
		}
	}
	else
	{
		$SANCObj = $global:SANConnection
		$CLIDir = $SANCObj.CLIDir
	}
	if (-not (Test-Path -Path $CLIDir )) 
	{
		Write-DebugLog "Stop: Path for HP3PAR cli.exe was not found. Make sure you have installed HP3PAR CLI" "ERR:"			
		return "FAILURE : Path for HP3PAR cli.exe was not found. Make sure you have installed HP3PAR CLI in $CLIDir "
	}	
	Write-DebugLog "Running:In function Invoke-3parCLI. Calling Test Network with IP Address = $DeviceIPAddress" $Debug	
	$Status = Test-Network $DeviceIPAddress
	if($Status -eq $null)
	{
		Write-DebugLog "Stop:In function Invoke-3parCLI. Invalid IP Address Format"  "ERR:"
		Throw "Invalid IP Address Format"
		
	}
	if($Status -eq "Failed")
	{
		Write-DebugLog "Stop:In function Invoke-3parCLI. Not able to ping the device with IP $DeviceIPAddress. Check IP address and try again."  "ERR:"
		Throw "Not able to ping the device with IP $DeviceIPAddress. Check IP address and try again."
	}
	
	Write-DebugLog "Running:In function Invoke-3parCLI. Executed Test Network with IP Address = $DeviceIPAddress. Now invoking HP3par cli...." $Debug
	
	try{

		#if(!($global:epwdFile)){
		#	Write-DebugLog "Stop:Please create encrpted password file first using New-SANConnection"  "ERR:"
		#	return "`nFAILURE : Please create encrpted password file first using New-SANConnection"
		#}	
		#write-host "encrypted password file is $epwdFile"
		$pwfile = $epwdFile
		$test = $cmd.split(" ")
		#$test = [regex]::split($cmd," ")
		$fcmd = $test[0].trim()
		$count=  $test.count
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
		if(!($?	)){
			return "`nFAILURE : FATAL ERROR"
		}	
	}
	catch{
		$msg = "In function Invoke-3parCLI -->Exception Occured. "
		$msg+= $_.Exception.ToString()			
		Write-Exception $msg -error
		Throw $msg
	}	
	Write-DebugLog "End:In function Invoke-3parCLI. If there are no errors reported on the console then HP3par cli with the cmd = $cmd for user $username has completed Successfully" $Debug
}

############################################################################################################################################
## FUNCTION TEST-NETWORK
############################################################################################################################################

Function Test-Network ([string]$IPAddress)
{
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
     http://www.hp.com
 
 #Requires PS -Version 3.0
 
 #>

	$Status = Test-IPFormat $IPAddress
	if ($Status -eq $null)
	{
		return $Status 
	}

	try 
	{
	  $Ping = new-object System.Net.NetworkInformation.Ping
	  $result = $ping.Send($IPAddress)
	  $Status = $result.Status.ToString()
	}
	catch [Exception]
	{
	  ## Server does not exist - skip it
	  $Status = "Failed"
	}
	                
	return $Status
				
}

############################################################################################################################################
## FUNCTION TEST-IPFORMAT
############################################################################################################################################

Function Test-IPFormat 
{
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
     http://www.hp.com
 
 #Requires PS -Version 3.0
 
 #>

	param([string]$Address =$(throw "Missing IP address parameter"))
	trap{$false;continue;}
	[bool][System.Net.IPAddress]::Parse($Address);
}


############################################################################################################################################
## FUNCTION Test-3PARConnection
############################################################################################################################################
Function Test-3PARConnection 
{
  [CmdletBinding()]
  Param(
  [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
  $WsapiConnection = $global:WsapiConnection
  )
  Write-DebugLog "Request: Request Test-3PARConnection to Test if the session key exists." $Debug  
  Write-DebugLog "Running: Validate the 3PAR session key exists." $Debug  
  
  $Validate = "Success"
  if(($WsapiConnection -eq $null) -or (-not ($WsapiConnection.IPAddress)) -or (-not ($WsapiConnection.Key)))
  {
	  Write-DebugLog "Stop: You are not connected to a 3PAR array or session key is expire.Please connect using : New-3parWSAPIConnection."
      
	  Write-Host
	  Write-Host "You are not connected to a 3PAR array or session key is expire.Please connect using : New-3parWSAPIConnection." -foreground yellow
	  Write-Host
	  
	  throw 
  }
  else
  {
	Write-DebugLog " End: Connected" $Info
  }
  Write-DebugLog "End: Test-3PARConnection" $Debug  
}

#END Test-3PARConnection

############################################################################################################################################
## FUNCTION Invoke-3parWSAPI
############################################################################################################################################
function Invoke-3parWSAPI 
{
    [CmdletBinding()]
    Param (
        [parameter(Position = 0, Mandatory = $true, HelpMessage = "Enter the resource URI (ex. /volumes)")]
        [ValidateScript({if ($_.startswith('/')) {$true} else {throw "-URI must begin with a '/' (eg. /volumes) in its value. Please correct the value and try again."}})]
        [string]
		$uri,
		
        [parameter(Position = 1, Mandatory = $true, HelpMessage = "Enter request type (GET POST DELETE)")]
        [string]
		$type,
		
        [parameter(Position = 2, Mandatory = $false, HelpMessage = "Body of the message")]
        [array]
		$body,
		
		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
		$WsapiConnection = $global:WsapiConnection
    )
    
	Write-DebugLog "Request: Request Invoke-3parWSAPI URL : $uri TYPE : $type " $Debug  
	
	$ip = $WsapiConnection.IPAddress
	$key = $WsapiConnection.Key
	
	$APIurl = 'https://'+$ip+':8080/api/v1'
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
    If ($type -eq 'GET')
	{
      Try
      {
		  Write-DebugLog "Request: Invoke-WebRequest for Data, Request Type : $type" $Debug
          $data = Invoke-WebRequest -Uri "$url" -Headers $headers -Method $type -UseBasicParsing
          return $data
      }
      Catch
      {
		Write-DebugLog "Stop: Exception Occurs" $Debug
        Show-RequestException -Exception $_
        return
      }
    }
    If (($type -eq 'POST') -or ($type -eq 'PUT')) 
	{
      Try
      {
		
		Write-DebugLog "Request: Invoke-WebRequest for Data, Request Type : $type" $Debug
        $json = $body | ConvertTo-Json  -Compress -Depth 10	
		
		#write-host "Invoke json = $json"
		
        $data = Invoke-WebRequest -Uri "$url" -Body $json -Headers $headers -Method $type -UseBasicParsing		
        return $data
      }
      Catch
      {
		Write-DebugLog "Stop: Exception Occurs" $Debug
        Show-RequestException -Exception $_
        return
      }
    }
    If ($type -eq 'DELETE') 
	{
      Try
      {
		Write-DebugLog "Request: Invoke-WebRequest for Data, Request Type : $type" $Debug
        $data = Invoke-WebRequest -Uri "$url" -Headers $headers -Method $type -UseBasicParsing
        return $data
      }
      Catch
      {
		Write-DebugLog "Stop: Exception Occurs" $Debug
        Show-RequestException -Exception $_
        return
      }
    }
	Write-DebugLog "End: Invoke-3parWSAPI" $Debug
}
#END Invoke-3parWSAPI

############################################################################################################################################
## FUNCTION Format-Result
############################################################################################################################################
function Format-Result
{
    [CmdletBinding()]
    Param (
      [parameter(Mandatory = $true)]
      $dataPS,
      [parameter(Mandatory = $true)]
      [string]$TypeName
    )

    Begin { $AlldataPS = @() }

    Process 
	{
      # Add custom type to the resulting oject for formating purpose	 
      Foreach ($data in $dataPS)
	  {	  
        If ($data) 
		{		  
          $data.PSObject.TypeNames.Insert(0,$TypeName)
        }		
        $AlldataPS += $data
      }
    }

    End {return $AlldataPS}
}
#END Format-Result

############################################################################################################################################
## FUNCTION Show-RequestException 
############################################################################################################################################
Function Show-RequestException 
{
  [CmdletBinding()]
  Param(
    [parameter(Mandatory = $true)]
    $Exception
  )

  #Exception catch when there's a connectivity problem with the array
  If ($Exception.Exception.InnerException) 
  {
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

	Return $result.code
  }

  #Exception catch when the rest request return an error
  If ($_.Exception.Response) 
  {
    $readStream = New-Object -TypeName System.IO.StreamReader -ArgumentList ($Exception.Exception.Response.GetResponseStream())
    $body = $readStream.ReadToEnd()
    $readStream.Close()
    $result = ConvertFrom-Json -InputObject $body

    Write-Host "The array send an error message: $($result.desc)." -foreground yellow
    #Write-Host "Retry with the parameter -Verbose for more informations" -foreground yellow
    Write-Host
    Write-Host "Status: $($Exception.Exception.Status)" -foreground yellow
    Write-Host "Error code: $($result.code)" -foreground yellow
    Write-Host "HTTP Error code: $($Exception.Exception.Response.StatusCode.value__)" -foreground yellow
    Write-Host "Message: $($result.desc)" -foreground yellow
    Write-Host
	
	Write-DebugLog "Stop:The array send an error message: $($result.desc)." $Debug
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

Function Test-FilePath ([String[]]$ConfigFiles)
{
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
     http://www.hp.com
 
 #Requires PS -Version 3.0
 
 #>
 
 	Write-DebugLog "Start: Entering function Test-FilePath." $Debug
	$Validate = @()	
	if(-not ($global:ConfigDir))
	{
		Write-DebugLog "STOP: Configuration Directory path is not set. Run scripts Init-PS-Session.ps1 OR import module VS-Functions.psm1 and run cmdlet Set-ConfigDirectory" "ERR:"
		$Validate = @("Configuration Directory path is not set. Run scripts Init-PS-Session.ps1 OR import module VS-Functions.psm1 and run cmdlet Set-ConfigDirectory.")
		return $Validate
	}
	foreach($argConfigFile in $ConfigFiles)
	{			
			if (-not (Test-Path -Path $argConfigFile )) 
			{
				
				$FullPathConfigFile = $global:ConfigDir + $argConfigFile
				if(-not (Test-Path -Path $FullPathConfigFile))
				{
					$Validate = $Validate + @(,"Path $FullPathConfigFile not found.")					
				}				
			}
	}	
	
	Write-DebugLog "End: Leaving function Test-FilePath." $Debug
	return $Validate
}

Function Test-PARCLi{
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
     http://www.hp.com
 
 #Requires PS -Version 3.0
 
 #> 
 [CmdletBinding()]
	param 
	(
		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
	)
	$SANCOB = $SANConnection 
	$clittype = $SANCOB.CliType
	Write-DebugLog "Start : in Test-PARCli function " "INFO:"
	if($clittype -eq "3parcli")
	{
		Test-PARCliTest -SANConnection $SANConnection
	}
	elseif($clittype -eq "SshClient")
	{
		Test-SSHSession -SANConnection $SANConnection
	}
	else
	{
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
     http://www.hp.com
 
 #Requires PS -Version 3.0
 
 #> 
 [CmdletBinding()]
	param 
	(	
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
	)
	
	$Result = Get-SSHSession | fl
	
	if($Result.count -gt 1)
	{
	}
	else
	{
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
     http://www.hp.com
 
 #Requires PS -Version 3.0
 
 #> 
 [CmdletBinding()]
	param 
	(
		[Parameter(Position=0,Mandatory=$false)]
		[System.String]
		#$pathFolder = "C:\Program Files (x86)\Hewlett-Packard\HP 3PAR CLI\bin\",
		$pathFolder="C:\Program Files (x86)\Hewlett Packard Enterprise\HPE 3PAR CLI\bin",
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
	)
	$SANCOB = $SANConnection 
	$DeviceIPAddress = $SANCOB.IPAddress
	Write-DebugLog "Start : in Test-PARCli function " "INFO:"
	#Write-host "Start : in Test-PARCli function "
	$CLIDir = $pathFolder
	if(Test-Path -Path $CLIDir){
		$clitestfile = $CLIDir + "\cli.exe"
		if( -not (Test-Path $clitestfile)){					
			return "FAILURE : HP3PAR cli.exe file was not found. Make sure you have cli.exe file under $CLIDir "
		}
		$pwfile = $SANCOB.epwdFile
		$cmd2 = "help.bat"
		#$cmdFinal = "$cmd2 -sys $DeviceIPAddress -pwf $pwfile"
		& $cmd2 -sys $DeviceIPAddress -pwf $pwfile
		#Invoke-Expression $cmdFinal
		if(!($?)){
			return "`nFAILURE : FATAL ERROR"
		}
	}
	else{
		$SANCObj = $SANConnection
		$CLIDir = $SANCObj.CLIDir	
		$clitestfile = $CLIDir + "\cli.exe"
		if (-not (Test-Path $clitestfile )) 
		{					
			return "FAILURE : HP3PAR cli.exe was not found. Make sure you have cli.exe file under $CLIDir "
		}
		$pwfile = $SANCObj.epwdFile
		$cmd2 = "help.bat"
		#$cmdFinal = "$cmd2 -sys $DeviceIPAddress -pwf $pwfile"
		#Invoke-Expression $cmdFinal
		& $cmd2 -sys $DeviceIPAddress -pwf $pwfile
		if(!($?)){
			return "`nFAILURE : FATAL ERROR"
		}
	}
	Write-DebugLog "Stop : in Test-PARCli function " "INFO:"
}

############################################################################################################################################
## FUNCTION TEST-CONNECTIONOBJECT
############################################################################################################################################

Function Test-ConnectionObject ($SANConnection)
{
<#
  .SYNOPSIS
    Validate connection object. For Internal Use only.
  
  .DESCRIPTION
	Validates if connection object for VC and OA are null/empty
        
  .EXAMPLE
    Test-ConnectionObject -SANConnection
	    
  .PARAMETER -SANConnection 
    Specify the VC or OA connection object. Ideally VC or Oa connection object is obtained by executing New-VCConnection or New-OAConnection.
	
  .Notes
    NAME:  Test-ConnectionObject
    LASTEDIT: 05/09/2012
    KEYWORDS: Test-ConnectionObject
   
  .Link
     http://www.hp.com
 
 #Requires PS -Version 3.0
 
 #>
	$Validate = "Success"
	if(($SANConnection -eq $null) -or (-not ($SANConnection.AdminName)) -or (-not ($SANConnection.Password)) -or (-not ($SANConnection.IPAddress)) -or (-not ($SANConnection.SSHDir)))
	{
		#Write-DebugLog "Connection object is null/empty or Connection object username,password,ipadress are null/empty. Create a valid connection object" "ERR:"
		$Validate = "Failed"		
	}
	return $Validate
}

Export-ModuleMember Test-IPFormat , Test-3PARConnection , Invoke-3parWSAPI , Format-Result , Show-RequestException , Test-SSHSession , Set-DebugLog , Test-Network , Invoke-3parCLI , Invoke-3parCLICmd , Test-FilePath , Test-PARCli , Test-PARCliTest, Test-ConnectionObject
# SIG # Begin signature block
# MIIgCwYJKoZIhvcNAQcCoIIf/DCCH/gCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDL5M5U0QqF8FCV
# uhBdTUjQzytlg7lb7p+rcq9m8Q5TfKCCGpEwggQUMIIC/KADAgECAgsEAAAAAAEv
# TuFS1zANBgkqhkiG9w0BAQUFADBXMQswCQYDVQQGEwJCRTEZMBcGA1UEChMQR2xv
# YmFsU2lnbiBudi1zYTEQMA4GA1UECxMHUm9vdCBDQTEbMBkGA1UEAxMSR2xvYmFs
# U2lnbiBSb290IENBMB4XDTExMDQxMzEwMDAwMFoXDTI4MDEyODEyMDAwMFowUjEL
# MAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24gbnYtc2ExKDAmBgNVBAMT
# H0dsb2JhbFNpZ24gVGltZXN0YW1waW5nIENBIC0gRzIwggEiMA0GCSqGSIb3DQEB
# AQUAA4IBDwAwggEKAoIBAQCU72X4tVefoFMNNAbrCR+3Rxhqy/Bb5P8npTTR94ka
# v56xzRJBbmbUgaCFi2RaRi+ZoI13seK8XN0i12pn0LvoynTei08NsFLlkFvrRw7x
# 55+cC5BlPheWMEVybTmhFzbKuaCMG08IGfaBMa1hFqRi5rRAnsP8+5X2+7UulYGY
# 4O/F69gCWXh396rjUmtQkSnF/PfNk2XSYGEi8gb7Mt0WUfoO/Yow8BcJp7vzBK6r
# kOds33qp9O/EYidfb5ltOHSqEYva38cUTOmFsuzCfUomj+dWuqbgz5JTgHT0A+xo
# smC8hCAAgxuh7rR0BcEpjmLQR7H68FPMGPkuO/lwfrQlAgMBAAGjgeUwgeIwDgYD
# VR0PAQH/BAQDAgEGMBIGA1UdEwEB/wQIMAYBAf8CAQAwHQYDVR0OBBYEFEbYPv/c
# 477/g+b0hZuw3WrWFKnBMEcGA1UdIARAMD4wPAYEVR0gADA0MDIGCCsGAQUFBwIB
# FiZodHRwczovL3d3dy5nbG9iYWxzaWduLmNvbS9yZXBvc2l0b3J5LzAzBgNVHR8E
# LDAqMCigJqAkhiJodHRwOi8vY3JsLmdsb2JhbHNpZ24ubmV0L3Jvb3QuY3JsMB8G
# A1UdIwQYMBaAFGB7ZhpFDZfKiVAvfQTNNKj//P1LMA0GCSqGSIb3DQEBBQUAA4IB
# AQBOXlaQHka02Ukx87sXOSgbwhbd/UHcCQUEm2+yoprWmS5AmQBVteo/pSB204Y0
# 1BfMVTrHgu7vqLq82AafFVDfzRZ7UjoC1xka/a/weFzgS8UY3zokHtqsuKlYBAIH
# MNuwEl7+Mb7wBEj08HD4Ol5Wg889+w289MXtl5251NulJ4TjOJuLpzWGRCCkO22k
# aguhg/0o69rvKPbMiF37CjsAq+Ah6+IvNWwPjjRFl+ui95kzNX7Lmoq7RU3nP5/C
# 2Yr6ZbJux35l/+iS4SwxovewJzZIjyZvO+5Ndh95w+V/ljW8LQ7MAbCOf/9RgICn
# ktSzREZkjIdPFmMHMUtjsN/zMIIEnzCCA4egAwIBAgISESHWmadklz7x+EJ+6RnM
# U0EUMA0GCSqGSIb3DQEBBQUAMFIxCzAJBgNVBAYTAkJFMRkwFwYDVQQKExBHbG9i
# YWxTaWduIG52LXNhMSgwJgYDVQQDEx9HbG9iYWxTaWduIFRpbWVzdGFtcGluZyBD
# QSAtIEcyMB4XDTE2MDUyNDAwMDAwMFoXDTI3MDYyNDAwMDAwMFowYDELMAkGA1UE
# BhMCU0cxHzAdBgNVBAoTFkdNTyBHbG9iYWxTaWduIFB0ZSBMdGQxMDAuBgNVBAMT
# J0dsb2JhbFNpZ24gVFNBIGZvciBNUyBBdXRoZW50aWNvZGUgLSBHMjCCASIwDQYJ
# KoZIhvcNAQEBBQADggEPADCCAQoCggEBALAXrqLTtgQwVh5YD7HtVaTWVMvY9nM6
# 7F1eqyX9NqX6hMNhQMVGtVlSO0KiLl8TYhCpW+Zz1pIlsX0j4wazhzoOQ/DXAIlT
# ohExUihuXUByPPIJd6dJkpfUbJCgdqf9uNyznfIHYCxPWJgAa9MVVOD63f+ALF8Y
# ppj/1KvsoUVZsi5vYl3g2Rmsi1ecqCYr2RelENJHCBpwLDOLf2iAKrWhXWvdjQIC
# KQOqfDe7uylOPVOTs6b6j9JYkxVMuS2rgKOjJfuv9whksHpED1wQ119hN6pOa9PS
# UyWdgnP6LPlysKkZOSpQ+qnQPDrK6Fvv9V9R9PkK2Zc13mqF5iMEQq8CAwEAAaOC
# AV8wggFbMA4GA1UdDwEB/wQEAwIHgDBMBgNVHSAERTBDMEEGCSsGAQQBoDIBHjA0
# MDIGCCsGAQUFBwIBFiZodHRwczovL3d3dy5nbG9iYWxzaWduLmNvbS9yZXBvc2l0
# b3J5LzAJBgNVHRMEAjAAMBYGA1UdJQEB/wQMMAoGCCsGAQUFBwMIMEIGA1UdHwQ7
# MDkwN6A1oDOGMWh0dHA6Ly9jcmwuZ2xvYmFsc2lnbi5jb20vZ3MvZ3N0aW1lc3Rh
# bXBpbmdnMi5jcmwwVAYIKwYBBQUHAQEESDBGMEQGCCsGAQUFBzAChjhodHRwOi8v
# c2VjdXJlLmdsb2JhbHNpZ24uY29tL2NhY2VydC9nc3RpbWVzdGFtcGluZ2cyLmNy
# dDAdBgNVHQ4EFgQU1KKESjhaGH+6TzBQvZ3VeofWCfcwHwYDVR0jBBgwFoAURtg+
# /9zjvv+D5vSFm7DdatYUqcEwDQYJKoZIhvcNAQEFBQADggEBAI+pGpFtBKY3IA6D
# lt4j02tuH27dZD1oISK1+Ec2aY7hpUXHJKIitykJzFRarsa8zWOOsz1QSOW0zK7N
# ko2eKIsTShGqvaPv07I2/LShcr9tl2N5jES8cC9+87zdglOrGvbr+hyXvLY3nKQc
# MLyrvC1HNt+SIAPoccZY9nUFmjTwC1lagkQ0qoDkL4T2R12WybbKyp23prrkUNPU
# N7i6IA7Q05IqW8RZu6Ft2zzORJ3BOCqt4429zQl3GhC+ZwoCNmSIubMbJu7nnmDE
# Rqi8YTNsz065nLlq8J83/rU9T5rTTf/eII5Ol6b9nwm8TcoYdsmwTYVQ8oDSHQb1
# WAQHsRgwggU7MIIDI6ADAgECAgphIE20AAAAAAAnMA0GCSqGSIb3DQEBBQUAMH8x
# CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
# b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKTAnBgNVBAMTIE1p
# Y3Jvc29mdCBDb2RlIFZlcmlmaWNhdGlvbiBSb290MB4XDTExMDQxNTE5NDUzM1oX
# DTIxMDQxNTE5NTUzM1owbDELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0
# IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTErMCkGA1UEAxMiRGlnaUNl
# cnQgSGlnaCBBc3N1cmFuY2UgRVYgUm9vdCBDQTCCASIwDQYJKoZIhvcNAQEBBQAD
# ggEPADCCAQoCggEBAMbM5XPm+9S75S0tMqbf5YE/yc0lSbZxKsPVlDRnogocsF9p
# pkCxxLeyj9CYpKlBWTrT3JTWPNt0OKRKzE0lgvdKpVMSOO7zSW1xkX5jtqumX8Ok
# hPhPYlG++MXs2ziS4wblCJEMxChBVfvLWokVfnHoNb9Ncgk9vjo4UFt3MRuNs8ck
# RZqnrG0AFFoEt7oT61EKmEFBIk5lYYeBQVCmeVyJ3hlKV9Uu5l0cUyx+mM0aBhak
# aHPQNAQTXKFx01p8VdteZOE3hzBWBOURtCmAEvF5OYiiAhF8J2a3iLd48soKqDir
# CmTCv2ZdlYTBoSUeh10aUAsgEsxBu24LUTi4S8sCAwEAAaOByzCByDARBgNVHSAE
# CjAIMAYGBFUdIAAwCwYDVR0PBAQDAgGGMA8GA1UdEwEB/wQFMAMBAf8wHQYDVR0O
# BBYEFLE+w2kD+L9HAdSYJhoIAu9jZCvDMB8GA1UdIwQYMBaAFGL7CiFbf0NuEdoJ
# VFBr9dKWcfGeMFUGA1UdHwROMEwwSqBIoEaGRGh0dHA6Ly9jcmwubWljcm9zb2Z0
# LmNvbS9wa2kvY3JsL3Byb2R1Y3RzL01pY3Jvc29mdENvZGVWZXJpZlJvb3QuY3Js
# MA0GCSqGSIb3DQEBBQUAA4ICAQAgjMFZ7W+cay3BSj51HUVMQVAcvYDq2bCSiwYq
# Ez9TFp5WOWqKY7Z4JHn1fbi5R6EKlsL2y72iZp8G4azSeQkO/TzcrAIMcK8/G+x4
# ftTrSwVgJtlzYZEh7bBoY+CXEqtvoBLt2Z/S2ic8s+RW+dHUgQ9xvUJ8ponczdW9
# laKr8ZMRfeisMSmoXWZwQZ38dcnVsxo5KtCFBVCLrJHKxJPLcaWdpJRvWAz6biDE
# CDG1hZ1+gfnSPcpbGIVsCobsIgkbpXQ0T38ovJVKqx22mLBdCaR3dn7vp45dhPYY
# JMvRbabDoZzCEHWA/50y/ebPQzqC986P4XIqm2K3X+2VGjlcL5RtSLcBXzMvu9wt
# czSJBEIKHIt5+aP6F+/6oRoQ3+CywZXrXAwFlzs1PhiITdtsvySJjci92J97OTok
# oNXf0fNKGpf2pm96H7CQqbOsATmR02G3ZPE+VzgDr8560rWQ9a7cOZnVtjyX7abL
# Fsd9aypMkJTmTFT9Hs0g7M5onIdY6WFgvusOydUZfZ/peL0OrCF1B4+pbuCMaipr
# nOPnZby8LTxt3ATcZ0U2Mq8EgbyoAG5hTJXFXNSOjp8vwTJ0vb0RZQMHze+3XgJX
# 2obUGig0r4hJss+l3YJWb2iqFOJZVP7/6u7v6pJwImCB4yUjwJ/MD0myNapYwzrD
# 2RaUEDCCBdMwggS7oAMCAQICEAiM5ul9BJk//xNKHVGOHxAwDQYJKoZIhvcNAQEL
# BQAwbDELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UE
# CxMQd3d3LmRpZ2ljZXJ0LmNvbTErMCkGA1UEAxMiRGlnaUNlcnQgRVYgQ29kZSBT
# aWduaW5nIENBIChTSEEyKTAeFw0xODA5MTMwMDAwMDBaFw0xOTA5MTgxMjAwMDBa
# MIHpMRMwEQYLKwYBBAGCNzwCAQMTAlVTMRkwFwYLKwYBBAGCNzwCAQITCERlbGF3
# YXJlMR0wGwYDVQQPDBRQcml2YXRlIE9yZ2FuaXphdGlvbjEQMA4GA1UEBRMHNTY5
# OTI2NTELMAkGA1UEBhMCVVMxCzAJBgNVBAgTAkNBMRIwEAYDVQQHEwlQYWxvIEFs
# dG8xKzApBgNVBAoTIkhld2xldHQgUGFja2FyZCBFbnRlcnByaXNlIENvbXBhbnkx
# KzApBgNVBAMTIkhld2xldHQgUGFja2FyZCBFbnRlcnByaXNlIENvbXBhbnkwggEi
# MA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDmIqUOA0ngeoop1HwCROwGSEKR
# SGOZw906vRHsjEkoPbOpnyp17jMjxrUPJG6cWOdXVlZ2ZysfS/H5D3WQO5hrgKV5
# 6etB2FzkrAleCWXj7KDi3KZR/7nX2tDt9lXdD/z1r9nY+fSihMgv3M2pCuRFC00q
# GpPy8+OYNx0kgSWjY1E3p27jIARAxbtt8s5h9nBf5JViycfnSLXMtxoZCvmDfuWZ
# 1LG5bX/2VsRfQAoFSl0AoZV17AOznFi7fy4+3cfVc/2Iy3MZPCAxe1BzJk+MbgyL
# 4KiAhm8h7VFQ10CdXQUHEprd21MoWHo7jt3MTH0dBNiAWQHh8GjfKqKbQdD/AgMB
# AAGjggHxMIIB7TAfBgNVHSMEGDAWgBSP6H7wbTJqAAUjx3CXajqQ/2vq1DAdBgNV
# HQ4EFgQUygudEY7yT3/rSELkxF64dcV28ZswLgYDVR0RBCcwJaAjBggrBgEFBQcI
# A6AXMBUME1VTLURFTEFXQVJFLTU2OTkyNjUwDgYDVR0PAQH/BAQDAgeAMBMGA1Ud
# JQQMMAoGCCsGAQUFBwMDMHsGA1UdHwR0MHIwN6A1oDOGMWh0dHA6Ly9jcmwzLmRp
# Z2ljZXJ0LmNvbS9FVkNvZGVTaWduaW5nU0hBMi1nMS5jcmwwN6A1oDOGMWh0dHA6
# Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9FVkNvZGVTaWduaW5nU0hBMi1nMS5jcmwwSwYD
# VR0gBEQwQjA3BglghkgBhv1sAwIwKjAoBggrBgEFBQcCARYcaHR0cHM6Ly93d3cu
# ZGlnaWNlcnQuY29tL0NQUzAHBgVngQwBAzB+BggrBgEFBQcBAQRyMHAwJAYIKwYB
# BQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBIBggrBgEFBQcwAoY8aHR0
# cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0RVZDb2RlU2lnbmluZ0NB
# LVNIQTIuY3J0MAwGA1UdEwEB/wQCMAAwDQYJKoZIhvcNAQELBQADggEBAIrUTO1b
# hkQ6EPIjfqR0AL38RsVuaye1zZ1qB0OWFWweIduSeDKRksdyeuDI7fQI+rdhO6A5
# t/1ifCQTN/RB7KrD0xF6eRVKKYpKBaEn3UitdH3QD+DAa4oeepBI7icGnA5l+0J+
# wi4REUHMbZjSZiFJaxh4JiYDm4E8W1h/nHwPL4C5dZRTx6oilLSIqeO2zrmxh6v3
# ZWN/Kprw4lAbcB6AZwXUXfDEtejxF0VWWYu8bDmhLNSydb+sPo9xCGGigBNF+0Pv
# OAb9EPn9s4xnADD+zciIpT1A0MHdtHrILDDbR5AZOu2QicYf3KbraFTajZWZZE7g
# D+lcit7JsXq938cwgga8MIIFpKADAgECAhAD8bThXzqC8RSWeLPX2EdcMA0GCSqG
# SIb3DQEBCwUAMGwxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMx
# GTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xKzApBgNVBAMTIkRpZ2lDZXJ0IEhp
# Z2ggQXNzdXJhbmNlIEVWIFJvb3QgQ0EwHhcNMTIwNDE4MTIwMDAwWhcNMjcwNDE4
# MTIwMDAwWjBsMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkw
# FwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSswKQYDVQQDEyJEaWdpQ2VydCBFViBD
# b2RlIFNpZ25pbmcgQ0EgKFNIQTIpMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIB
# CgKCAQEAp1P6D7K1E/Fkz4SA/K6ANdG218ejLKwaLKzxhKw6NRI6kpG6V+TEyfMv
# qEg8t9Zu3JciulF5Ya9DLw23m7RJMa5EWD6koZanh08jfsNsZSSQVT6hyiN8xULp
# xHpiRZt93mN0y55jJfiEmpqtRU+ufR/IE8t1m8nh4Yr4CwyY9Mo+0EWqeh6lWJM2
# NL4rLisxWGa0MhCfnfBSoe/oPtN28kBa3PpqPRtLrXawjFzuNrqD6jCoTN7xCypY
# QYiuAImrA9EWgiAiduteVDgSYuHScCTb7R9w0mQJgC3itp3OH/K7IfNs29izGXuK
# UJ/v7DYKXJq3StMIoDl5/d2/PToJJQIDAQABo4IDWDCCA1QwEgYDVR0TAQH/BAgw
# BgEB/wIBADAOBgNVHQ8BAf8EBAMCAYYwEwYDVR0lBAwwCgYIKwYBBQUHAwMwfwYI
# KwYBBQUHAQEEczBxMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5j
# b20wSQYIKwYBBQUHMAKGPWh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdp
# Q2VydEhpZ2hBc3N1cmFuY2VFVlJvb3RDQS5jcnQwgY8GA1UdHwSBhzCBhDBAoD6g
# PIY6aHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0SGlnaEFzc3VyYW5j
# ZUVWUm9vdENBLmNybDBAoD6gPIY6aHR0cDovL2NybDQuZGlnaWNlcnQuY29tL0Rp
# Z2lDZXJ0SGlnaEFzc3VyYW5jZUVWUm9vdENBLmNybDCCAcQGA1UdIASCAbswggG3
# MIIBswYJYIZIAYb9bAMCMIIBpDA6BggrBgEFBQcCARYuaHR0cDovL3d3dy5kaWdp
# Y2VydC5jb20vc3NsLWNwcy1yZXBvc2l0b3J5Lmh0bTCCAWQGCCsGAQUFBwICMIIB
# Vh6CAVIAQQBuAHkAIAB1AHMAZQAgAG8AZgAgAHQAaABpAHMAIABDAGUAcgB0AGkA
# ZgBpAGMAYQB0AGUAIABjAG8AbgBzAHQAaQB0AHUAdABlAHMAIABhAGMAYwBlAHAA
# dABhAG4AYwBlACAAbwBmACAAdABoAGUAIABEAGkAZwBpAEMAZQByAHQAIABDAFAA
# LwBDAFAAUwAgAGEAbgBkACAAdABoAGUAIABSAGUAbAB5AGkAbgBnACAAUABhAHIA
# dAB5ACAAQQBnAHIAZQBlAG0AZQBuAHQAIAB3AGgAaQBjAGgAIABsAGkAbQBpAHQA
# IABsAGkAYQBiAGkAbABpAHQAeQAgAGEAbgBkACAAYQByAGUAIABpAG4AYwBvAHIA
# cABvAHIAYQB0AGUAZAAgAGgAZQByAGUAaQBuACAAYgB5ACAAcgBlAGYAZQByAGUA
# bgBjAGUALjAdBgNVHQ4EFgQUj+h+8G0yagAFI8dwl2o6kP9r6tQwHwYDVR0jBBgw
# FoAUsT7DaQP4v0cB1JgmGggC72NkK8MwDQYJKoZIhvcNAQELBQADggEBABkzSgyB
# MzfbrTbJ5Mk6u7UbLnqi4vRDQheev06hTeGx2+mB3Z8B8uSI1en+Cf0hwexdgNLw
# 1sFDwv53K9v515EzzmzVshk75i7WyZNPiECOzeH1fvEPxllWcujrakG9HNVG1XxJ
# ymY4FcG/4JFwd4fcyY0xyQwpojPtjeKHzYmNPxv/1eAal4t82m37qMayOmZrewGz
# zdimNOwSAauVWKXEU1eoYObnAhKguSNkok27fIElZCG+z+5CGEOXu6U3Bq9N/yal
# TWFL7EZBuGXOuHmeCJYLgYyKO4/HmYyjKm6YbV5hxpa3irlhLZO46w4EQ9f1/qbw
# YtSZaqXBwfBklIAxggTQMIIEzAIBATCBgDBsMQswCQYDVQQGEwJVUzEVMBMGA1UE
# ChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSswKQYD
# VQQDEyJEaWdpQ2VydCBFViBDb2RlIFNpZ25pbmcgQ0EgKFNIQTIpAhAIjObpfQSZ
# P/8TSh1Rjh8QMA0GCWCGSAFlAwQCAQUAoHwwEAYKKwYBBAGCNwIBDDECMAAwGQYJ
# KoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQB
# gjcCARUwLwYJKoZIhvcNAQkEMSIEIKgVgousnM+4KGK83YIVhKnCiVCxgIr90KnW
# swbmFY4XMA0GCSqGSIb3DQEBAQUABIIBABhctFs79ZZMy1U+9cvweXFV/kKL/TzX
# SguI/ZTgj0mjzRwh0cKGNyoYevesOY0SFW0wt+gplQgyTP+0jT4EuUZVJ6KhPWs1
# wSvVguiQyQRgTJbGxCaffKqJacG+l5WhAlMRAARTydDvLTSKxgdSGDTG3wEczrJ3
# FWSPOB7dEDgPfHVwrR/gAvy9f6PUByDa/Y3ZLPL1yb9mXeczDAYgahXPu0SEfb4J
# 9N4G6xnrDLgT6sZ6KYE+9It+I40bKX2MG3vRLSzxC+0e53Mxoq8hh67DD11t+yYg
# rDCZL4sdVt1dyF48mRywn+2eUNOj7/dn3wazx8YxmflcCCkQkkYklFShggKiMIIC
# ngYJKoZIhvcNAQkGMYICjzCCAosCAQEwaDBSMQswCQYDVQQGEwJCRTEZMBcGA1UE
# ChMQR2xvYmFsU2lnbiBudi1zYTEoMCYGA1UEAxMfR2xvYmFsU2lnbiBUaW1lc3Rh
# bXBpbmcgQ0EgLSBHMgISESHWmadklz7x+EJ+6RnMU0EUMAkGBSsOAwIaBQCggf0w
# GAYJKoZIhvcNAQkDMQsGCSqGSIb3DQEHATAcBgkqhkiG9w0BCQUxDxcNMTkwMTEx
# MTA0NTI4WjAjBgkqhkiG9w0BCQQxFgQUilp8kUxAkZkxyyGjVeptt2KIRSQwgZ0G
# CyqGSIb3DQEJEAIMMYGNMIGKMIGHMIGEBBRjuC+rYfWDkJaVBQsAJJxQKTPseTBs
# MFakVDBSMQswCQYDVQQGEwJCRTEZMBcGA1UEChMQR2xvYmFsU2lnbiBudi1zYTEo
# MCYGA1UEAxMfR2xvYmFsU2lnbiBUaW1lc3RhbXBpbmcgQ0EgLSBHMgISESHWmadk
# lz7x+EJ+6RnMU0EUMA0GCSqGSIb3DQEBAQUABIIBAIMDMReovdXuMDTUYMrfTFEf
# U6MlwdT/sWPAdmBnInkKTkMLylJMT0OWEEZQ+4Tgrdha8zVgFJaLr0uFf6Kx2y87
# e8FTGqP6xvfZeuYCOtwQVi7lwDbaxmY4ujW8+giSUEECRoKocwNnb4kgNIQm1qHV
# QcMwp6PLZkrhpqsLal50V5x96kFZLE32Cd4lCcRaO/xPVD2d6RQMd7EX7pRVDhSC
# nMgtEUFR+StbP6WAEuxb0jYC5wLraFEW9r6c/vQY90kO8wIHsX0lJ4bq0QVLJYu/
# QzmrfXJmEoWNu4C9Q8bHIwU3YEgZO3URICnq9fe7MU8J6tEQoxvUuHL3MXc+T4g=
# SIG # End signature block
