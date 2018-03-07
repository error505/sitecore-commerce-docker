.\Generate-Self-Signed-Certificate.ps1 -dnsName 'commerce.client' -file '.\Files\commerce.pfx' -secret 'secret'

$cert = New-SelfSignedCertificate -certstorelocation cert:\localmachine\my -dnsname 'DO_NOT_TRUST_SitecoreRootCert' -KeyUsage DigitalSignature,CertSign -KeyExportPolicy Exportable -Provider 'Microsoft Enhanced RSA and AES Cryptographic Provider';
$pwd = ConvertTo-SecureString -String 'secret' -Force -AsPlainText;
Export-PfxCertificate -cert $cert -FilePath '.\Files\root.pfx' -Password $pwd;
