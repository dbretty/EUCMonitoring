# Citrix XenDesktop 7.x Platform Monitoring Tool

## Project Desription

This is a [Citrix XenDesktop 7.x monitoring platform](http://bretty.me.uk/free-citrix-xendesktop-7-monitoring-platform/) that is based on Powershell and FREE! It will check all the key components of your Citrix XenDesktop Estate and give you a visual dashboard as to the current state.

![](https://raw.githubusercontent.com/aaronparker/xendesktop-7x-monitor/master/img/overview.png)

## Motivation

The reason I started writing this is because I wanted a platform that will give you a high level birds eye view of whats happening on your Citrix Platform. More importantly I wanted it to be free!

## Installation

To install and run this software follow these steps

### Pre-requisites

The Server that you want to run this script from must have the XenServer and XenDesktop PowerShell SDK Installed. Install Citrix Studio on the monitoring server and also install the XenServer SDK from the [XenServer 7.2 Standard Edition](https://www.citrix.com/downloads/xenserver/product-software/xenserver-72-standard-edition.html) download page.

### Installation steps

1. Create a directory on your monitoring server (e.g. monitoring)
2. Copy the files into that directory

```text
ROOT DIRECTORY
    xendesktop-monitor.ps1
    xendesktop-monitor.json
        MODULES DIRECTORY
        xendesktop-monitor-global.ps1
```

3. Update the JSON File with your environment information - Use xendesktop-monitoring-json-ref.txt
5. Copy the xendesktop-monitor.css file into the directory that you are going to put the html output file
4. Run the script manually or ctreate a scheduled task to run it

## Contributors

Dave Brett [@dbretty](https://twitter.com/dbretty) | James Kindon [@james_kindon](https://twitter.com/james_kindon)