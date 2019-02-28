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
##	File Name:		Logger.psm1
##	Description: 	Common Logger 
##		
##	Created:		June 2015
##	Last Modified:	January 2019
##	History:		v1.0 - Created
##					v2.2 - Added functions to write Exceptions
##	
#####################################################################################

##Split path to get current location
$curPath = Split-Path -Path $MyInvocation.MyCommand.Definition |Split-path  

$pathLogs = join-path $curPath "Logs"
if(-Not (Test-Path $pathLogs) )
{
   try{
	New-Item $pathLogs -Type Directory | Out-Null
	}
	catch
	{
		$global:LogInfo = $false
		Write-Warning "Failed to create Logs Directory $_.Exception.ToString() Log file will not be created."
	}
}
[String]$temp = Get-Date -f s
$timeStamp = $temp.ToString().Replace(":","-")


$timeStampPath = "\Log-{0}.log" -f $timeStamp     
$LogFile = ($pathLogs + $timeStampPath)

$timeStampPath = "\DebugLog-{0}.log" -f $timeStamp     
$dbgLogFile = ($pathLogs + $timeStampPath) 

$timeStampPath = "\Result-{0}.txt" -f $timeStamp     
$resultFile = ($pathLogs + $timeStampPath)

############################################################################################################################################
## FUNCTION WRITE-EXCEPTION
############################################################################################################################################
Function Write-Exception 
{
<#
  .SYNOPSIS
    Logs exception message to a log file under Logs directory.
  
  .DESCRIPTION
	 Logs exception message to a log file under Logs directory. This directory is directory one level above of the current executing 
	 path of the module.
        
  .EXAMPLE
    Write-Exception -TextLog "Exception Occured"
    
  .PARAMETER TextLog 
    Specify the exception message
	
  .PARAMETER Error 
    Specify the switch -error to indicate it as Error: 
	
   .PARAMETER Warn 
    Specify the switch -warn to indicate it as Warning: 
            
  .Notes
    NAME:  Write-Exception    
    LASTEDIT: 05/15/2012
    KEYWORDS: Write-Exception
   
  .Link
     Http://www.hp.com
 
 #Requires PS -Version 2.0
 
 #>
	[cmdletbinding()]
	Param
	(
	    [parameter(mandatory = $true)]    
	    $TextLog,	    	   
	    [parameter(mandatory = $False)]
	    [Switch]
	    $Error,
	    [parameter(mandatory = $False)]
	    [Switch]
	    $Warn
	 )     
    
    if ($TextLog.GetType.Name -eq "Hashtable")
    {
      $TextLog.GetEnumerator() | Sort-Object Name | foreach-object {Write-Output "{0},{1}" -f $_.Name,$_.Value | Out-File $LogFile -Append}
                        
    }elseif($TextLog.GetType.Name -eq "Object[]")
    {
        $TextLog.GetEnumerator() | Sort-Object Name | foreach-object {Write-Output $_ | Out-File $LogFile -Append}
    
    }elseif($TextLog -is [Array])
    {
        $TextLog.GetEnumerator() | Sort-Object Name | foreach-object {Write-Output $_ | Out-File $LogFile -Append}
    }
    else
    {			       
        if ($Error)
        {
            Write-Error $TextLog
        }
        if ($Warn)
        {
            Write-Warning $TextLog
        }       
    }
	
	# Write to debug log file the error message if debug log is set to true
	$strLog = "Error :" + $TextLog
	Write-LogFile -TextLog $strLog
}

