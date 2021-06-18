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

$global:LogInfo = $true
$global:DisplayInfo = $true

if(!$global:VSVersion)
{
	$global:VSVersion = "v3.0"
}

if(!$global:ConfigDir) 
{
	$global:ConfigDir = $null 
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$curPath = Split-Path -Path $MyInvocation.MyCommand.Definition |Split-path  

$pathLogs = join-path $curPath "X-Logs"
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
     http://www.hpe.com
 
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
     http://www.hpe.com
 
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
     http://www.hpe.com
 
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
# MIIlhQYJKoZIhvcNAQcCoIIldjCCJXICAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCcL9UBDsPP1xgi
# pJQAfhIGrCdLiXV0dL0a+fE0WydrXaCCFikwggVMMIIDNKADAgECAhMzAAAANdjV
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
# U9Tg46LC0lsa+jImLWpXcBw8pFguo/NbSwfcMlnzh6cabVgxgg6yMIIOrgIBATCB
# kDB8MQswCQYDVQQGEwJHQjEbMBkGA1UECBMSR3JlYXRlciBNYW5jaGVzdGVyMRAw
# DgYDVQQHEwdTYWxmb3JkMRgwFgYDVQQKEw9TZWN0aWdvIExpbWl0ZWQxJDAiBgNV
# BAMTG1NlY3RpZ28gUlNBIENvZGUgU2lnbmluZyBDQQIQJl6ULMWyOufq8fQJzRxR
# /TANBglghkgBZQMEAgEFAKB8MBAGCisGAQQBgjcCAQwxAjAAMBkGCSqGSIb3DQEJ
# AzEMBgorBgEEAYI3AgEEMBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMC8G
# CSqGSIb3DQEJBDEiBCBbqvxr5wSKzUWiQSdwySuI1e/tmJlpCJqAZYG2fok2sjAN
# BgkqhkiG9w0BAQEFAASCAQCaqtZFpHP1dbfZ7EsgPik51UwiYETSTC9UOTY8//GB
# OcdQyt03iV1FBko0tiX3TE8L3uXLwv2O1nJQykK5/C19zlNzGEiRzyP45ixCqaEd
# oxh282vf5gDvyoAF6jWCHnd3bG2gg8emIWpvFADzQHnw6HM87GeHAuwCeS067qCB
# y6DK1vgjGOskV6u3RRV0IRdDHLoqY1R353zk8R3iSBPV+QM6A+ztfUvS0Cmv0tOF
# zQUtzUYQgYXI+GeAEIj6W/78zkkQmDFTpowjpGb9w7k2tn10zTuLaoKMq2RMv1+d
# Y0QTw5NxCgDR+CPlP5U++bxyYHGetPDbSwibG7opIflHoYIMdDCCDHAGCisGAQQB
# gjcDAwExggxgMIIMXAYJKoZIhvcNAQcCoIIMTTCCDEkCAQMxDzANBglghkgBZQME
# AgEFADCBrwYLKoZIhvcNAQkQAQSggZ8EgZwwgZkCAQEGCSsGAQQBoDICAzAxMA0G
# CWCGSAFlAwQCAQUABCDVHbx8dkPP0waPRJgVumjwxOZsvQGAbjX1Wygh2osjPQIU
# SyksYWofR8YsiaZhhRdR0eXlqT8YDzIwMTkwODIyMTA1NDAwWqAvpC0wKzEpMCcG
# A1UEAwwgR2xvYmFsU2lnbiBUU0EgZm9yIEFkdmFuY2VkIC0gRzKgggjTMIIEtjCC
# A56gAwIBAgIMDKfPXQcHJKyJ55o6MA0GCSqGSIb3DQEBCwUAMFsxCzAJBgNVBAYT
# AkJFMRkwFwYDVQQKExBHbG9iYWxTaWduIG52LXNhMTEwLwYDVQQDEyhHbG9iYWxT
# aWduIFRpbWVzdGFtcGluZyBDQSAtIFNIQTI1NiAtIEcyMB4XDTE4MDIxOTAwMDAw
# MFoXDTI5MDMxODEwMDAwMFowKzEpMCcGA1UEAwwgR2xvYmFsU2lnbiBUU0EgZm9y
# IEFkdmFuY2VkIC0gRzIwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQC3
# x5KKKNjzkctQDV3rKUTBglmlymTOvYO1UeWUzG6Amhds3P9i5jZDXgHCDGSNynee
# 9l13RbleyCTrQTcRZjesyM10m8yz70zifxvOc77Jlp01Hnz3VPds7KAS1q6ZnWPE
# eF9ZqS4i9cMn2LJbRWMnkP+MsT2ptPMOwPEgZQaJnQMco7BSQYU067zLzlT2Ev6z
# AYlKpvpUxR/70xzA47+X4z/QG/lAxxvV6yZ8QzDHcPJ4EaqFTqUODQBKOhF3o8oj
# AYCeyJNWXUbMitjSqgqEhbKJW9UyzkF7GE5UyqvRUl4S0ySeVvMMj929ko551UGJ
# w6Og5ZH8x2edhzPOcTJzAgMBAAGjggGoMIIBpDAOBgNVHQ8BAf8EBAMCB4AwTAYD
# VR0gBEUwQzBBBgkrBgEEAaAyAR4wNDAyBggrBgEFBQcCARYmaHR0cHM6Ly93d3cu
# Z2xvYmFsc2lnbi5jb20vcmVwb3NpdG9yeS8wCQYDVR0TBAIwADAWBgNVHSUBAf8E
# DDAKBggrBgEFBQcDCDBGBgNVHR8EPzA9MDugOaA3hjVodHRwOi8vY3JsLmdsb2Jh
# bHNpZ24uY29tL2dzL2dzdGltZXN0YW1waW5nc2hhMmcyLmNybDCBmAYIKwYBBQUH
# AQEEgYswgYgwSAYIKwYBBQUHMAKGPGh0dHA6Ly9zZWN1cmUuZ2xvYmFsc2lnbi5j
# b20vY2FjZXJ0L2dzdGltZXN0YW1waW5nc2hhMmcyLmNydDA8BggrBgEFBQcwAYYw
# aHR0cDovL29jc3AyLmdsb2JhbHNpZ24uY29tL2dzdGltZXN0YW1waW5nc2hhMmcy
# MB0GA1UdDgQWBBQtbm7RjeUDgO7nY+mn2doLPFciPTAfBgNVHSMEGDAWgBSSIadK
# lV1ksJu0HuYAN0fmnUErTDANBgkqhkiG9w0BAQsFAAOCAQEAjf0dH4+I02X4tVxG
# 6afTtj9Ky0MFwgcNw14DhCM3qHqMlyP/J5yEfWHrXEtXPpv0RNuAWPe2Zd6PEgpf
# p4d0t9oUQIdR7J9KR1XwF+gYPnEgMeYoIqtO9q6ca8LnRPtoDSB/Uz+UG6GGgk4y
# FhBaP4lYwdC027aQ+40y6aFLRlA3tsM66SkkEpJaTiu5tgp6NoyXwO+JfDPeMeGh
# l+TnRa1hUv1aidNUfopNW4l7DpZ30fI8OBva+aVhIGUCvMWt1wxiECgs3bbjqGEA
# rAgmo42F0GTJNpAeilLJh401pV1IkfyTpqVl8ez5OtylLJ4EbWIz/t76n8XOr5Xz
# UajyzjCCBBUwggL9oAMCAQICCwQAAAAAATGJxlAEMA0GCSqGSIb3DQEBCwUAMEwx
# IDAeBgNVBAsTF0dsb2JhbFNpZ24gUm9vdCBDQSAtIFIzMRMwEQYDVQQKEwpHbG9i
# YWxTaWduMRMwEQYDVQQDEwpHbG9iYWxTaWduMB4XDTExMDgwMjEwMDAwMFoXDTI5
# MDMyOTEwMDAwMFowWzELMAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24g
# bnYtc2ExMTAvBgNVBAMTKEdsb2JhbFNpZ24gVGltZXN0YW1waW5nIENBIC0gU0hB
# MjU2IC0gRzIwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCqm47DqxFR
# JQG2lpTiT9jBCPZGI9lFxZWXW6sav9JsV8kzBh+gD8Y8flNIer+dh56v7sOMR+FC
# 7OPjoUpsDBfEpsG5zVvxHkSJjv4L3iFYE+5NyMVnCxyys/E0dpGiywdtN8WgRyYC
# FaSQkal5ntfrV50rfCLYFNfxBx54IjZrd3mvr/l/jk7htQgx/ertS3FijCPxAzmP
# RHm2dgNXnq0vCEbc0oy89I50zshoaVF2EYsPXSRbGVQ9JsxAjYInG1kgfVn2k4CO
# +Co4/WugQGUfV3bMW44ETyyo24RQE0/G3Iu5+N1pTIjrnHswJvx6WLtZvBRykoFX
# t3bJ2IAKgG4JAgMBAAGjgegwgeUwDgYDVR0PAQH/BAQDAgEGMBIGA1UdEwEB/wQI
# MAYBAf8CAQAwHQYDVR0OBBYEFJIhp0qVXWSwm7Qe5gA3R+adQStMMEcGA1UdIARA
# MD4wPAYEVR0gADA0MDIGCCsGAQUFBwIBFiZodHRwczovL3d3dy5nbG9iYWxzaWdu
# LmNvbS9yZXBvc2l0b3J5LzA2BgNVHR8ELzAtMCugKaAnhiVodHRwOi8vY3JsLmds
# b2JhbHNpZ24ubmV0L3Jvb3QtcjMuY3JsMB8GA1UdIwQYMBaAFI/wS3+oLkUkrk1Q
# +mOai97i3Ru8MA0GCSqGSIb3DQEBCwUAA4IBAQAEVoJKfNDOyb82ZtG+NZ6TbJfo
# Bs4xGFn5bEFfgC7AQiW4GMf81LE3xGigzyhqA3RLY5eFd2E71y/j9b0zopJ9ER+e
# imzvLLD0Yo02c9EWNvG8Xuy0gJh4/NJ2eejhIZTgH8Si4apn27Occ+VAIs85ztvm
# d5Wnu7LL9hmGnZ/I1JgFsnFvTnWu8T1kajteTkamKl0IkvGj8x10v2INI4xcKjiV
# 0sDVzc+I2h8otbqBaWQqtaai1XOv3EbbBK6R127FmLrUR8RWdIBHeFiMvu8r/exs
# v9GU979Q4HvgkP0gGHgYIl0ILowcoJfzHZl9o52R0wZETgRuehwg4zbwtlC5MYIC
# qDCCAqQCAQEwazBbMQswCQYDVQQGEwJCRTEZMBcGA1UEChMQR2xvYmFsU2lnbiBu
# di1zYTExMC8GA1UEAxMoR2xvYmFsU2lnbiBUaW1lc3RhbXBpbmcgQ0EgLSBTSEEy
# NTYgLSBHMgIMDKfPXQcHJKyJ55o6MA0GCWCGSAFlAwQCAQUAoIIBDjAaBgkqhkiG
# 9w0BCQMxDQYLKoZIhvcNAQkQAQQwHAYJKoZIhvcNAQkFMQ8XDTE5MDgyMjEwNTQw
# MFowLwYJKoZIhvcNAQkEMSIEIO0+eY5CuNlfxj63bKgFR8xnCZc+Sasuv/DG7HF9
# /bVEMIGgBgsqhkiG9w0BCRACDDGBkDCBjTCBijCBhwQUmxIFeucqr/bWN3K0n2oj
# byZJzakwbzBfpF0wWzELMAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24g
# bnYtc2ExMTAvBgNVBAMTKEdsb2JhbFNpZ24gVGltZXN0YW1waW5nIENBIC0gU0hB
# MjU2IC0gRzICDAynz10HBySsieeaOjANBgkqhkiG9w0BAQEFAASCAQCgontSZppt
# pr7rsbzPDfAYX7rEkODVv7LHr0P8zQNCQzyj8/N53t4SwRw6F+OnlfsGeznMoRP8
# RBaKtGL87IGgYUtdW2Oui80R16ORMWgPPn2HZjx9kODVJKeRXcKHg5GZ1QSSWodD
# ldz/fs3NG6QMbSr0bAM/Bh4uy1MEc9qll4qqxfwwXCe+/nwwzWC2TfTQgfUw1xwY
# vBlvOq8L9eIGqkoJJHizjGrdBtlQggzE3FC784nWQuxSGensMHrqH4AjSVSuUQRD
# xW2Icu012k8DH7oLxSzlBwTz2YlUPJFbUwNsMZbQRANpLw6/sO/3ThmMu2t3ms7S
# APFP8CkPys86
# SIG # End signature block
