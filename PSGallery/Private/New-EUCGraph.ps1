function New-EUCGraph {
    <#   
Broken Stuff.  Total testbed. 
# Install GraphViz from the Chocolatey repo
# Find-Package graphviz | Install-Package -ForceBootstrap

# Install PSGraph from the Powershell Gallery
# Find-Module PSGraph | Install-Module

# Import Module


#> 
    Import-Module PSGraph

    #    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "High")]
    
    Param
    (

        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$Results

    )
    
    $subgraph = 0
    graph EUC -Attributes @{ Label = 'EUC Monitoring' } {
        
        <#This won't work
        if ( !$null -eq $Results.Server ) {
            subgraph $subgraph -Attributes @{ Label = 'Workloads'} {
                if ( $Results.Server.Downs = 0 ) { $color = 'palegreen'}
                elseif ( $Results.Server.Ups = 0 ) { $color = 'red'}
                else { $color = 'orange'}
                node server @{ style = 'filled'; color = $color}
            }
        }
            
        #this either.  Purely for placeholder
        if ( !$null -eq $Results.desktop ) {
            subgraph $subgraph -Attributes @{ Label = 'Workloads'} {
                if ( $Results.Server.Downs = 0 ) { $color = 'palegreen'}
                elseif ( $Results.Server.Ups = 0 ) { $color = 'red'}
                else { $color = 'orange'}
                node desktop @{ style = 'filled'; color = $color}
            }
        }
        $subgraph++ 
        #>

        $color = 'palegreen'

        subgraph $subgraph -Attributes @{Label = 'Workloads'} {
            node server @{style = 'filled' ; color = $color; label = 'Worker: Servers'} 
            node desktop @{style = 'filled'; color = 'Orange'; label = 'Worker: Desktops'}
        }
        $subgraph++


        subgraph $subgraph -Attributes @{label = 'Citrix'} {
            #    
            #       subgraph -Attribute @{label = 'Infrastructure'} {
            node xenserver @{ style = 'filled'; color = 'lightblue'}
            #     } 
            node controllers @{style = 'filled'; color = 'PaleGreen'; label = 'Citrix Delivery Controllers'}
            node storefront @{style = 'filled'; color = 'PaleGreen'; label = 'Citrix StoreFront'}

            edge storefront -To controllers
            #            edge controllers -To licensing
            node director, licensing @{ style = 'filled'; color = 'lightblue'}
        } 
        subgraph $subgraph -Attributes @{Label = 'Citrix'} {
            node provisioning @{ style = 'filled'; color = 'lightblue'}
        }
        $subgraph++

        if ( $true -eq $Results.Microsoft.AD.Test ) {
            subgraph $subgraph -Attributes @{ Label = 'Microsoft'} {
                Write-Host "It worked."
                <#                if ( $Results.Microsoft.AD.Results = 0 ) { $color = 'palegreen'}
                elseif ( $Results.Server.Ups = 0 ) { $color = 'red'}
                else { $color = 'orange'}
#>              
                $color = 'palegreen'
                node AD @{ style = 'filled'; color = $color; label = 'Domain Controllers'}
            }
        }

        subgraph $subgraph -Attributes @{label = 'Microsoft'} {
            node database @{ style = 'filled'; color = 'lightblue'; label = 'MSSQL Servers'}
            #          node rdsbroker, app-v @{ style = 'filled'; color = 'palegreen'}
            node hyper-v @{ style = 'filled'; color = 'lightblue'}
        }
        $subgraph++ 

        #       edge controllers -To app-v

        subgraph $subgraph -Attributes @{label = 'VMWare'} {
            node vmware @{ style = 'filled'; color = 'lightblue'}
        }
        $subgraph++ 

        #        edge storefront -To domaincontroller
        #        edge controllers -To database, domaincontroller
        #        edge licensing -To database
        #       edge director -To database

        subgraph $subgraph -Attributes @{Label = 'Networking'} {
            node netscaler @{style = 'filled'; color = 'paleGreen'; Label = 'Netscaler'}
            #        node f5 @{ style = 'filled'; color = 'Red'}
        }
        $subgraph++
        edge netscaler -To controllers, storefront
        #        edge f5 -To rdsbroker


        edge controllers -To server, desktop
        #       edge rdsbroker -To server, desktop

        subgraph $subgraph -Attributes @{ Label = 'Third Party'} {
            node ControlUp @{ style = 'filled'; color = 'lightblue'; label = 'Control Up'}
            #        node uberAgent @{ style = 'filled'; color = 'lightblue'}
        }

        $errors = "This is a problem", "here is another problem", "things are really getting hairy", "even longer error list", "one more"
        Record ErrorList {
            Row 'This is a row'
            Row "where does $subgraph go"
            Row  -Label '<B>Something</B>'
            foreach ($error in $errors) { row $error }
        }

        <#
        Connect all the edges
        Networking to Gateway
        Networking to Broker
        Gateway to Broker
        Broker to Workloads


        #>
        <#        
        if ( $() -and (!$null -eq $Results.Network.NetScalerGateway) ) {

        }


        # DDC to Servers
        $Results.server
        if ( () -and (!$null -eq $Results.server) ) {   
            edge controller -To server
        }

        # DDC to Desktops
        if ( () -and (!$null -eq $Results.desktop) ) {
            edge controller -To desktop 
        }
#>

    } | Export-PSGraph  -ShowGraph -LayoutEngine Hierarchical
}

