Write-Output 'Copy wwwroot folder'
xcopy wwwroot ..\wwwroot /Y

Write-Output 'Setting Security to TLS 1.2'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Write-Output 'Prevent the progress meter from trying to access the console'
$global:progressPreference = 'SilentlyContinue'

Write-Output 'Getting a list of downloads'
$downloadSource = 'https://binaries.sonarsource.com/Distribution/sonarqube/'
$allDownloads = Invoke-WebRequest -Uri $downloadSource -UseBasicParsing
$zipFiles = $allDownloads[0].Links | Where-Object { $_.href.EndsWith('.zip') -and !($_.href.contains('alpha') -or $_.href.contains('RC')) }
$latestFile = $zipFiles[-1]
$downloadUri = $downloadSource + $latestFile.href

Write-Output "Downloading '$downloadUri'"
$outputFile = "..\wwwroot\$($latestFile.href)"
Invoke-WebRequest -Uri $downloadUri -OutFile $outputFile -UseBasicParsing
Write-Output 'Done downloading file'

Write-Output 'Extracting zip'
Expand-Archive -Path $outputFile -DestinationPath ..\wwwroot
Write-Output 'Extraction complete'

Write-Output 'Connection Strings Replacement'
$port = "9000"

$connectionString = $env:SQLAZURECONNSTR_jdbcConnString

$connectionUsername = $env:SQLAZURECONNSTR_jdbcUserName

$connectionPassword = $env:SQLAZURECONNSTR_jdbcUserPassword

$propFile = Get-ChildItem -path '..\wwwroot' -Include 'sonar.properties' -Recurse
if(!$propFile) {
    Write-Output 'Connection Strings Replacement Failed'
    exit
}
(Get-Content -Path $propFile.FullName -Raw) | Foreach-Object {
	$_ -ireplace '#?sonar.jdbc.url=jdbc:sqlserver://localhost;databaseName=sonar;integratedSecurity=true', "sonar.jdbc.url=$connectionString" `
	   -ireplace '#?sonar.web.port=.+', "sonar.web.port=$port" `
	   -ireplace '#?sonar.jdbc.username=.*', "sonar.jdbc.username=$connectionUsername" `
	   -ireplace '#?sonar.jdbc.password=.*', "sonar.jdbc.password=$connectionPassword"
	} | Set-Content $propFile.FullName	

Write-Output 'Connection Strings Replacement complete'