############################################################################################################################################
## FUNCTION WRITE-LOGFILE
############################################################################################################################################
Function Write-LogFile 
{
<#
  .SYNOPSIS
    Logs general debug messages to a log file under Logs directory. This is internal method not exposed to public.
  
  .DESCRIPTION
	 Logs general debug messages to a log file under Logs directory. This directory is directory one level above of the current executing 
	 path of the module.
        
  .EXAMPLE
    Write-LogFile -TextLog "My Debugging message"
    
  .PARAMETER TextLog 
    Specify the exception message
            
  .Notes
    NAME:  Write-LogFile    
    LASTEDIT: 05/15/2012
    KEYWORDS: Write-LogFile
   
  .Link
     Http://www.hp.com
 
 #Requires PS -Version 2.0
 
 #>
	[cmdletbinding()]
	Param
	(
	    [parameter(Position=0, mandatory = $true)]   
	    $TextLog
		
		#[parameter(Position=1 ,mandatory = $true)]		
	    #$LogDebugInfo
	 )

	# Sometimes Logs folder is not getting created in a scenario where the modules are imported and then the Logs folder is deleted by the user.
	# Just to make sure we have the folder created, doing this check again.
	if(-Not (Test-Path $pathLogs) )
    {       
	   try{
		New-Item $pathLogs -Type Directory | Out-Null
		}
		catch
		{
			$global:LogInfo = $false
			Write-Warning "Failed to create Logs Directory $_.Exception.ToString() Log file will not be created."
		}		
    }
	
	if($global:LogInfo)
	{
	   Write-Output "$(Get-Date) $TextLog" | Out-File $dbgLogFile -Append       
	          
	} 
}
############################################################################################################################################
## FUNCTION WRITE-DEBUGLOG
############################################################################################################################################

Function Write-DebugLog
{
<#
  .SYNOPSIS
    Logs general debug messages to a console and also to a log file if Set-DebugLog is set to $true. See Set-DebugLog for more info.
  
  .DESCRIPTION
	 Logs general debug messages to a console and also to a log file if Set-DebugLog is set to $true. See Set-DebugLog for more info. Log directory is created
	 which is one level above of the current executing path of the module.
        
  .EXAMPLE
    Write-DebugLog -TextLog "My Debugging message" -MessageType "INFO:"
	MessageType can take values "INFO:" , "ERR:" , "WARN:" , "DEBUG:" , "OTH:". Message type is case sensitive and must match 
	as seen in the expected values.
    
  .PARAMETER TextLog 
    Specify the exception message
           
  .PARAMETER MsssageType
    Specify the type of message. MessageType can take values "INFO:" , "ERR:" , "WARN:" , "DEBUG:" , "OTH:". Message type is case sensitive and must match 
	as seen in the expected values.
	
  .Notes
    NAME:  Write-DebugLog    
    LASTEDIT: 05/15/2012
    KEYWORDS: Write-DebugLog
   
  .Link
     Http://www.hp.com
 
 #Requires PS -Version 2.0
 
 #>
	
	[cmdletbinding()]
	Param
	(
	    [parameter(Position=0, mandatory = $true)]
	    [System.String]
	    $Message,
		[parameter(Position=1, mandatory = $false)]
	    [System.String]
	    $MessageType     
	 )

	#User Preference if he wants to see the display on PS console. User can swith the Display on/off by calling Set-DebugInfo $true $true.
	# Display is disabled by default. 
	$datetimeMessage = "$(Get-Date) " + $Message
	if ($global:DisplayInfo)	{
	
		If ($MessageType -match "ERR:") {
		   # write-host $datetimeMessage -ForegroundColor RED
		} elseIf ($MessageType -match "WARN:") {
		    #write-host $datetimeMessage -ForegroundColor DARKYELLOW 
		} elseIf ($MessageType -match "WARNING:") {
		    #write-host $datetimeMessage -ForegroundColor DARKYELLOW 
		} elseIf ($MessageType -match "INFO:") {
		    #write-host $datetimeMessage -ForegroundColor DARKGRAY 
		} elseIf ($MessageType -match "DEBUG:") {
		    #write-host $datetimeMessage -ForegroundColor DARKGREEN 
			# dont write any DEBUG messages on the console. Let them only be written in the log file.
		} elseIf ($MessageType -match "OTH:") {
		   #write-host $datetimeMessage -ForegroundColor BLACK 
		} Else {
		    #write-host $datetimeMessage
		}
	}
	
	
	# Write to the debug log file the error message if  Set-DebugLog is set to true
	$LogMessage = $MessageType + " " + $Message
	Write-LogFile -TextLog $LogMessage
	
}

Export-ModuleMember Write-DebugLog , Write-Exception


