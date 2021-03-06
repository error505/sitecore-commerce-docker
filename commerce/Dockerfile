# escape=`

# Stage 0: prepare files & build prerequisites
FROM microsoft/aspnet:4.7.1-windowsservercore-1709 AS prepare

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

ARG COMMERCE_SIF_PACKAGE
ARG COMMERCE_SDK_PACKAGE
ARG SITECORE_BIZFX_PACKAGE

WORKDIR /Files

ADD files /Files
ADD scripts /Scripts

# Expand installation files
RUN Expand-Archive -Path "/Files/$Env:COMMERCE_SDK_PACKAGE" -DestinationPath '/Files/Sitecore.Commerce.SDK'; 
RUN Expand-Archive -Path "/Files/$Env:COMMERCE_SIF_PACKAGE" -DestinationPath '/Files/SIF.Sitecore.Commerce'; 
RUN Expand-Archive -Path "/Files/$Env:SITECORE_BIZFX_PACKAGE" -DestinationPath '/Files/Sitecore.BizFX'; 

# Stage 1: create actual image
FROM microsoft/aspnet:4.7.1-windowsservercore-1709

ARG HOST_NAME="commerce"
ARG SITECORE_HOSTNAME="sitecore"
ARG SHOP_NAME="CommerceEngineDefaultStorefront"
ARG ENVIRONMENT_NAME="HabitatAuthoring"
ARG COMMERCE_ENGINE_PACKAGE
ARG SITECORE_IDENTITY_PACKAGE
ARG PLUMBER_FILE_NAME="plumber.zip"

ARG SQL_USER="sa"
ARG SQL_SA_PASSWORD
ARG SQL_DB_PREFIX
ARG SQL_SERVER="mssql"
ARG SOLR_PORT=8983
ARG SOLR_CORE_PREFIX="xp0"

ARG XCONNECT_CERT_PATH
ARG SOLR_CERT_PATH
ARG SITECORE_CERT_PATH
ARG COMMERCE_CERT_PATH
ARG ROOT_CERT_PATH

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

WORKDIR /Files

# Copy required files
ADD scripts /Scripts

