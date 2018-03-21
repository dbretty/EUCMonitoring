# EUC Platform Monitoring Tool

## Project Desription

This is a [EUC monitoring platform](http://bretty.me.uk/free-citrix-xendesktop-7-monitoring-platform/) that is based on Powershell and FREE! It will check all the key components of your End User Compute Estate and give you a visual dashboard as to the current state. It is currently focussed on Citrix but will eventually be branched out to cover VMware and Misrosoft Technologies.

![](https://raw.githubusercontent.com/dbretty/xendesktop-7x-monitor/master/img/overview.png)

## Motivation

The reason I started writing this is because I wanted a platform that will give you a high level, birds eye view of whats happening on your End User Compute Estate. More importantly I wanted it to be free! There are a number of products out there that can give you a lot of detail about whats happening but none that give you an overview of everything.  Thats what this is intended to resolve. It will automate and take away the steps that you normally do day to day on your estate and give you all of that information in a nice visual dashboard.

## Installation

To install and run this software follow these steps

### Pre-requisites

The Server that you want to run this script from must have the XenServer and XenDesktop PowerShell SDK Installed. Install Citrix Studio on the monitoring server and also install the XenServer SDK from the [XenServer 7.2 Standard Edition](https://www.citrix.com/downloads/xenserver/product-software/xenserver-72-standard-edition.html) download page.

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

```text
Set-EUCMonitoring C:\Monitoring -verbose
```

5. Once this is done go to that directory and rename the **euc-monitoring.json.template** file to **euc-monitoring.json**
6. Edit the json file to reflect your environment
7. Finally run the following command pointing to the directory that holds all the EUC Monitoring Scripts

```text
cd C:\Monitoring
Start-XDMonitor
```
OR
```text
Start-XDMonitor -JsonFile ".\mysettings.json" -LogFile ".\mylog.txt" -CSSFile ".\euc-monitor.css" -Verbose 
```

8. Open up your new dashboard HTML file from the location you specified in your json for web data output

## Contributors

Dave Brett [@dbretty](https://twitter.com/dbretty) | James Kindon [@james_kindon](https://twitter.com/james_kindon) | Ryan Butler [@ryan_c_butler](https://twitter.com/Ryan_C_Butler) | David Wilkinson [@WilkyIT](https://twitter.com/WilkyIT) | Gareth Carson [@CitXen](https://twitter.com/CitXen) | Jake Walsh [@jakewalsh90](https://twitter.com/jakewalsh90) | Andy Mallins [@andymallins](https://twitter.com/andymallins)