# All below is just testing.  
<#

$MyConfigFileLocation = "C:\Monitor\euc-monitoring.json.test"
$Config = Get-Content -Raw -Path $MyConfigFileLocation | ConvertFrom-Json -ErrorAction Stop 
$Res = $Config.PsObject.copy()

# We don't care about WebData

$Res.Microsoft.Global.Test = "yes"
$Res.Microsoft.AD.Test = $true

$Res.Microsoft.AD | Add-Member -MemberType NoteProperty -Name Results -Value (New-Object System.Collections.ArrayList)

# Lets assume this is how objects get returned.  
$Res.Microsoft.AD.Results += New-Object -TypeName psobject -Property @{ 
    Servername   = "dc1.domain.com" 
    PortCheck    = $true
    ServicesUp   = "NTDS", "NetLogon"
    ServicesDown = "ADWS"
}

$Res.Microsoft.AD.Results += New-Object -TypeName psobject -Property @{ 
    Servername   = "dc2.domain.com" 
    PortCheck    = $true
    ServicesUp   = "NTDS", "NetLogon"
    ServicesDown = "ADWS"
}

<# Now our Test-Subject can look like
$JSONConfig.Section.Subsection | Add-Member -MemberType NoteProperty -Name Results -Value (New-Object System.Collections.ArrayList)
foreach ( $server in $Servers ) {
    $valueA = 1
    $valueB = $true
    $JSONConfig.Section.SubSection.Results += New-Object -TypeName psobject -Property @{
        A = $valueA
        B = $valueB
    }
}
# Which means we can have uniform Values to iterate over, a standard services check, and 
# use JSON to say true instead of "yes", and have a common parameter set. 
#>

<#
$Res.Microsoft.AD.Results | ConvertTo-Json
<# Yeilds this:
[
    {
        "Servername":  "dc1.domain.com",
        "ServicesDown":  "ADWS",
        "PortCheck":  true,
        "ServicesUp":  [
                           "NTDS",
                           "NetLogon"
                       ]
    },
    {
        "Servername":  "dc2.domain.com",
        "ServicesDown":  "ADWS",
        "PortCheck":  true,
        "ServicesUp":  [
                           "NTDS",
                           "NetLogon"
                       ]
    }
]
#>

<#
New-EUCGraph -Results $Res

#>