COPY files/*.pfx /Files/
COPY --from=prepare /Files/Sitecore.Commerce.SDK /Files/Sitecore.Commerce.SDK/
COPY --from=prepare /Files/SIF.Sitecore.Commerce /Files/SIF.Sitecore.Commerce/
COPY --from=prepare /Files/Sitecore.BizFX /Files/Sitecore.BizFX/
COPY --from=prepare /Files/${COMMERCE_ENGINE_PACKAGE} /Files/
COPY --from=prepare /Files/${SITECORE_IDENTITY_PACKAGE} /Files/
COPY --from=prepare /Files/${PLUMBER_FILE_NAME} /Files/

# Trust Self signed certificates
RUN /Scripts/Import-Certificate.ps1 -certificateFile /Files/$Env:SOLR_CERT_PATH -secret 'secret' -storeName 'Root' -storeLocation 'LocalMachine'
RUN /Scripts/Import-Certificate.ps1 -certificateFile /Files/$Env:XCONNECT_CERT_PATH -secret 'secret' -storeName 'Root' -storeLocation 'LocalMachine'
RUN /Scripts/Import-Certificate.ps1 -certificateFile /Files/$Env:SITECORE_CERT_PATH -secret 'secret' -storeName 'Root' -storeLocation 'LocalMachine'
RUN /Scripts/Import-Certificate.ps1 -certificateFile /Files/$Env:COMMERCE_CERT_PATH -secret 'secret' -storeName 'Root' -storeLocation 'LocalMachine'
RUN /Scripts/Import-Certificate.ps1 -certificateFile /Files/$Env:ROOT_CERT_PATH -secret 'secret' -storeName 'Root' -storeLocation 'LocalMachine'

# Import certificate
RUN /Scripts/Import-Certificate.ps1 -certificateFile /Files/$Env:COMMERCE_CERT_PATH -secret 'secret' -storeName 'My' -storeLocation 'LocalMachine'
RUN /Scripts/Import-Certificate.ps1 -certificateFile /Files/$Env:ROOT_CERT_PATH -secret 'secret' -storeName 'My' -storeLocation 'LocalMachine'

# Import XConnect certificate
RUN /Scripts/Import-Certificate.ps1 -certificateFile /Files/$Env:XCONNECT_CERT_PATH -secret 'secret' -storeName 'My' -storeLocation 'LocalMachine'

RUN net user /add commerceuser 'Pa$$w0rd'; `
    Set-LocalUser -Name 'commerceuser' -PasswordNeverExpires:$true

# Install SIF
RUN /Scripts/Install-SIF.ps1

# Configure
RUN [Environment]::SetEnvironmentVariable('PSModulePath', $env:PSModulePath + ';/Files/SIF.Sitecore.Commerce/Modules'); `
    $solrUrl = 'https://solr:{0}/solr' -f $Env:SOLR_PORT; `
    $engineZip = '/Files/{0}' -f $Env:COMMERCE_ENGINE_PACKAGE; `
    Install-SitecoreConfiguration -Path '/Files/SIF.Sitecore.Commerce/Configuration/Commerce/CommerceEngine/CommerceEngine.Deploy.json' `
    -CommerceServicesDbServer $Env:SQL_SERVER `
    -CommerceServicesDbName SitecoreCommerce9_SharedEnvironments `
    -CommerceServicesGlobalDbName SitecoreCommerce9_Global `
    -CommerceServicesPostfix Sc9 `
    -SitecoreDbServer $Env:SQL_SERVER `
    -SitecoreCoreDbName "${$Env:SQL_DB_PREFIX}_Core"`
    -SolrUrl $solrUrl `
    -SearchIndexPrefix $Env:SOLR_CORE_PREFIX `
    -CommerceOpsServicesPort 5015 `
    -CommerceShopsServicesPort 5005 `
    -CommerceAuthoringServicesPort 5000 `
    -CommerceMinionsServicesPort 5010 `
    -SiteHostHeaderName 'sitecore' `
    -UserAccount @{ Domain = $Env:COMPUTERNAME; UserName = 'commerceuser'; Password = 'Pa$$w0rd' } `
    -CommerceEngineDacPac '/Files/Dacpac.dacpac' `
    -SitecoreCommerceEngineZipPath $engineZip `
    -CommerceSearchProvider 'SOLR' `
    -CertificateName 'commerce' `
    -Skip "DeployCommerceDatabase", "AddCommerceUserToCoreDatabase"

RUN [Environment]::SetEnvironmentVariable('PSModulePath', $env:PSModulePath + ';/Files/SIF.Sitecore.Commerce/Modules'); `
    Install-SitecoreConfiguration -Path '/Files/SIF.Sitecore.Commerce/Configuration/Commerce/SitecoreBizFx/SitecoreBizFx.json' `
    -SitecoreBizFxServicesContentPath './Sitecore.BizFX' `
    -CommerceAuthoringServicesPort 5000 `
    -UserAccount @{ Domain = $Env:COMPUTERNAME; UserName = 'commerceuser'; Password = 'Pa$$w0rd' }

RUN [Environment]::SetEnvironmentVariable('PSModulePath', $env:PSModulePath + ';/Files/SIF.Sitecore.Commerce/Modules'); `
    $zip = '/Files/{0}' -f $Env:SITECORE_IDENTITY_PACKAGE; `
    Install-SitecoreConfiguration -Path '/Files/SIF.Sitecore.Commerce/Configuration/Commerce/SitecoreIdentityServer/SitecoreIdentityServer.json' `
    -SitecoreIdentityServerZipPath $zip `
    -SitecoreIdentityServerName 'SitecoreIdentityServer' `
    -SitecoreDbServer $Env:SQL_SERVER `
    -SitecoreCoreDbName "${$Env:SQL_DB_PREFIX}_Core" `
    -UserAccount @{ Domain = $Env:COMPUTERNAME; UserName = 'commerceuser'; Password = 'Pa$$w0rd' }    

# The Commerce SSL bindings are created with DNS localhost in a harcoded way
# Update these to match the host name
RUN $certificates = Get-ChildItem -Path 'cert:\localmachine\my' -DnsName 'DO_NOT_TRUST_SitecoreRootCert'; `
    $rootCert = $certificates[0]; `
    $certificate = New-SelfSignedCertificate -certstorelocation cert:\localmachine\my -dnsname 'commerce' -Signer $rootcert -KeyExportPolicy Exportable -Provider 'Microsoft Enhanced RSA and AES Cryptographic Provider'; `
    Get-WebBinding -Name 'CommerceOps_Sc9' -Protocol 'https' | Remove-WebBinding; `
    New-WebBinding -Name 'CommerceOps_Sc9' -HostHeader $Env:HOST_NAME -Protocol 'https' -SslFlags 1 -Port 5015; `
    $binding = Get-WebBinding -Name 'CommerceOps_Sc9' -Protocol 'https'; `
    $binding.AddSslCertificate($certificate.GetCertHashString(), 'My'); `
    Get-WebBinding -Name 'CommerceShops_Sc9' -Protocol 'https' | Remove-WebBinding; `
    New-WebBinding -Name 'CommerceShops_Sc9' -HostHeader $Env:HOST_NAME -Protocol 'https' -SslFlags 1 -Port 5005; `
    $binding = Get-WebBinding -Name 'CommerceShops_Sc9' -Protocol 'https'; `
    $binding.AddSslCertificate($certificate.GetCertHashString(), 'My'); `
    Get-WebBinding -Name 'CommerceAuthoring_Sc9' -Protocol 'https' | Remove-WebBinding; `
    New-WebBinding -Name 'CommerceAuthoring_Sc9' -HostHeader $Env:HOST_NAME -Protocol 'https' -SslFlags 1 -Port 5000; `
    $binding = Get-WebBinding -Name 'CommerceAuthoring_Sc9' -Protocol 'https'; `
    $binding.AddSslCertificate($certificate.GetCertHashString(), 'My'); `    
    Get-WebBinding -Name 'CommerceMinions_Sc9' -Protocol 'https' | Remove-WebBinding; `
    New-WebBinding -Name 'CommerceMinions_Sc9' -HostHeader $Env:HOST_NAME -Protocol 'https' -SslFlags 1 -Port 5010; `
    $binding = Get-WebBinding -Name 'CommerceMinions_Sc9' -Protocol 'https'; `
    $binding.AddSslCertificate($certificate.GetCertHashString(), 'My'); `        
    Get-WebBinding -Name 'SitecoreBizFx' -Protocol 'https' | Remove-WebBinding; `
    New-WebBinding -Name 'SitecoreBizFx' -HostHeader $Env:HOST_NAME -Protocol 'https' -SslFlags 1 -Port 4200; `
    $binding = Get-WebBinding -Name 'SitecoreBizFx' -Protocol 'https'; `
    $binding.AddSslCertificate($certificate.GetCertHashString(), 'My'); `        
    Get-WebBinding -Name 'SitecoreIdentityServer' -Protocol 'https' | Remove-WebBinding; `
    New-WebBinding -Name 'SitecoreIdentityServer' -HostHeader $Env:HOST_NAME -Protocol 'https' -SslFlags 1 -Port 5050; `
    $binding = Get-WebBinding -Name 'SitecoreIdentityServer' -Protocol 'https'; `
    $binding.AddSslCertificate($certificate.GetCertHashString(), 'My');

ADD commerce/UpdateConnectionString.ps1 /Scripts

RUN /Scripts/UpdateConnectionString.ps1 -folder c:\inetpub\wwwroot\CommerceAuthoring_Sc9 `
    -userName 'sa' `
    -password $Env:SQL_SA_PASSWORD `
    -server $Env:SQL_SERVER; `
    /Scripts/UpdateConnectionString.ps1 -folder c:\inetpub\wwwroot\CommerceMinions_Sc9 `
    -userName 'sa' `
    -password $Env:SQL_SA_PASSWORD `
    -server $Env:SQL_SERVER; `
    /Scripts/UpdateConnectionString.ps1 -folder c:\inetpub\wwwroot\CommerceOps_Sc9 `
    -userName 'sa' `
    -password $Env:SQL_SA_PASSWORD `
    -server $Env:SQL_SERVER; `
    /Scripts/UpdateConnectionString.ps1 -folder c:\inetpub\wwwroot\CommerceShops_Sc9 `
    -userName 'sa' `
    -password $Env:SQL_SA_PASSWORD `
    -server $Env:SQL_SERVER

# Install hosting
RUN Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1')); `
    choco install -y --params="Quiet" dotnetcore-windowshosting

# Install IIS URL Rewrite
RUN choco install -y --params="Quiet" urlrewrite

RUN $pathToAppSettings  = $(Join-Path -Path c:\inetpub\wwwroot\SitecoreIdentityServer\wwwroot -ChildPath "appsettings.json"); `
    $json = Get-Content $pathToAppSettings -raw | ConvertFrom-Json; `
    $connectionString = 'Data Source={0};Initial Catalog=Sitecore_Core;Integrated Security=False;User Id={1};Password={2};' -f $Env:SQL_SERVER, 'sa', $Env:SQL_SA_PASSWORD; `
    $json.AppSettings.SitecoreMembershipOptions.ConnectionString = $connectionString; `
    $json = ConvertTo-Json $json -Depth 100; `
    Set-Content $pathToAppSettings -Value $json -Encoding UTF8;

RUN $hostFileName = 'c:\\windows\\system32\\drivers\\etc\\hosts'; '\"`r`n127.0.0.1`t$Env:HOST_NAME\"' | Add-Content $hostFileName

ADD commerce/UpdateIdentityServerUrl.ps1 /Scripts

RUN /Scripts/UpdateIdentityServerUrl.ps1 -folder c:\inetpub\wwwroot\CommerceAuthoring_Sc9 `
    -hostName $Env:HOST_NAME; `
    /Scripts/UpdateIdentityServerUrl.ps1 -folder c:\inetpub\wwwroot\CommerceMinions_Sc9 `
    -hostName $Env:HOST_NAME; `
    /Scripts/UpdateIdentityServerUrl.ps1 -folder c:\inetpub\wwwroot\CommerceOps_Sc9 `
    -hostName $Env:HOST_NAME; `
    /Scripts/UpdateIdentityServerUrl.ps1 -folder c:\inetpub\wwwroot\CommerceShops_Sc9 `
    -hostName $Env:HOST_NAME;

ADD commerce/UpdateSitecoreUrl.ps1 /Scripts

RUN /Scripts/UpdateSitecoreUrl.ps1 -folder c:\inetpub\wwwroot\CommerceAuthoring_Sc9 `
    -hostName $Env:SITECORE_HOSTNAME; `
    /Scripts/UpdateSitecoreUrl.ps1 -folder c:\inetpub\wwwroot\CommerceMinions_Sc9 `
    -hostName $Env:SITECORE_HOSTNAME; `
    /Scripts/UpdateSitecoreUrl.ps1 -folder c:\inetpub\wwwroot\CommerceOps_Sc9 `
    -hostName $Env:SITECORE_HOSTNAME; `
    /Scripts/UpdateSitecoreUrl.ps1 -folder c:\inetpub\wwwroot\CommerceShops_Sc9 `
    -hostName $Env:SITECORE_HOSTNAME

# Set the certificate details of the certificate sitecore will connect with
RUN $CommerceServicesPathCollection = @('C:\\inetpub\\wwwroot\\CommerceAuthoring_Sc9', 'C:\\inetpub\\wwwroot\\CommerceMinions_Sc9', `
                                       'C:\\inetpub\\wwwroot\\CommerceOps_Sc9', 'C:\\inetpub\\wwwroot\\CommerceShops_Sc9'); `
    $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2; `
    $cert.Import('c:\\Files\\commerce.pfx', 'secret', 'MachineKeySet'); `
    foreach($path in $CommerceServicesPathCollection) { `
        $pathToJson = $(Join-Path -Path $path -ChildPath "wwwroot\config.json"); `
        $originalJson = Get-Content $pathToJson -Raw | ConvertFrom-Json; `
        $certificateNode = $originalJson.Certificates.Certificates[0]; `
		$certificateNode.Thumbprint = $cert.Thumbprint; `
        $appSettingsNode = $originalJson.AppSettings; `
        $appSettingsNode.SitecoreIdentityServerUrl = 'https://commerce:5050'; `
        $appSettingsNode.AllowedOrigins = @('https://commerce:4200','http://commerce:4200','http://sitecore'); `
        $appSettingsNode.AntiForgeryEnabled = $False; `
		$originalJson | ConvertTo-Json -Depth 100 -Compress | set-content $pathToJson; `
    } 

# Configure the business tools
RUN $pathToJson = $(Join-Path -Path 'C:\\inetpub\\wwwroot\\SitecoreBizFx' -ChildPath "assets\\config.json"); `
    $originalJson = Get-Content $pathToJson -Raw | ConvertFrom-Json; `
    $originalJson.EnvironmentName = $Env:ENVIRONMENT_NAME; `
    $originalJson.EngineUri = ('https://{0}:5000' -f $Env:HOST_NAME); `
    $originalJson.IdentityServerUri = ('https://{0}:5050' -f $Env:HOST_NAME); `
    $originalJson.BizFxUri = ('https://{0}:4200' -f $Env:HOST_NAME); `
    $originalJson.ShopName = $Env:SHOP_NAME; `
    $originalJson | ConvertTo-Json -Depth 100 -Compress | set-content $pathToJson;

# Configure the business tools with the correct settings in Identity server
RUN $pathToAppSettings  = $(Join-Path -Path c:\inetpub\wwwroot\SitecoreIdentityServer\wwwroot -ChildPath "appsettings.json"); `
    $json = Get-Content $pathToAppSettings -raw | ConvertFrom-Json; `
    $json.AppSettings.Clients[0].RedirectUris[0] = ('https://{0}:4200' -f $Env:HOST_NAME); `
    $json.AppSettings.Clients[0].RedirectUris[1] = ('https://{0}:4200/?' -f $Env:HOST_NAME); `
    $json.AppSettings.Clients[0].PostLogoutRedirectUris[0] = ('https://{0}:4200' -f $Env:HOST_NAME); `
    $json.AppSettings.Clients[0].PostLogoutRedirectUris[1] = ('https://{0}:4200/?' -f $Env:HOST_NAME); `
    $json.AppSettings.Clients[0].AllowedCorsOrigins[0] = ('https://{0}:4200/' -f $Env:HOST_NAME); `
    $json.AppSettings.Clients[0].AllowedCorsOrigins[1] = ('https://{0}:4200' -f $Env:HOST_NAME); `         
    $json = ConvertTo-Json $json -Depth 100; `
    Set-Content $pathToAppSettings -Value $json -Encoding UTF8;

# Install plumber
RUN Expand-Archive -Path "/Files/$Env:PLUMBER_FILE_NAME" -DestinationPath 'c:\\inetpub\\plumber'; `
    Import-Module -Name WebAdministration; `
    $iisApp = New-Item IIS:\Sites\Plumber -bindings @{protocol='http';bindingInformation='*:4000:' + $Env:HOST_NAME} -physicalPath 'c:\inetpub\plumber'; `
    $pathToJson = $(Join-Path -Path 'C:\\inetpub\\plumber' -ChildPath "static\\config.json"); `
    $originalJson = Get-Content $pathToJson -Raw | ConvertFrom-Json; `
    $originalJson.EngineUri = ('https://{0}:5000' -f $Env:HOST_NAME); `
    $originalJson.IdentityServerUri = ('https://{0}:5050' -f $Env:HOST_NAME); `
    $originalJson.PlumberUri = ('http://{0}:4000' -f $Env:HOST_NAME); `
    $originalJson | ConvertTo-Json -Depth 100 -Compress | set-content $pathToJson; `
    $pathToAppSettings  = $(Join-Path -Path c:\inetpub\wwwroot\SitecoreIdentityServer\wwwroot -ChildPath "appsettings.json"); `
    $json = Get-Content $pathToAppSettings -raw | ConvertFrom-Json; `
    $client = @{}; `
    $client.ClientId = 'Plumber'; `
    $client.ClientName = 'Plumber'; `
    $client.AccessTokenType = 0; `
    $client.AccessTokenLifetimeInSeconds = 3600; `
    $client.IdentityTokenLifetimeInSeconds = 3600; `
    $client.AllowAccessTokensViaBrowser = $true; `
    $client.RequireConsent = $false; `
    $client.RequireClientSecret = $false; `
    $client.AllowedGrantTypes = @('implicit'); `
    $client.AllowedScopes = @('openid', 'dataEventRecords', 'dataeventrecordsscope', 'securedFiles', 'securedfilesscope', 'role', 'EngineAPI'); `
    $client.RedirectUris = @(('http://{0}:4000' -f $Env:HOST_NAME), ('http://{0}:4000/?' -f $Env:HOST_NAME)); `
    $client.PostLogoutRedirectUris = @(('http://{0}:4000' -f $Env:HOST_NAME), ('http://{0}:4000/?' -f $Env:HOST_NAME)); `
    $client.AllowedCorsOrigins = @(('http://{0}:4000' -f $Env:HOST_NAME), ('http://{0}:4000' -f $Env:HOST_NAME)); `
    $json.AppSettings.Clients += $client; `
    $json = ConvertTo-Json $json -Depth 100; `
    Set-Content $pathToAppSettings -Value $json -Encoding UTF8; `
    $CommerceServicesPathCollection = @('C:\\inetpub\\wwwroot\\CommerceAuthoring_Sc9', 'C:\\inetpub\\wwwroot\\CommerceMinions_Sc9', `
                                       'C:\\inetpub\\wwwroot\\CommerceOps_Sc9', 'C:\\inetpub\\wwwroot\\CommerceShops_Sc9'); `
    foreach($path in $CommerceServicesPathCollection) { `
        $pathToJson = $(Join-Path -Path $path -ChildPath "wwwroot\config.json"); `
        $originalJson = Get-Content $pathToJson -Raw | ConvertFrom-Json; `
        $appSettingsNode = $originalJson.AppSettings; `
        $appSettingsNode.AllowedOrigins += ('http://{0}:4000' -f $Env:HOST_NAME); `
		$originalJson | ConvertTo-Json -Depth 100 -Compress | set-content $pathToJson; `    
    }

# Expose Plumber port
EXPOSE 4000

ADD commerce/WatchDirectoryMultiple.ps1 /Scripts
ADD commerce/WatchDefaultDirectories.ps1 /Scripts

ENTRYPOINT /Scripts/WatchDefaultDirectories.ps1
