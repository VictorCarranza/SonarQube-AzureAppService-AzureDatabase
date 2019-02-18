function log($message) {
    [DateTime]$dateTime = [System.DateTime]::Now
    Write-Output "$($dateTime.ToLongTimeString()) $message" 
}

log('Starting HttpPlatformHandler Script')

$port = $env:HTTP_PLATFORM_PORT
log("HTTP_PLATFORM_PORT is: $port")

$connectionString = $env:SQLAZURECONNSTR_jdbcConnString
$newConnectionString = "sonar.jdbc.url=" + $connectionString
$sqConnStringToReplace = "#?sonar.jdbc.url=jdbc:sqlserver://localhost;databaseName=sonar;integratedSecurity=true"

$connectionUsername = $env:SQLAZURECONNSTR_jdbcUserName
$connectionUsernameStringToReplace = "#?sonar.jdbc.username="
$newconnectionUsername = "sonar.jdbc.username=" + $connectionUsername

$connectionPassword = $env:SQLAZURECONNSTR_jdbcUserPassword
$connectionPasswordStringToReplace = "#?sonar.jdbc.password="
$newconnectionPassword = "sonar.jdbc.password=" + $connectionPassword

log('Searching for sonar.properties file')
$propFile = Get-ChildItem 'sonar.properties' -Recurse
if(!$propFile) {
    log("Could not find sonar.properties")
    exit
}
log("File found at: $($propFile.FullName)")
log("Writing to sonar.properties file")
(Get-Content -Path $propFile.FullName -Raw) | Foreach-Object {
	$_ -replace '$sqConnStringToReplace', "$newConnectionString" `
	   -replace '#?sonar.web.port=.+', "sonar.web.port=$port" `
	   -replace '$connectionUsernameStringToReplace', "$newconnectionUsername" `
	   -replace '$connectionPasswordStringToReplace', "$newconnectionPassword"
	} | Set-Content $propFile.FullName	

log('Searching for wrapper.conf file')
$wrapperConfig = Get-ChildItem 'wrapper.conf' -Recurse
if(!$wrapperConfig) {
    log("Could not find wrapper.conf")
    exit
}
log("File found at: $($wrapperConfig.FullName)")
log("Writing to wrapper.conf file")
$wrapperConfigContents = Get-Content -Path $wrapperConfig.FullName -Raw
$wrapperConfigContents -ireplace 'wrapper.java.command=java', "wrapper.java.command=%JAVA_HOME%\bin\java" | Set-Content -Path $wrapperConfig.FullName

log("Searching for StartSonar.bat")
$startScript = Get-ChildItem 'StartSonar.bat' -Recurse
if(!$startScript) {
    log("Could not find StartSonar.bat")
    exit
}
log("File found at: $($startScript[-1].FullName)")
log("Executing StartSonar.bat")
& $startScript[-1].FullName