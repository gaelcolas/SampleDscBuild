$DscRoot = join-path "$env:TEMP\kitchen" "modules"


function Get-TempDirectory
{
    [CmdletBinding()]
    [OutputType([System.IO.DirectoryInfo])]
    param ( )

    do
    {
        $tempDir = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ([System.IO.Path]::GetRandomFileName())
    }
    until (-not (Test-Path -Path $tempDir -PathType Container))

    return New-Item -Path $tempDir -ItemType Directory -ErrorAction Stop
}


gci -Directory "$DscRoot\DSC_ConfigurationScripts" | % { Ipmo $_.FullName }

ipmo "$DscRoot\DSC_Tooling\DscConfiguration" -ErrorAction Stop -force
ipmo "$DscRoot\DSC_Tooling\dscbuild" -ErrorAction Stop -force

if ($AvailableCerts = Get-ChildItem Cert:\LocalMachine\My | ? FriendlyName -eq 'DscConfigSecureStoreCertificate') {
    $cert = $AvailableCerts[0]
    Write-verbose "Certificate found for encrypting DSC Credentials locally."
}
else {
    $CreatingNewCert = $true
    . "$DscRoot\DSC_Tooling\New-SelfSignedCertificateEx.ps1" 
    $CertParam = @{
        Subject = 'CN=DscConfigSecureStoreCertificate'
        KeyUsage = 'KeyEncipherment, DataEncipherment'
        SAN = $Env:COMPUTERNAME, 'dscpullsrvcredstore'
        FriendlyName = 'DscConfigSecureStoreCertificate'
        ProviderName = "Microsoft Enhanced RSA and AES Cryptographic Provider"
        Exportable = $true
        StoreLocation = 'LocalMachine'
    }
    $cert = New-SelfSignedCertificateEx @CertParam
}

Set-DscConfigurationCertificate -CertificateThumbprint $cert.Thumbprint

if ($CreatingNewCert) {
    . "$DscRoot\DSC_Tooling\CreateCredentials.ps1"
}

$ConfigurationData = Get-ConfigurationData -Path "$DscRoot\DSC_Configuration" -Force -ErrorAction Stop
     $params = @{
        WorkingDirectory = (Get-TempDirectory).FullName
        SourceResourceDirectory = "$DscRoot\DSC_Resources"
        SourceToolDirectory = "$DscRoot\DSC_Tooling"
        DestinationRootDirectory = "C:\BuildOutput"
        DestinationToolDirectory = $env:TEMP
        ConfigurationData =$ConfigurationData
        ModulePath = "$DscRoot\DSC_Script" , "$DscRoot\DSC_Tooling"
        ConfigurationModuleName = 'MSSQL_BASIC'
        ConfigurationName = 'MSSQL_BASIC'
        Configuration = $true
        Resource = $true
    }
    Invoke-DscBuild @params -verbose -skipDSCResourcesUnitTest

    
Write-Verbose "Configuration Name = $ConfigurationData"
if (-not $ConfigurationName) {
    throw "Configuration Name is not set"
}
elseif ($ConfigurationName -notmatch "^PULL_") {
    $SUT_Node = $ConfigurationData.AllNodes | ? NodeName -match $ConfigurationName
    Write-Verbose "RENAMING NODE $ConfigurationName TO LOCALHOST"
    $SUT_Node.NodeName = 'localhost'
    $SUT_Node.Name = 'localhost'
    ###
    . "$DscRoot\DSC_Tooling\New-SelfSignedCertificateEx.ps1" 
    $DSCCertParameter = @{
        Subject = "CN=DSCPULLSRV" 
        EKU = "Server Authentication", "Client authentication" 
        KeyUsage = "KeyEncipherment, DigitalSignature"
        SAN = (Get-NetIPConfiguration).IPv4Address.IPAddress 
        StoreLocation = "LocalMachine"
        ProviderName = "Microsoft Software Key Storage Provider" 
        SignatureAlgorithm = 'sha256'
    }
    $DSCCert = New-SelfSignedCertificateEx @DSCCertParameter
    
    $SUT_Node.Services.DSCPULLSRV.DSCServiceCertificateThumbPrint = $DSCCert.Thumbprint
    ###
}
else {
    $ConfigurationName = $ConfigurationName -replace "PULL_"
    $SUT_Node = $ConfigurationData.AllNodes | ? NodeName -match $ConfigurationName
    $SUT_Node.NodeName = 'localhost'
    $SUT_Node.Name = 'localhost'

    $SERVER = Resolve-DscConfigurationProperty -Node $SUT_Node -ConfigurationData $ConfigurationData -PropertyName TestKitchen\DscPullServerIP
    $PORT = Resolve-DscConfigurationProperty -DefaultValue 8080 -Node $SUT_Node -ConfigurationData $ConfigurationData -PropertyName TestKitchen\DscPullServerPort
    
    [DSCLocalConfigurationManager()]
    Configuration "PULL_$ConfigurationName" {
        Node localhost {

            Settings
            {
                RefreshMode = 'Pull'
                ConfigurationModeFrequencyMins = 15
                ConfigurationMode = 'ApplyAndAutoCorrect'
                RebootNodeifNeeded = $true
                ActionAfterReboot = 'ContinueConfiguration'
                #CertificateId = $node.Thumbprint
                #ConfigurationID = 'MSSQL_BASIC'
            }

            ConfigurationRepositoryWeb TESTKitchenPULL {
                ServerURL = "https://$($SERVER):$($PORT)/PSDSCPullServer.svc"
                RegistrationKey = Resolve-DscConfigurationProperty -Node $SUT_Node -ConfigurationData $ConfigurationData -PropertyName TestKitchen\RegistrationKey
                ConfigurationNames = @($ConfigurationName)
                AllowUnsecureConnection = $true
            }

            ReportServerWeb CONTOSO-PullSrv {
                ServerURL = "https://$($SERVER):$($PORT)/PSDSCPullServer.svc"
            }
        }
    }
    & "PULL_$ConfigurationName" -ConfigurationData $ConfigurationData -OutputPath 'C:\Configurations' #Complile the Meta MOF
    Set-DscLocalConfigurationManager -ComputerName localhost -Path "C:\Configurations" -verbose
    break
}

 # For each role, create a configuration that will setup a pull: __PULL__CONFIGNAME
 # when Test-Kitchen converges the suite PULL.CONFIGNAME,
 #      - it will register to the PULL server
 #      - configure its LCM to pull the CONFIGNAME 