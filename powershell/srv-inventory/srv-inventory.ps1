#$outputFilePath = "M:\OutputToFile.csv"
$outputFilePath = "M:\DC-VM-ETKA-DE-01.csv"

$strMessage = "Service startup type of this conteiner may be disabled, stoped, manual, `nor may be not completedly configured. Or container configuration may be broken. `nAlso Tomcat's container may be installed in the system and not be registered as a windows service `n(or deleted from windows registry service section manualy). Also container may be empty `nwithout any deployed application. `nGeneraly this may be done in order to disable default tomcat container."

$srvInfo = @{}
$srvInfo["os-name"] = (Get-WmiObject -class Win32_OperatingSystem).Caption
$srvInfo["os-version"] = (Get-WmiObject -class Win32_OperatingSystem).Version
$srvInfo["os-architecture"] = (Get-WmiObject -class Win32_OperatingSystem).OSArchitecture
$srvInfo["os-fullinfo"] = $srvInfo["os-name"] + " version: " + $srvInfo["os-version"]
#$srvInfo["hostname"] = (Get-WMIObject Win32_ComputerSystem | Select-Object -ExpandProperty name)
$srvInfo["hostname"] = (hostname)
$srvInfo["default-java-version"] = (java -version 2>&1)[1].tostring()
$srvInfo["tomcat-containers"] = @{}

function getStrXMLProperties ($xmlNode) {
    $currXMLPropetryes = @{}
    $str = ""
    
    foreach ($item in ($xmlNode | Get-Member -MemberType Property|select Name)) {
        $currXMLPropetryes[$item.Name] = $xmlNode.($item.Name)
        #$str += ($item.Name + '="' + $currXMLPropetryes[$item.Name] + '"' + "`n")
        $str += ($item.Name + '=' + $currXMLPropetryes[$item.Name] + "`n")
    }
    $str -replace "`n$"
}


####################################################################
#                      Get Tomcat settings                         #
####################################################################
# Start-Process -FilePath powershell.exe -Verb RunAs -ArgumentList ($allTomcats = Get-ChildItem $tomcatRegistryPath)

$tomcatRegistryPath = 'HKLM:\SOFTWARE\Wow6432Node\Apache Software Foundation\Procrun 2.0'
# $registryServicesPath = 'HKLM:\SYSTEM\CurrentControlSet\services'
$registryServicesPath = 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services'

