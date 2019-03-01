#
# HPE 3PAR PowerShell Toolkit

The HPE 3PAR StoreServ Storage PowerShell Toolkit supports cmdlets, which are wrappers around the native HPE 3PAR StoreServ Storage CLI commands or HPE 3PAR StoreServ Storage Web Services API (WSAPI).

## Features of HPE 3PAR PowerShell Toolkit

HPE 3PAR StoreServ Storage PowerShell Toolkit v2.2 works with PowerShell v3.0 and later, upto PowerShell v5.1.

It can be used in following two ways:

1. With Native HPE 3PAR StoreServ Storage CLI command.

When you run the cmdlets, the following actions take place:

1. (a)A secure connection to the HPE 3PAR StoreServ Storage is established over Secure Shell.
2. (b)The native HPE 3PAR StoreServ Storage CLI command and parameters are formed based on the PowerShell cmdlet and parameters.
3. (c)The native HPE 3PAR StoreServ Storage CLI command is executed.
4. (d)The output of the cmdlets is returned as PowerShell objects. This output can be piped to other PowerShell cmdlets for further processing.

1. With HPE 3PAR Web Service API.

When you run the cmdlets, the following actions take place:

1. (a)A secure connection using HPE 3PAR Web Service API is established as a session key (credential). Unused session keys expire after 15 minutes.
2. (b)The HPE 3PAR Web Service API and parameters are formed based on the PowerShell cmdlet and parameters.
3. (c)WSAPI uses the HTTPS protocol to enable programmatic management of 3PAR storage servers, and provides client access to web services at specified HTTPS locations. Clients communicate with the WSAPI server using HTTPS methods and data structures represented with JSON.
4. (d)The output of the cmdlets is returned as PowerShell objects. This output can be piped to other PowerShell cmdlets for search.

## Product support

HPE 3PAR StoreServ Storage PowerShell Toolkit supports PowerShell 3.0 and later. This Toolkit provides cmdlets to manage the following operations:

- Views and manages Common Provisioning Group (CPG).
- Views and manages VVols.
- Views and manages Virtual Volume sets.
- Views and manages Hosts.
- Views and manages Host sets.
- Views and manages Virtual Logical Unit Number (vLUN).
- Views and manages Physical copy.
- Views and manages Virtual copy (Snapshots).
- Views and manages ports.
- Views and manages tasks.
- Views and manages Disk Enclosure.
- Views and manages Performance Management.
- Views and manages Spares.
- Supports for HPE 3PAR Web Services API.
- Supports for System Reporter cmdlets.
- Supports for Remote Copy cmdlets.
- Supports for Compression-related cmdlets.
- Supports for Asynchronous streaming replication.
- Supports for Deduplication-related cmdlets.
- Supports for Storage Federation related cmdlets.
- Supports for Smart SAN Enhancements (iSCSI) related cmdlets.

## Supported Host operating systems and HPE 3PAR PowerShell versions

HPE 3PAR StoreServ Storage PowerShell Toolkit works with HPE 3PAR PowerShell Toolkit 3.0 and later. You can use this Toolkit in the following environments:

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

## Supported HPE 3PAR StoreServ Storage Platforms

HPE 3PAR StoreServ 7000, 8000, 10000, and 20000 series.

Supported firmware for HPE 3PAR StoreServ Storage are:

- 3.1 (MU1, MU2, MU3 &amp; MU4)
- 3.1 (MU1, MU2, and MU3)
- 2.2 (including all MUs)
- 2.1 (including all MUs)

NOTE: Only CLI-based cmdlets are qualified with 3.3.1 MU4 and WSAPI-based cmdlets are qualified until 3.3.1 MU3.
