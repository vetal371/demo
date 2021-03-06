$srvInfo = @{}
$srvInfo["os-name"]
$srvInfo["os-version"]
$srvInfo["os-fullinfo"]
$srvInfo["hostname"]
$srvInfo["default-java-version"]


$srvInfo["tomcat-containers"] = @{}
$srvInfo["tomcat-containers"][$currTomcat.PSChildName] = @{}
$srvInfo["tomcat-containers"][$currTomcat.PSChildName]["containerName"]
$srvInfo["tomcat-containers"][$currTomcat.PSChildName]["Classpath"]
$srvInfo["tomcat-containers"][$currTomcat.PSChildName]["Jvm"]
$srvInfo["tomcat-containers"][$currTomcat.PSChildName]["JvmMs"]
$srvInfo["tomcat-containers"][$currTomcat.PSChildName]["JvmMx"]
$srvInfo["tomcat-containers"][$currTomcat.PSChildName]["JvmSs"]
$srvInfo["tomcat-containers"][$currTomcat.PSChildName]["Options"]
$srvInfo["tomcat-containers"][$currTomcat.PSChildName]["catalina.home"]
$srvInfo["tomcat-containers"][$currTomcat.PSChildName]["catalina.base"]
$srvInfo["tomcat-containers"][$currTomcat.PSChildName]["java.endorsed.dirs"]
$srvInfo["tomcat-containers"][$currTomcat.PSChildName]["java.io.tmpdir"]
$srvInfo["tomcat-containers"][$currTomcat.PSChildName]["java.util.logging.manager"]
$srvInfo["tomcat-containers"][$currTomcat.PSChildName]["java.util.logging.config.file"]
$srvInfo["tomcat-containers"][$currTomcat.PSChildName]["XX:MaxPermSize"]
$srvInfo["tomcat-containers"][$currTomcat.PSChildName]["com.sun.management.jmxremote"]
$srvInfo["tomcat-containers"][$currTomcat.PSChildName]["com.sun.management.jmxremote.port"]
$srvInfo["tomcat-containers"][$currTomcat.PSChildName]["com.sun.management.jmxremote.ssl"]
$srvInfo["tomcat-containers"][$currTomcat.PSChildName]["com.sun.management.jmxremote.authenticate"]
$srvInfo["tomcat-containers"][$currTomcat.PSChildName]["Tomcat-Info"]
$srvInfo["tomcat-containers"][$currTomcat.PSChildName]["Tomcat-Version"]
$srvInfo["tomcat-containers"][$currTomcat.PSChildName]["Tomcat-JVM-Version"]
$srvInfo["tomcat-containers"][$currTomcat.PSChildName]["TomcatService_Description"]
$srvInfo["tomcat-containers"][$currTomcat.PSChildName]["TomcatService_DisplayName"]
$srvInfo["tomcat-containers"][$currTomcat.PSChildName]["TomcatService_ImagePath"]
$srvInfo["tomcat-containers"][$currTomcat.PSChildName]["TomcatService_ObjectName"]
$srvInfo["tomcat-containers"][$currTomcat.PSChildName]["tomcat-server.xml-path"]
            #$srvInfo["tomcat-containers"][$currTomcat.PSChildName]["port"]
            #$srvInfo["tomcat-containers"][$currTomcat.PSChildName]["protocol-type"]
$srvInfo["tomcat-containers"][$currTomcat.PSChildName]["jvmRoute"]

$srvInfo["tomcat-containers"][$currTomcat.PSChildName]["app-xml-configs"]=@()
$srvInfo["tomcat-containers"][$currTomcat.PSChildName]["app-xml-configs"][$i]

$srvInfo["tomcat-containers"][$currTomcat.PSChildName]["app-local-URL"]=@()
$srvInfo["tomcat-containers"][$currTomcat.PSChildName]["app-local-URL"][$i]

$srvInfo["tomcat-containers"][$currTomcat.PSChildName]["site-URL"]=@()
$srvInfo["tomcat-containers"][$currTomcat.PSChildName]["site-URL"][$i]

$srvInfo["tomcat-containers"][$currTomcat.PSChildName]["app-xml-config-path"]=@()
$srvInfo["tomcat-containers"][$currTomcat.PSChildName]["app-xml-config-path"][$i]

