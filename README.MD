[![Build status](https://ci.appveyor.com/api/projects/status/2yb4ai0n72nrsm2x/branch/master?retina=true)](https://ci.appveyor.com/project/dbretty/eucmonitoring/branch/master)

# EUC Platform Monitoring Tool

## Project Desription

This is a [EUC monitoring platform](http://bretty.me.uk/free-citrix-xendesktop-7-monitoring-platform/) that is based on Powershell and FREE! It will check all the key components of your End User Compute Estate and give you a visual dashboard as to the current state. It is currently focussed on Citrix but will eventually be branched out to cover VMware and Microsoft Technologies.

![](https://raw.githubusercontent.com/dbretty/eucmonitoring/master/img/overview.png)

## Motivation

The reason I started writing this is because I wanted a platform that will give you a high level, birds eye view of whats happening on your End User Compute Estate. More importantly I wanted it to be free! There are a number of products out there that can give you a lot of detail about whats happening but none that give you an overview of everything.  Thats what this is intended to resolve. It will automate and take away the steps that you normally do day to day on your estate and give you all of that information in a nice visual dashboard.

## Installation

To install and run this software follow these steps

### Pre-requisites 
#### On-Premises

The Server that you want to run this script from must have the XenServer and XenDesktop PowerShell SDK Installed. Install Citrix Studio on the monitoring server and also install the XenServer SDK from the [XenServer](https://www.citrix.com/downloads/xenserver/product-software.html) download page.

#### Cloud
The Server that you want to run this script from must have the Remote [PowerShell SDK for Applications and Desktops Service](http://download.apps.cloud.com/CitrixPoshSdk.exe): 

Obtain a Citrix Cloud automation credential as follows:
- Login to https://citrix.cloud.com/
- Navigate to "Identity and Access Management". 
- Click "API Access". 
- Enter a name for Secure Client and click Create Client. 
- Once Secure Client is created, download Secure Client Credentials file (ie. downloaded to C:\Monitoring)

Note the Customer ID located in this same page, this is case senstitive.
```
Set-XDCredentials -CustomerId "%Customer ID%" -SecureClientFile "C:\Monitoring\secureclient.csv" -ProfileType CloudApi -StoreAs "CloudAdmin"
```

NOTE: **xdbrokerprimary/xdbrokerfailover** should be set as the Citrix Cloud Connector, the cloud connectors will proxy the connection directly to the Delivery Controller as they are not directly accessible.

NOTE: xdbrokerprimary/xdbrokerfailover should be set as the Citrix Cloud Connector, the cloud connectors will proxy the connection directly to the Delivery Controller as they are not directly accessible.

### Installation steps

1. Open up PowerShell on the machine you want to use for monitoring.
2. Run the following to locate on PSGallery
```text
Find-Module EUCMonitoring
```
3. Run the following command to install the EUC Monitoring Module.
   * Install for **Allusers** (Need to be run as Administrator)
        ```text
        Install-Module EUCMonitoring
        ```
   * Install for **Currentuser**
        ```text
        Install-Module EUCMonitoring -Scope CurrentUser
        ```
4. Next run the following command pointing to a directory that you want the EUC Monitoring setting files and output HTML to reside.
   * Run this for manual configuration. 
        ```text
        Set-EUCMonitoring C:\Monitoring -verbose
        ```
   * Or, for users that want a more interactive dashboard, you can invoke this parameter which will install InfluxDB, Grafana, and NSSM, along with some default dashboards. (This will need to be run as Administrator)
        ```text
        Set-EUCMonitoring C:\Monitoring -InstallVisualizationSetup -verbose
        ```
    * There is a corresponding ```-UninstallVisualizationSetup``` that will uninstall the Influx/Grafana/NSSM instances and remove their directories, but leave your remaining files intact. 
5. If manually configuring, go to that directory and rename the **euc-monitoring.json.template** file to **euc-monitoring.json**
6. Edit the json file to reflect your environment.  

7. Finally run the following command pointing to the directory that holds the needed files

```text
cd C:\Monitoring
Start-EUCMonitor
```
OR
```text
Start-EUCMonitor -JsonFile ".\mysettings.json" -Verbose 
```
OR, if you did the interactive dashboard
```text
cd C:\Monitoring
.\Begin-EUCMonitor.ps1
```

8. Open up your new dashboard HTML file from the location you specified in your json for web data output

## Active Contributors

Dave Brett [@dbretty](https://twitter.com/dbretty) | James Kindon [@james_kindon](https://twitter.com/james_kindon) | Ryan Butler [@ryan_c_butler](https://twitter.com/Ryan_C_Butler) | David Wilkinson [@WilkyIT](https://twitter.com/WilkyIT) | Adam Yarborough [@littletoyrobots](https://twitter.com/littletoyrobots) | Hal Lange [@hal_lange](https://twitter.com/hal_lange) | Ryan Revord [@rsrevord](https://twitter.com/rsrevord)
