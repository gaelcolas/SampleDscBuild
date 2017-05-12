Configuration DSCPULLSRV {

    Import-DscResource -ModuleName xPSDesiredStateConfiguration -ModuleVersion 5.0.0.0
    Import-DscResource -ModuleName xComputerManagement -ModuleVersion 1.8.0.0
    Node $AllNodes.Where{ 
        (Resolve-DscConfigurationProperty -Node $_ -PropertyName MemberOfServices -ErrorAction SilentlyContinue -ResolutionBehavior AllValues) -contains 'DSCPULLSRV'
    }.NodeName
    {
        LocalConfigurationManager
        {
            ConfigurationMode = 'ApplyAndAutoCorrect'
            RebootNodeifNeeded = $node.RebootNodeifNeeded
            CertificateId = $node.Thumbprint
        }

        xComputer NameComputer
        {
            Name = $Node.Name
        }

        Registry TLS1_2ServerEnabled
        {
            Ensure = 'Present'
            Key = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server'
            ValueName = 'Enabled'
            ValueData = 1
            ValueType = 'Dword'
        }

        Registry TLS1_2ServerDisabledByDefault
        {
            Ensure = 'Present'
            Key = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server'
            ValueName = 'DisabledByDefault'
            ValueData = 0
            ValueType = 'Dword'
        }

        Registry TLS1_2ClientEnabled
        {
            Ensure = 'Present'
            Key = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client'
            ValueName = 'Enabled'
            ValueData = 1
            ValueType = 'Dword'
        }

        Registry TLS1_2ClientDisabledByDefault
        {
            Ensure = 'Present'
            Key = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client'
            ValueName = 'DisabledByDefault'
            ValueData = 0
            ValueType = 'Dword'
        }

        Registry SSL2ServerDisabled
        {
            Ensure = 'Present'
            Key = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Server'
            ValueName = 'Enabled'
            ValueData = 0
            ValueType = 'Dword'
        }

        # Install the Windows Server DSC Service feature
        WindowsFeature DSCServiceFeature
        {
            Ensure = 'Present'
            Name = 'DSC-Service'
        }

        $AllRegistrationKeys = (Resolve-DscConfigurationProperty -Node $Node -PropertyName vmid -ErrorAction SilentlyContinue -ResolutionBehavior AllValues) | Select -unique
        
        File RegistrationKeyFile
        {
            Ensure          = 'Present'
            Type            = 'File'
            DestinationPath = Resolve-DscConfigurationProperty -Default "C:\WindowsPowerShell\DscService\RegistrationKeys.txt" -Node $Node -PropertyName RegistrationKeysPath
            Contents        = $AllRegistrationKeys -join "`r`n"
        }

        xDSCWebService PSDSCPullServer 
        {
            DependsOn = '[WindowsFeature]DSCServiceFeature'
            UseSecurityBestPractices = $false
            Ensure = 'Present'
            EndpointName = Resolve-DscConfigurationProperty -Default 'PSDSCPullServer' -Node $Node -PropertyName EndpointName
            Port = Resolve-DscConfigurationProperty -Default 8080 -Node $Node -PropertyName PSDSCPullServer_port
            PhysicalPath = Resolve-DscConfigurationProperty -Default "C:\inetpub\wwwroot\PSDSCPullServer" -Node $Node -PropertyName PhysicalPath
            CertificateThumbPrint = Resolve-DscConfigurationProperty -Default 'CertificateSubject' -Node $Node -PropertyName DSCServiceCertificateThumbPrint
            AcceptSelfSignedCertificates = Resolve-DscConfigurationProperty -Default $true -Node $Node -PropertyName AcceptSelfSignedCertificates
            ModulePath = Resolve-DscConfigurationProperty -Default $true -Node $Node -PropertyName ModulePath
            ConfigurationPath = Resolve-DscConfigurationProperty -Default "X:\DSC\BuildOutput\Configuration" -Node $Node -PropertyName ConfigurationPath
            State = Resolve-DscConfigurationProperty -Default 'Started' -Node $Node -PropertyName State
            RegistrationKeyPath = Split-path -parent (Resolve-DscConfigurationProperty -Default  "C:\WindowsPowerShell\DscService\RegistrationKeys.txt" -Node $Node -PropertyName RegistrationKeysPath)
        }
    }
}