# SIG # Begin signature block
# MIIfUgYJKoZIhvcNAQcCoIIfQzCCHz8CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCSOjwbo0loKU8W
# 6lEs34kN6lck3N98XQNVDLf8rI+RoKCCGm8wggPuMIIDV6ADAgECAhB+k+v7fMZO
# WepLmnfUBvw7MA0GCSqGSIb3DQEBBQUAMIGLMQswCQYDVQQGEwJaQTEVMBMGA1UE
# CBMMV2VzdGVybiBDYXBlMRQwEgYDVQQHEwtEdXJiYW52aWxsZTEPMA0GA1UEChMG
# VGhhd3RlMR0wGwYDVQQLExRUaGF3dGUgQ2VydGlmaWNhdGlvbjEfMB0GA1UEAxMW
# VGhhd3RlIFRpbWVzdGFtcGluZyBDQTAeFw0xMjEyMjEwMDAwMDBaFw0yMDEyMzAy
# MzU5NTlaMF4xCzAJBgNVBAYTAlVTMR0wGwYDVQQKExRTeW1hbnRlYyBDb3Jwb3Jh
# dGlvbjEwMC4GA1UEAxMnU3ltYW50ZWMgVGltZSBTdGFtcGluZyBTZXJ2aWNlcyBD
# QSAtIEcyMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAsayzSVRLlxwS
# CtgleZEiVypv3LgmxENza8K/LlBa+xTCdo5DASVDtKHiRfTot3vDdMwi17SUAAL3
# Te2/tLdEJGvNX0U70UTOQxJzF4KLabQry5kerHIbJk1xH7Ex3ftRYQJTpqr1SSwF
# eEWlL4nO55nn/oziVz89xpLcSvh7M+R5CvvwdYhBnP/FA1GZqtdsn5Nph2Upg4XC
# YBTEyMk7FNrAgfAfDXTekiKryvf7dHwn5vdKG3+nw54trorqpuaqJxZ9YfeYcRG8
# 4lChS+Vd+uUOpyyfqmUg09iW6Mh8pU5IRP8Z4kQHkgvXaISAXWp4ZEXNYEZ+VMET
# fMV58cnBcQIDAQABo4H6MIH3MB0GA1UdDgQWBBRfmvVuXMzMdJrU3X3vP9vsTIAu
# 3TAyBggrBgEFBQcBAQQmMCQwIgYIKwYBBQUHMAGGFmh0dHA6Ly9vY3NwLnRoYXd0
# ZS5jb20wEgYDVR0TAQH/BAgwBgEB/wIBADA/BgNVHR8EODA2MDSgMqAwhi5odHRw
# Oi8vY3JsLnRoYXd0ZS5jb20vVGhhd3RlVGltZXN0YW1waW5nQ0EuY3JsMBMGA1Ud
# JQQMMAoGCCsGAQUFBwMIMA4GA1UdDwEB/wQEAwIBBjAoBgNVHREEITAfpB0wGzEZ
# MBcGA1UEAxMQVGltZVN0YW1wLTIwNDgtMTANBgkqhkiG9w0BAQUFAAOBgQADCZuP
# ee9/WTCq72i1+uMJHbtPggZdN1+mUp8WjeockglEbvVt61h8MOj5aY0jcwsSb0ep
# rjkR+Cqxm7Aaw47rWZYArc4MTbLQMaYIXCp6/OJ6HVdMqGUY6XlAYiWWbsfHN2qD
# IQiOQerd2Vc/HXdJhyoWBl6mOGoiEqNRGYN+tjCCBKMwggOLoAMCAQICEA7P9DjI
# /r81bgTYapgbGlAwDQYJKoZIhvcNAQEFBQAwXjELMAkGA1UEBhMCVVMxHTAbBgNV
# BAoTFFN5bWFudGVjIENvcnBvcmF0aW9uMTAwLgYDVQQDEydTeW1hbnRlYyBUaW1l
# IFN0YW1waW5nIFNlcnZpY2VzIENBIC0gRzIwHhcNMTIxMDE4MDAwMDAwWhcNMjAx
# MjI5MjM1OTU5WjBiMQswCQYDVQQGEwJVUzEdMBsGA1UEChMUU3ltYW50ZWMgQ29y
# cG9yYXRpb24xNDAyBgNVBAMTK1N5bWFudGVjIFRpbWUgU3RhbXBpbmcgU2Vydmlj
# ZXMgU2lnbmVyIC0gRzQwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCi
# Yws5RLi7I6dESbsO/6HwYQpTk7CY260sD0rFbv+GPFNVDxXOBD8r/amWltm+YXkL
# W8lMhnbl4ENLIpXuwitDwZ/YaLSOQE/uhTi5EcUj8mRY8BUyb05Xoa6IpALXKh7N
# S+HdY9UXiTJbsF6ZWqidKFAOF+6W22E7RVEdzxJWC5JH/Kuu9mY9R6xwcueS51/N
# ELnEg2SUGb0lgOHo0iKl0LoCeqF3k1tlw+4XdLxBhircCEyMkoyRLZ53RB9o1qh0
# d9sOWzKLVoszvdljyEmdOsXF6jML0vGjG/SLvtmzV4s73gSneiKyJK4ux3DFvk6D
# Jgj7C72pT5kI4RAocqrNAgMBAAGjggFXMIIBUzAMBgNVHRMBAf8EAjAAMBYGA1Ud
# JQEB/wQMMAoGCCsGAQUFBwMIMA4GA1UdDwEB/wQEAwIHgDBzBggrBgEFBQcBAQRn
# MGUwKgYIKwYBBQUHMAGGHmh0dHA6Ly90cy1vY3NwLndzLnN5bWFudGVjLmNvbTA3
# BggrBgEFBQcwAoYraHR0cDovL3RzLWFpYS53cy5zeW1hbnRlYy5jb20vdHNzLWNh
# LWcyLmNlcjA8BgNVHR8ENTAzMDGgL6AthitodHRwOi8vdHMtY3JsLndzLnN5bWFu
# dGVjLmNvbS90c3MtY2EtZzIuY3JsMCgGA1UdEQQhMB+kHTAbMRkwFwYDVQQDExBU
# aW1lU3RhbXAtMjA0OC0yMB0GA1UdDgQWBBRGxmmjDkoUHtVM2lJjFz9eNrwN5jAf
# BgNVHSMEGDAWgBRfmvVuXMzMdJrU3X3vP9vsTIAu3TANBgkqhkiG9w0BAQUFAAOC
# AQEAeDu0kSoATPCPYjA3eKOEJwdvGLLeJdyg1JQDqoZOJZ+aQAMc3c7jecshaAba
# tjK0bb/0LCZjM+RJZG0N5sNnDvcFpDVsfIkWxumy37Lp3SDGcQ/NlXTctlzevTcf
# Q3jmeLXNKAQgo6rxS8SIKZEOgNER/N1cdm5PXg5FRkFuDbDqOJqxOtoJcRD8HHm0
# gHusafT9nLYMFivxf1sJPZtb4hbKE4FtAC44DagpjyzhsvRaqQGvFZwsL0kb2yK7
# w/54lFHDhrGCiF3wPbRRoXkzKy57udwgCRNx62oZW8/opTBXLIlJP7nPf8m/PiJo
# Y1OavWl0rMUdPH+S4MO8HNgEdTCCBTswggMjoAMCAQICCmEgTbQAAAAAACcwDQYJ
# KoZIhvcNAQEFBQAwfzELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24x
# EDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlv
# bjEpMCcGA1UEAxMgTWljcm9zb2Z0IENvZGUgVmVyaWZpY2F0aW9uIFJvb3QwHhcN
# MTEwNDE1MTk0NTMzWhcNMjEwNDE1MTk1NTMzWjBsMQswCQYDVQQGEwJVUzEVMBMG
# A1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSsw
# KQYDVQQDEyJEaWdpQ2VydCBIaWdoIEFzc3VyYW5jZSBFViBSb290IENBMIIBIjAN
# BgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAxszlc+b71LvlLS0ypt/lgT/JzSVJ
# tnEqw9WUNGeiChywX2mmQLHEt7KP0JikqUFZOtPclNY823Q4pErMTSWC90qlUxI4
# 7vNJbXGRfmO2q6Zfw6SE+E9iUb74xezbOJLjBuUIkQzEKEFV+8taiRV+ceg1v01y
# CT2+OjhQW3cxG42zxyRFmqesbQAUWgS3uhPrUQqYQUEiTmVhh4FBUKZ5XIneGUpX
# 1S7mXRxTLH6YzRoGFqRoc9A0BBNcoXHTWnxV215k4TeHMFYE5RG0KYAS8Xk5iKIC
# EXwnZreIt3jyygqoOKsKZMK/Zl2VhMGhJR6HXRpQCyASzEG7bgtROLhLywIDAQAB
# o4HLMIHIMBEGA1UdIAQKMAgwBgYEVR0gADALBgNVHQ8EBAMCAYYwDwYDVR0TAQH/
# BAUwAwEB/zAdBgNVHQ4EFgQUsT7DaQP4v0cB1JgmGggC72NkK8MwHwYDVR0jBBgw
# FoAUYvsKIVt/Q24R2glUUGv10pZx8Z4wVQYDVR0fBE4wTDBKoEigRoZEaHR0cDov
# L2NybC5taWNyb3NvZnQuY29tL3BraS9jcmwvcHJvZHVjdHMvTWljcm9zb2Z0Q29k
# ZVZlcmlmUm9vdC5jcmwwDQYJKoZIhvcNAQEFBQADggIBACCMwVntb5xrLcFKPnUd
# RUxBUBy9gOrZsJKLBioTP1MWnlY5aopjtngkefV9uLlHoQqWwvbLvaJmnwbhrNJ5
# CQ79PNysAgxwrz8b7Hh+1OtLBWAm2XNhkSHtsGhj4JcSq2+gEu3Zn9LaJzyz5Fb5
# 0dSBD3G9QnymidzN1b2VoqvxkxF96KwxKahdZnBBnfx1ydWzGjkq0IUFUIuskcrE
# k8txpZ2klG9YDPpuIMQIMbWFnX6B+dI9ylsYhWwKhuwiCRuldDRPfyi8lUqrHbaY
# sF0JpHd2fu+njl2E9hgky9FtpsOhnMIQdYD/nTL95s9DOoL3zo/hciqbYrdf7ZUa
# OVwvlG1ItwFfMy+73C1zNIkEQgoci3n5o/oX7/qhGhDf4LLBletcDAWXOzU+GIhN
# 22y/JImNyL3Yn3s5OiSg1d/R80oal/amb3ofsJCps6wBOZHTYbdk8T5XOAOvznrS
# tZD1rtw5mdW2PJftpssWx31rKkyQlOZMVP0ezSDszmich1jpYWC+6w7J1Rl9n+l4
# vQ6sIXUHj6lu4IxqKmuc4+dlvLwtPG3cBNxnRTYyrwSBvKgAbmFMlcVc1I6Ony/B
# MnS9vRFlAwfN77deAlfahtQaKDSviEmyz6XdglZvaKoU4llU/v/q7u/qknAiYIHj
# JSPAn8wPSbI1qljDOsPZFpQQMIIF0zCCBLugAwIBAgIQCIzm6X0EmT//E0odUY4f
# EDANBgkqhkiG9w0BAQsFADBsMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNl
# cnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSswKQYDVQQDEyJEaWdp
# Q2VydCBFViBDb2RlIFNpZ25pbmcgQ0EgKFNIQTIpMB4XDTE4MDkxMzAwMDAwMFoX
# DTE5MDkxODEyMDAwMFowgekxEzARBgsrBgEEAYI3PAIBAxMCVVMxGTAXBgsrBgEE
# AYI3PAIBAhMIRGVsYXdhcmUxHTAbBgNVBA8MFFByaXZhdGUgT3JnYW5pemF0aW9u
# MRAwDgYDVQQFEwc1Njk5MjY1MQswCQYDVQQGEwJVUzELMAkGA1UECBMCQ0ExEjAQ
# BgNVBAcTCVBhbG8gQWx0bzErMCkGA1UEChMiSGV3bGV0dCBQYWNrYXJkIEVudGVy
# cHJpc2UgQ29tcGFueTErMCkGA1UEAxMiSGV3bGV0dCBQYWNrYXJkIEVudGVycHJp
# c2UgQ29tcGFueTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAOYipQ4D
# SeB6iinUfAJE7AZIQpFIY5nD3Tq9EeyMSSg9s6mfKnXuMyPGtQ8kbpxY51dWVnZn
# Kx9L8fkPdZA7mGuApXnp60HYXOSsCV4JZePsoOLcplH/udfa0O32Vd0P/PWv2dj5
# 9KKEyC/czakK5EULTSoak/Lz45g3HSSBJaNjUTenbuMgBEDFu23yzmH2cF/klWLJ
# x+dItcy3GhkK+YN+5ZnUsbltf/ZWxF9ACgVKXQChlXXsA7OcWLt/Lj7dx9Vz/YjL
# cxk8IDF7UHMmT4xuDIvgqICGbyHtUVDXQJ1dBQcSmt3bUyhYejuO3cxMfR0E2IBZ
# AeHwaN8qoptB0P8CAwEAAaOCAfEwggHtMB8GA1UdIwQYMBaAFI/ofvBtMmoABSPH
# cJdqOpD/a+rUMB0GA1UdDgQWBBTKC50RjvJPf+tIQuTEXrh1xXbxmzAuBgNVHREE
# JzAloCMGCCsGAQUFBwgDoBcwFQwTVVMtREVMQVdBUkUtNTY5OTI2NTAOBgNVHQ8B
# Af8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwewYDVR0fBHQwcjA3oDWgM4Yx
# aHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0VWQ29kZVNpZ25pbmdTSEEyLWcxLmNy
# bDA3oDWgM4YxaHR0cDovL2NybDQuZGlnaWNlcnQuY29tL0VWQ29kZVNpZ25pbmdT
# SEEyLWcxLmNybDBLBgNVHSAERDBCMDcGCWCGSAGG/WwDAjAqMCgGCCsGAQUFBwIB
# FhxodHRwczovL3d3dy5kaWdpY2VydC5jb20vQ1BTMAcGBWeBDAEDMH4GCCsGAQUF
# BwEBBHIwcDAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMEgG
# CCsGAQUFBzAChjxodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRF
# VkNvZGVTaWduaW5nQ0EtU0hBMi5jcnQwDAYDVR0TAQH/BAIwADANBgkqhkiG9w0B
# AQsFAAOCAQEAitRM7VuGRDoQ8iN+pHQAvfxGxW5rJ7XNnWoHQ5YVbB4h25J4MpGS
# x3J64Mjt9Aj6t2E7oDm3/WJ8JBM39EHsqsPTEXp5FUopikoFoSfdSK10fdAP4MBr
# ih56kEjuJwacDmX7Qn7CLhERQcxtmNJmIUlrGHgmJgObgTxbWH+cfA8vgLl1lFPH
# qiKUtIip47bOubGHq/dlY38qmvDiUBtwHoBnBdRd8MS16PEXRVZZi7xsOaEs1LJ1
# v6w+j3EIYaKAE0X7Q+84Bv0Q+f2zjGcAMP7NyIilPUDQwd20esgsMNtHkBk67ZCJ
# xh/cputoVNqNlZlkTuAP6VyK3smxer3fxzCCBrwwggWkoAMCAQICEAPxtOFfOoLx
# FJZ4s9fYR1wwDQYJKoZIhvcNAQELBQAwbDELMAkGA1UEBhMCVVMxFTATBgNVBAoT
# DERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTErMCkGA1UE
# AxMiRGlnaUNlcnQgSGlnaCBBc3N1cmFuY2UgRVYgUm9vdCBDQTAeFw0xMjA0MTgx
# MjAwMDBaFw0yNzA0MTgxMjAwMDBaMGwxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxE
# aWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xKzApBgNVBAMT
# IkRpZ2lDZXJ0IEVWIENvZGUgU2lnbmluZyBDQSAoU0hBMikwggEiMA0GCSqGSIb3
# DQEBAQUAA4IBDwAwggEKAoIBAQCnU/oPsrUT8WTPhID8roA10bbXx6MsrBosrPGE
# rDo1EjqSkbpX5MTJ8y+oSDy31m7clyK6UXlhr0MvDbebtEkxrkRYPqShlqeHTyN+
# w2xlJJBVPqHKI3zFQunEemJFm33eY3TLnmMl+ISamq1FT659H8gTy3WbyeHhivgL
# DJj0yj7QRap6HqVYkzY0visuKzFYZrQyEJ+d8FKh7+g+03byQFrc+mo9G0utdrCM
# XO42uoPqMKhM3vELKlhBiK4AiasD0RaCICJ2615UOBJi4dJwJNvtH3DSZAmALeK2
# nc4f8rsh82zb2LMZe4pQn+/sNgpcmrdK0wigOXn93b89OgklAgMBAAGjggNYMIID
# VDASBgNVHRMBAf8ECDAGAQH/AgEAMA4GA1UdDwEB/wQEAwIBhjATBgNVHSUEDDAK
# BggrBgEFBQcDAzB/BggrBgEFBQcBAQRzMHEwJAYIKwYBBQUHMAGGGGh0dHA6Ly9v
# Y3NwLmRpZ2ljZXJ0LmNvbTBJBggrBgEFBQcwAoY9aHR0cDovL2NhY2VydHMuZGln
# aWNlcnQuY29tL0RpZ2lDZXJ0SGlnaEFzc3VyYW5jZUVWUm9vdENBLmNydDCBjwYD
# VR0fBIGHMIGEMECgPqA8hjpodHRwOi8vY3JsMy5kaWdpY2VydC5jb20vRGlnaUNl
# cnRIaWdoQXNzdXJhbmNlRVZSb290Q0EuY3JsMECgPqA8hjpodHRwOi8vY3JsNC5k
# aWdpY2VydC5jb20vRGlnaUNlcnRIaWdoQXNzdXJhbmNlRVZSb290Q0EuY3JsMIIB
# xAYDVR0gBIIBuzCCAbcwggGzBglghkgBhv1sAwIwggGkMDoGCCsGAQUFBwIBFi5o
# dHRwOi8vd3d3LmRpZ2ljZXJ0LmNvbS9zc2wtY3BzLXJlcG9zaXRvcnkuaHRtMIIB
# ZAYIKwYBBQUHAgIwggFWHoIBUgBBAG4AeQAgAHUAcwBlACAAbwBmACAAdABoAGkA
# cwAgAEMAZQByAHQAaQBmAGkAYwBhAHQAZQAgAGMAbwBuAHMAdABpAHQAdQB0AGUA
# cwAgAGEAYwBjAGUAcAB0AGEAbgBjAGUAIABvAGYAIAB0AGgAZQAgAEQAaQBnAGkA
# QwBlAHIAdAAgAEMAUAAvAEMAUABTACAAYQBuAGQAIAB0AGgAZQAgAFIAZQBsAHkA
# aQBuAGcAIABQAGEAcgB0AHkAIABBAGcAcgBlAGUAbQBlAG4AdAAgAHcAaABpAGMA
# aAAgAGwAaQBtAGkAdAAgAGwAaQBhAGIAaQBsAGkAdAB5ACAAYQBuAGQAIABhAHIA
# ZQAgAGkAbgBjAG8AcgBwAG8AcgBhAHQAZQBkACAAaABlAHIAZQBpAG4AIABiAHkA
# IAByAGUAZgBlAHIAZQBuAGMAZQAuMB0GA1UdDgQWBBSP6H7wbTJqAAUjx3CXajqQ
# /2vq1DAfBgNVHSMEGDAWgBSxPsNpA/i/RwHUmCYaCALvY2QrwzANBgkqhkiG9w0B
# AQsFAAOCAQEAGTNKDIEzN9utNsnkyTq7tRsueqLi9ENCF56/TqFN4bHb6YHdnwHy
# 5IjV6f4J/SHB7F2A0vDWwUPC/ncr2/nXkTPObNWyGTvmLtbJk0+IQI7N4fV+8Q/G
# WVZy6OtqQb0c1UbVfEnKZjgVwb/gkXB3h9zJjTHJDCmiM+2N4ofNiY0/G//V4BqX
# i3zabfuoxrI6Zmt7AbPN2KY07BIBq5VYpcRTV6hg5ucCEqC5I2SiTbt8gSVkIb7P
# 7kIYQ5e7pTcGr03/JqVNYUvsRkG4Zc64eZ4IlguBjIo7j8eZjKMqbphtXmHGlreK
# uWEtk7jrDgRD1/X+pvBi1JlqpcHB8GSUgDGCBDkwggQ1AgEBMIGAMGwxCzAJBgNV
# BAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdp
# Y2VydC5jb20xKzApBgNVBAMTIkRpZ2lDZXJ0IEVWIENvZGUgU2lnbmluZyBDQSAo
# U0hBMikCEAiM5ul9BJk//xNKHVGOHxAwDQYJYIZIAWUDBAIBBQCgfDAQBgorBgEE
# AYI3AgEMMQIwADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3
# AgELMQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQgIKrYIexBSspOosVf
# vIl/InjeevM4IUugcGXEDmr3V6gwDQYJKoZIhvcNAQEBBQAEggEA3/YIS605F1uO
# SMTC7/K0crn2fJ9ni3Ijk7bHi2teyLNAGw+DB/J3tAJvzDfpEfYYokfFMZy2yPq7
# yyXSS9ybiK4n38nHkeHe2pGcIvBNUUFAOIB9YmbuTbXpGdxIuRT/4gizjtfZNwem
# 9T/pVymKrcKtNuDvWcesEgQNu9c0jQ2aZbmAfajCwNnL+xyFvIp/EMAl1gPlp2YK
# SHiPB9YkJhpKcKA+Qpoysi/sTirLmHA7ZoAHkplBG8+p0l+o8kul2xgqDow0tM8+
# 51y4jXTlWAn5sjJgrh67PAPN6ksWUih+cEqR8QeoCVP2pv/Ir1JEyawRFvMi3kLN
# lIqcgUgEq6GCAgswggIHBgkqhkiG9w0BCQYxggH4MIIB9AIBATByMF4xCzAJBgNV
# BAYTAlVTMR0wGwYDVQQKExRTeW1hbnRlYyBDb3Jwb3JhdGlvbjEwMC4GA1UEAxMn
# U3ltYW50ZWMgVGltZSBTdGFtcGluZyBTZXJ2aWNlcyBDQSAtIEcyAhAOz/Q4yP6/
# NW4E2GqYGxpQMAkGBSsOAwIaBQCgXTAYBgkqhkiG9w0BCQMxCwYJKoZIhvcNAQcB
# MBwGCSqGSIb3DQEJBTEPFw0xOTAxMjEwNzI3MzhaMCMGCSqGSIb3DQEJBDEWBBR4
# juy7E7dvPE3XrH9hlTfye+4ZsTANBgkqhkiG9w0BAQEFAASCAQA9eBIFlxxXyjhR
# 5+veWj2Wdj7V+twUoprEAKeJsklCDgO9xTjosmV7j/vbNRA+gbJzVWne8IRCaqKk
# gq9CNp1LmoiM+tHSYeJALzZNFuwIqcThasHHdkc3cpdTXzx9hxRTIwEwp2R/0IBX
# x3Ya2Ujs8Xamo6QAXtZAjPCNoM+PgQsqJjfLhcW3Kez+2SL6phmdU0Qi5uaeWS9p
# U3+MIftrJxhOPS4CqPeFDm2oIHGT5aIU2x00Sk7CyZLrXlvU1SOUjlcsSnJo1+8v
# b/v4HSYlHLS44Jf31TQa3Wzwx7hJvEY1NSe28eHKukdaniESYQ8bg5TTV0NwnNfk
# 1zCn3GdL
# SIG # End signature block
