# Preparing Foreman
to use the generated OS Images please configure youre Foreman Instace according to this guide.
This Guide was written with Foreman 2.1 - if you use a older or newer version some settings might be called different.


## Create Installation Media Mirror
1. Navigate to _Hosts > Provisioning Setup > Operating Systems_
2. Click the _Create Medium_ Button
3. Fill in the Form:
   - Name: `Windows Images`
   - Path: `http://your.webserver.local/$arch/$major/`
   - Operating System Family: select _Windows_
   - Locations: select your Options
   - Organizations: select your Options
4. Submit

## Create Operating System
1. Navigate to _Hosts > Provisioning Setup > Operating Systems_
2. Click the _Create Operating System_ Button
3. Fill in the Form:
   - Name: `WindowsServer2016`
   - Description: `Windows Server 2016`
   - Major Version: `2016`
   - Minor Version: leave empty
   - Root Password Hash: select _Base64-Windows_
   - Architectures: select your Architecture, like amd64 or x86_64

4. Select the Tab _Partition Table_
   - Filter for _Windows_
   - Add _Windows default partition table_ and _Windows default GPT EFI partition table_ to list

5. Select the Tab _Installation Media_
   - Filter for _Windows Images_
   - Add _Windows Images_ to the list

6. Submit

## Modify Provisioning Templates
1. Navigate to _Host > Templates > Provisioning Templates_
2. Search for _Windows_
3. For each of the following templates, edit the Options in the Tabs:
   - _Association_: Add _Windows Server 2016_ to the list
   - _Locations_: select your Options
   - _Organizations_: select your Options

   Templates:
   - PXELinux chain iPXE
   - Windows default finish
   - Windows default provision
   - Windows default PXELinux
   - Windows default iPXE
   - Windows peSetup.cmd


## Modify Operating System
1. Navigate to _Hosts > Provisioning Setup > Operating Systems_
2. Search for the just created `Windows Server 2016`
3. Select the Parameters Tab and add at least the `wimImageName` Setting
4. Submit


### Possible Parameters
#### Mandotory Parameters:
- wimImageName: possible options from _images.ini_

#### Optional Parameters:
- windowsLicenseKey (string): `ABCDE-ABCDE-ABCDE-ABCDE-ABCDE`
- windowsLicenseOwner (string): `Company, INC`
- localAdminAccountDisabled (boolean): `true` or `false`
- ntpServer (string): `time.windows.com,pool.ntp.org`
- foremanDebug (boolean): `true` or `false`
- systemLocale (string): `en-US`, `de-DE`
- systemUILanguage (string): `en-US`, `de-DE`
- systemTimeZone (string): `GMT Standard Time`, `Eastern Standard Time`, `W. Europe Standard Time` [Microsoft Time Zones](https://support.microsoft.com/en-us/help/973627/microsoft-time-zone-index-values)

#### Optional Parameters: Active Diretory Domain Join:
- computerDomain (string): `domain.com`
- domainAdminAccount (string): `ad-join-user@domain.com`
- domainAdminAccountPasswd (string): `securepassword`
- computerOU (string): `OU=Computers,CN=domain,CN=com`