if (Test-Path $tomcatRegistryPath) {
    # Get Tomcat instances from registry
    # $allTomcats = Get-ChildItem $tomcatRegistryPath
      
    if (Test-Path $env:SystemRoot\system32\WindowsPowerShell\v1.0\powershell.exe) {
        $PShellProgram = $env:SystemRoot + "\system32\WindowsPowerShell\v1.0\powershell.exe"
    }
    else {
        $PShellProgram = powershell.exe
    }
    
    Start-Process -FilePath $PShellProgram -Verb RunAs -ArgumentList ($allTomcats = Get-ChildItem $tomcatRegistryPath)
    ### Start-Process -FilePath powershell.exe -Verb RunAs -ArgumentList ($allSystemServices = Get-ChildItem $registryServicesPath)
    
    foreach ($currTomcat in $allTomcats) {

        
        ################################################################################################################
        #                                       Do actions on the container level                                      #
        ################################################################################################################
        $isExistContainerOnDisk = $TRUE
        
        
        # Get Tomcat's registry settings
        $currTomcatPropertyPath = $currTomcat.ToString() + "\Parameters\Java"
        $currTomcatSettings = Get-ItemProperty "Registry::$currTomcatPropertyPath"
        
        $srvInfo["tomcat-containers"][$currTomcat.PSChildName] = @{}
        $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["containerName"] = $currTomcat.PSChildName
        $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["Classpath"] = $currTomcatSettings.Classpath
        $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["Jvm"] = $currTomcatSettings.Jvm
        $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["JvmMs"] = $currTomcatSettings.JvmMs
        $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["JvmMx"] = $currTomcatSettings.JvmMx
        $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["JvmSs"] = $currTomcatSettings.JvmSs
        $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["Options"] = $currTomcatSettings.Options
        
        foreach ($currTomcatSettingsValue in $currTomcatSettings.Options) {
            if     ($currTomcatSettingsValue -like "-Dcatalina.home*") { 
                $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["catalina.home"] = `
                                                                    $currTomcatSettingsValue.remove(0,16) 
            }
            elseif ($currTomcatSettingsValue -like "-Dcatalina.base*") { 
                $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["catalina.base"] = `
                                                                    $currTomcatSettingsValue.remove(0,16) 
                if ((Test-Path $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["catalina.base"]) -eq $FALSE) {
                    $isExistContainerOnDisk = $FALSE
                }
            }
            elseif ($currTomcatSettingsValue -like "-Djava.endorsed.dirs*") { 
                $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["java.endorsed.dirs"] = `
                                                                    $currTomcatSettingsValue.remove(0,21) 
            }
            elseif ($currTomcatSettingsValue -like "-Djava.io.tmpdir*") { 
                $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["java.io.tmpdir"] = `
                                                                    $currTomcatSettingsValue.remove(0,17) 
            }
            elseif ($currTomcatSettingsValue -like "-Djava.util.logging.manager*") { 
                $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["java.util.logging.manager"] = `
                                                                    $currTomcatSettingsValue.remove(0,28) 
            }
            elseif ($currTomcatSettingsValue -like "-Djava.util.logging.config.file*") { 
                $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["java.util.logging.config.file"] = `
                                                                    $currTomcatSettingsValue.remove(0,32) 
            }
            elseif ($currTomcatSettingsValue -like "-XX:MaxPermSize*") { 
                $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["XX:MaxPermSize"] = `
                                                                    $currTomcatSettingsValue.remove(0,16) 
            }
            elseif ($currTomcatSettingsValue -like "-Dcom.sun.management.jmxremote") { 
                $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["com.sun.management.jmxremote"] = `
                                                                    $currTomcatSettingsValue.remove(0,30) 
            }
            elseif ($currTomcatSettingsValue -like "-Dcom.sun.management.jmxremote.port*") { 
                $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["com.sun.management.jmxremote.port"] = `
                                                                    $currTomcatSettingsValue.remove(0,36) 
            }
            elseif ($currTomcatSettingsValue -like "-Dcom.sun.management.jmxremote.ssl*") { 
                $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["com.sun.management.jmxremote.ssl"] = `
                                                                    $currTomcatSettingsValue.remove(0,35) 
            }
            elseif ($currTomcatSettingsValue -like "-Dcom.sun.management.jmxremote.authenticate*") { 
                $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["com.sun.management.jmxremote.authenticate"] = `
                                                                    $currTomcatSettingsValue.remove(0,44) 
            }            
        }
        
        # Get Tomcat's Server Info
        if ($isExistContainerOnDisk) {
            $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["Tomcat-Info"] = `
                                        (java -cp `
                                        ($srvInfo["tomcat-containers"][$currTomcat.PSChildName]["catalina.home"] + "\lib\catalina.jar") `
                                        org.apache.catalina.util.ServerInfo)
        }
        else {
            $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["Tomcat-Info"] = "None"
        }
        
        # Get Tomcat's version
        if ($isExistContainerOnDisk) {
            $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["Tomcat-Version"] = ""
            foreach ($currTomcatVerItem in $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["Tomcat-Info"]) {
                if     ($currTomcatVerItem -like "Server version:*") { 
                    $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["Tomcat-Version"] += $currTomcatVerItem + "`n" 
                }
                elseif ($currTomcatVerItem -like "Server number:*") { 
                    $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["Tomcat-Version"] += $currTomcatVerItem + "`n" 
                }
            }
            $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["Tomcat-Version"] = `
                                        ($srvInfo["tomcat-containers"][$currTomcat.PSChildName]["Tomcat-Version"] -replace "`n$")
        }
        else {
            $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["Tomcat-Version"] = "None"
        }
        
        
        # Get Tomcat's JVM version
        if ($isExistContainerOnDisk) {
            $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["Tomcat-JVM-Version"] = ""
            foreach ($currTomcatJVMVerItem in $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["Tomcat-Info"]) {
                if     ($currTomcatJVMVerItem -like "JVM Version:*") { 
                    $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["Tomcat-JVM-Version"] += $currTomcatJVMVerItem + "`n" 
                }
                elseif ($currTomcatJVMVerItem -like "JVM Vendor:*") { 
                    $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["Tomcat-JVM-Version"] += $currTomcatJVMVerItem + "`n" 
                }
            }
            $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["Tomcat-JVM-Version"] = `
                                        ($srvInfo["tomcat-containers"][$currTomcat.PSChildName]["Tomcat-JVM-Version"] -replace "`n$")
        }
        else {
            $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["Tomcat-JVM-Version"] = "None"   
        }


        # Get Tomcat Services information        
        $isExistConteinerInServiceRegistry = $TRUE
        $currTomcatServicePropertyPath = $registryServicesPath + "\" + $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["containerName"]
        
        if ((Test-Path Registry::$currTomcatServicePropertyPath) -eq $FALSE) {
            $isExistConteinerInServiceRegistry = $FALSE
        }
        
        if ($isExistConteinerInServiceRegistry) {
            $currTomcatServiceSettings = Get-ItemProperty "Registry::$currTomcatServicePropertyPath"
            
            $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["TomcatService_Description"] = $currTomcatServiceSettings.Description
            $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["TomcatService_DisplayName"] = $currTomcatServiceSettings.DisplayName
            $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["TomcatService_ImagePath"] = $currTomcatServiceSettings.ImagePath
            $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["TomcatService_ObjectName"] = $currTomcatServiceSettings.ObjectName
        }
        else {
            $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["TomcatService_Description"] = "None"
            $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["TomcatService_DisplayName"] = "None"
            $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["TomcatService_ImagePath"] = "None"
            $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["TomcatService_ObjectName"] = "None"
        }
        
        # --------
        
        # Get main Tomcat configuration file (server.xml)
        $isExistServerXML = $TRUE
        $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["tomcat-server.xml-path"] = `
                                    $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["catalina.base"] + "\conf\server.xml"
        
        if ((Test-Path $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["tomcat-server.xml-path"]) -eq $FALSE) {
            $isExistServerXML = $FALSE
        }
               
        if ($isExistServerXML) {
            # Read server.xml file and get jvmRoute
            [xml]$currServerXML = Get-Content $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["tomcat-server.xml-path"]
            
            $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["protocol-ports"] = @()
            $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["protocol-types"] = @()
            $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["ssl-settings"] = @()
            $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["isSSLExist"] = $FALSE
            
            $iHTTPConnector = 0
            
            foreach ($currConnectorItem in $currServerXML.Server.Service.Connector) {
                
                if  ($currConnectorItem.protocol) {
                    # http or ajp or else
                    if ($currConnectorItem.protocol -like "HTTP/1.1") {
                        $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["protocol-ports"] += $currConnectorItem.port
                        $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["protocol-types"] += "http"
                        $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["ssl-settings"] += ""
                    } 
                    elseif ($currConnectorItem.protocol -like "AJP/1.3") {
                        $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["protocol-ports"] += $currConnectorItem.port
                        $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["protocol-types"] += "ajp"
                        $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["ssl-settings"] += ""
                    }
                    else {
                        $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["protocol-ports"] += $currConnectorItem.port
                        $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["protocol-types"] += $currConnectorItem.protocol
                        $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["ssl-settings"] += ""
                    }
                } 
                elseif (($currConnectorItem.scheme -like "https") -or ($currConnectorItem.secure) -or `
                        ($currConnectorItem.SSLEnabled) -or ($currConnectorItem.sslProtocol)) {
                    # https
                    $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["protocol-ports"] += $currConnectorItem.port
                    $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["protocol-types"] += "https"
                    $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["ssl-settings"] += (getStrXMLProperties ($currConnectorItem))
                    
                    $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["isSSLExist"] = $TRUE
                }
                else {
                    $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["protocol-ports"] + $currConnectorItem.port
                    $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["protocol-types"] + "ERROR-Port"
                    $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["ssl-settings"] + ""
                }

                $iHTTPConnector++
                
                    
            }
                    
            $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["protocols-count"] = $iHTTPConnector
            
            
            
            
                    
            
            
            # Get jvmRoute
            # $currServerXML.Server.Service.Engine.jvmRoute
            $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["jvmRoute"] = ""
            foreach ($currTomcatEngine in $currServerXML.Server.Service) {
                if ($currTomcatEngine.Engine.jvmRoute) {
                    $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["jvmRoute"] += 'jvmRoute="' + $currTomcatEngine.Engine.jvmRoute + '" ' 
                }
                else {
                    $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["jvmRoute"] += "jvmRoute doesn't exist"
                }
            }
        }
        else {
            #$srvInfo["tomcat-containers"][$currTomcat.PSChildName]["protocol-ports"] = @()
            #$srvInfo["tomcat-containers"][$currTomcat.PSChildName]["protocol-types"] = @()
            #$srvInfo["tomcat-containers"][$currTomcat.PSChildName]["ssl-settings"] = @()
            $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["isSSLExist"] = "None"
            
            $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["protocols-count"] = "None"
            $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["jvmRoute"] = "None"
        }
        
        # Get FileSystemRights
        if ($isExistContainerOnDisk) {
            $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["FileSystemRights"] = `
                                    $(get-item $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["catalina.base"] | get-acl).access | `
                                    select IdentityReference,FileSystemRights | `
                                    ForEach-Object {"creator_owner: [ $($_.IdentityReference) ] `t FileSystemRights: [ $($_.FileSystemRights) ]!"}
        }
        else {
            $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["FileSystemRights"] = "None"
        }
        
        
        #$srvInfo["tomcat-containers"][$currTomcat.PSChildName]["FileSystemRights"] = `
        #                        $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["FileSystemRights"] -replace "!", "`n$"
        $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["FileSystemRights"] = `
                                $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["FileSystemRights"] -replace "!", "`n"
                               
        # Get XML config files
        $isExistXMLConfigsPath = $TRUE
        
        $i = 0
        $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["app-xml-configs"] = @()
        $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["app-local-URL"] = @()
        $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["site-URL"] = @()
        $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["app-xml-config-path"] = @()
        
        if ((Test-Path (($srvInfo["tomcat-containers"][$currTomcat.PSChildName]["catalina.base"]) + "\conf\Catalina\localhost")) -eq $FALSE) {
            $isExistXMLConfigsPath = $FALSE
        }
        
        
        $isExistSitesXMLConfigs = $FALSE
        if ($isExistXMLConfigsPath) {
            foreach ($xmlConfigFile in (Get-ChildItem (($srvInfo["tomcat-containers"][$currTomcat.PSChildName]["catalina.base"]) + `
                                                                                                            "\conf\Catalina\localhost"))) {
                $isExistSitesXMLConfigs = $TRUE                                                                             
            }
        }
        
        
        if ($isExistXMLConfigsPath -and $isExistSitesXMLConfigs) {
                        
            foreach ($xmlConfigFile in (Get-ChildItem (($srvInfo["tomcat-containers"][$currTomcat.PSChildName]["catalina.base"]) + `
                                                                                                            "\conf\Catalina\localhost"))) {
                ################################################################################################################
                #                                     Do actions on the application level                                      #
                ################################################################################################################
                
                
                # Continue: Get XML config files
                $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["app-xml-configs"] += $xmlConfigFile.Name
                $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["app-local-URL"] += $xmlConfigFile.Name -replace ".xml$"
                $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["app-xml-config-path"] += `
                                                                    $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["catalina.base"] + `
                                                                    "\conf\Catalina\localhost\" + $xmlConfigFile.Name

                $iSiteURLMax = $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["protocols-count"]
                $tmpSiteURLString = ""
                $tmpSSLSettingString = ""
                for ($iSiteURL=0; $iSiteURL -lt $iSiteURLMax; $iSiteURL++) {
                    $tmpSiteURLString += $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["protocol-types"][$iSiteURL] + "://" + `
                                        $srvInfo["hostname"].ToLower() + ":" + $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["protocol-ports"][$iSiteURL] + "/" + `
                                        $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["app-local-URL"][$i] + "`n"
                                        
                    # SSL settings for connector                    
                    $tmpSSLSettingString += $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["ssl-settings"][$iSiteURL] + "`n"
                }
                
                $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["site-URL"] += ($tmpSiteURLString -replace "`n$")
                
                if ($srvInfo["tomcat-containers"][$currTomcat.PSChildName]['isSSLExist'] -eq $FALSE) {
                    $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["site-ssl-settings"] = "SSL Settings doesn't exist"
                }
                else {
                    $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["site-ssl-settings"] += ($tmpSSLSettingString -replace "`n$")
                }
                
                # Get session settings
                $currWebXMLPath = $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["catalina.base"] + "\conf\web.xml"
                [xml]$currWebXML = Get-Content ($currWebXMLPath)
                $currSessionConfig = getStrXMLProperties ($currWebXML."web-app"."session-config")
                $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["session-settings"] = "Configured at: $currWebXMLPath`n`n" + $currSessionConfig
                #$srvInfo["tomcat-containers"][$currTomcat.PSChildName]["session-settings"]
                
                # Preparing output JMX settings in order to use this string in main output string
                $currJMXSettings = ""
                If ($srvInfo["tomcat-containers"][$currTomcat.PSChildName].ContainsKey("com.sun.management.jmxremote")) { 
                    $currJMXSettings += "-Dcom.sun.management.jmxremote`n" 
                }
                If ($srvInfo["tomcat-containers"][$currTomcat.PSChildName].ContainsKey("com.sun.management.jmxremote.port")) { 
                    $currJMXSettings += "-Dcom.sun.management.jmxremote.port=" + `
                                            $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["com.sun.management.jmxremote.port"] + "`n" 
                }
                If ($srvInfo["tomcat-containers"][$currTomcat.PSChildName].ContainsKey("com.sun.management.jmxremote.port")) { 
                    $currJMXSettings += "-Dcom.sun.management.jmxremote.ssl=" + `
                                            $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["com.sun.management.jmxremote.ssl"] + "`n" 
                }
                If ($srvInfo["tomcat-containers"][$currTomcat.PSChildName].ContainsKey("com.sun.management.jmxremote.authenticate")) { 
                    $currJMXSettings += "-Dcom.sun.management.jmxremote.authenticate=" + `
                                            $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["com.sun.management.jmxremote.authenticate"] + "`n"
                }
                $currJMXSettings = $currJMXSettings -replace "`n$"
                
                
                # Preparing line string in order to make write this string to CSV file. This is a main output string
                $strToFile += '"' + $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["site-URL"][$i] + '",' +`
                                '"' + $srvInfo["os-fullinfo"] +'",' + `
                                '"' + $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["Tomcat-Version"] + '",' +`
                                '"' + $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["TomcatService_ObjectName"] + '",' +`
                                '"' + $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["Tomcat-JVM-Version"] + '",' +`
                                '"' + $srvInfo["default-java-version"] + '",' +
                                '"' +  ' -Xms' + $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["JvmMs"] `
                                    + ' -Xmx' + $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["JvmMx"] `
                                    + ' -Xss' + $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["JvmSs"] `
                                    + ' -XX:MaxPermSize' + $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["XX:MaxPermSize"] + '",' +`
                                '"' + $currJMXSettings + '",' + `
                                '"' + "Permissions for: " + $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["catalina.base"] + "`n" `
                                    + $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["FileSystemRights"] + '",' + `
                                '"' + $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["jvmRoute"] + '",' + 
                                '"' + $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["site-ssl-settings"] + '",' + `
                                '"' + $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["session-settings"] + '"' + "`n"
                    
                $i++
            }
        }
        else {
            #
            # Preparing line string in order to make write this string to CSV file. This is a main output string
            
                $strToFile += '"' + $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["containerName"] + ': ' + $strMessage + '",' +`
                                '"' + $srvInfo["os-fullinfo"] +'",' + `
                                '"' + $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["Tomcat-Version"] + '",' +`
                                '"' + $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["TomcatService_ObjectName"] + '",' +`
                                '"' + $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["Tomcat-JVM-Version"] + '",' +`
                                '"' + $srvInfo["default-java-version"] + '",' +
                                '"' +  ' -Xms' + $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["JvmMs"] `
                                    + ' -Xmx' + $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["JvmMx"] `
                                    + ' -Xss' + $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["JvmSs"] `
                                    + ' -XX:MaxPermSize' + $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["XX:MaxPermSize"] + '",' +`
                                '"' + $currJMXSettings + '",' + `
                                '"' + "Permissions for: " + $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["catalina.base"] + "`n" `
                                    + $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["FileSystemRights"] + '",' + `
                                '"' + $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["jvmRoute"] + '",' + 
                                '"' + $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["site-ssl-settings"] + '",' + `
                                '"' + $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["session-settings"] + '"' + "`n"
                                
            
            
        }
    }   
}

$strToFile | Out-File $outputFilePath -Append
