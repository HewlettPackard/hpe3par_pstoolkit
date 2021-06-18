#
# HPE Alletra 9000 and Primera and 3PAR PowerShell Toolkit

The HPE Alletra 9000 and Primera and 3PAR PowerShell Toolkit supports cmdlets, which are wrappers around the native HPE Alletra 9000 or HPE Primera or HPE 3PAR storage CLI commands and Web Services API (WSAPI).

## Features of HPE Alletra 9000 and Primera and 3PAR PowerShell Toolkit

The latest HPE Alletra 9000 and Primera and 3PAR PowerShell Toolkit works with PowerShell 3.0 and later up to PowerShell 5.1, PowerShell Core 6.x, and PowerShell 7.

It can be used in the following two ways:

**With Native HPE Alletra 9000 or HPE Primera or HPE 3PAR storage CLI command**

When you run the cmdlets, the following actions take place:

1. A secure connection to the HPE Alletra 9000 or HPE Primera or HPE 3PAR storage is established over a secure shell.
2. The native HPE Alletra 9000 or HPE Primera or HPE 3PAR storage CLI command and parameters are formed based on the PowerShell cmdlet and parameters.
3. The native HPE Alletra 9000 or HPE Primera or HPE 3PAR storage CLI command are executed.
4. The output of the cmdlets is returned as PowerShell objects. This output can be piped to other PowerShell cmdlets for further processing.

NOTE: PowerShell Core 6.x and PowerShell 7 are supported only for CLI and WSAPI connections. Not supported for PoshSSH Connection.

**With HPE Alletra 9000 or HPE Primera or HPE 3PAR storage Web Service API (WSAPI 1.6.4 and 1.7)**

When you run the cmdlets, the following actions take place:

1. A secure connection using WSAPI is established as a session key (credential). Unused session keys expire after 15 minutes.
2. The WSAPI and parameters are formed based on the PowerShell cmdlet and parameters.
3. The WSAPI uses the HTTPS protocol to enable programmatic management of HPE Alletra 9000 or HPE Primera or HPE 3PAR storage servers and provides client access to web services at specified HTTPS locations. Clients communicate with the WSAPI server using HTTPS methods and data structures represented with JSON.
4. The output of the cmdlets is returned as PowerShell objects. This output can be piped to other PowerShell cmdlets for search.

## Product support

The HPE Alletra 9000 and Primera and 3PAR PowerShell Toolkit supports PowerShell 3.0 and later up to PowerShell 5.1, PowerShell Core 6.x and PowerShell 7. This Toolkit provides cmdlets to manage the following operations:

- Views and manages 
	- Common Provisioning Group (CPG)
	- VVols
	- Virtual Volume sets
	- Hosts
	- Host sets
	- Virtual Logical Unit Number (vLUN)
	- Physical copy
	- Virtual copy (Snapshots)
	- Ports
	- Tasks
	- Disk Enclosure
	- Performance Management
	- Spares
	- CIM
- Support for 
	- System Reporter Cmdlets
	- Remote Copy Cmdlets
	- Compression-related Cmdlets
	- Asynchronous streaming replication
	- Deduplication-related Cmdlets
	- Storage Federation related Cmdlets
	- Smart SAN Enhancements (iSCSI) related Cmdlets.
	- Adaptive Optimization (AO)
	- Domain Management
	- Flash cache
	- Health and Alert Management
	- Node Subsystem Management
	- Service Cmdlets
	- CIM Cmdlets
	- HPE Primera and HPE 3PAR Web Services API

## Supported Host operating systems and PowerShell versions

HPE Alletra 9000 and Primera and 3PAR PowerShell Toolkit works with PowerShell 3.0 and later up to PowerShell 5.1, PowerShell Core 6.x, and PowerShell 7. You can use this Toolkit in the following environments:

- Microsoft Windows 2019
- Microsoft Windows Server 2016
- Microsoft Windows Server 2012 R2
- Microsoft Windows Server 2012
- Microsoft Windows Server 2008 R2 SP1
- Microsoft Windows Server 2008 R2
- Microsoft Windows Server 2008 SP1
- Microsoft Windows 10
- Microsoft Windows 8
- Microsoft Windows 7 SP1
- Microsoft Windows 7

## Supported Storage Platforms

**HPE Alletra 9000**

Supported firmware for HPE Alletra 9000 is 9.3.0

**HPE Primera 630, 650 and 670 series**

Supported firmware for HPE Primera are 4.0.0, 4.1.0, 4.2.0 and 4.3.0

**HPE 3PAR storage 7000, 8000, 9000, 10000, &amp; 20000 series**

Supported firmware for HPE 3PAR storage are:

- 3.3.1 (MU1, MU2, MU3, MU4 &amp; MU5)
- 3.3.1 (MU1, MU2, and MU3)
- 3.2.2 (including all MUs)
- 3.2.1 (including all MUs)

## PowerShell Toolkit cmdlets Flow

We can perform the following operations using PowerShell Toolkit CLI cmdlets.

- Create/Add
- Update/Set
- Delete/Remove
- Get
