# Usage .\Get-Base64FromPFX.ps1 -PFXFilePath ".\certs\wildcard_internal_domain_com.pfx" ".\certs\ilbcert"
# Usage .\Get-Base64FromPFX.ps1 -PFXFilePath ".\certs\wildcard_domain_com.pfx" ".\certs\appgwcert"

Param(
    [Parameter(Mandatory = $true)][string] $PFXFilePath,
    [Parameter(Mandatory = $true)][string] $OutputName
)
Write-Host "Loading PFX $PFXFilePath"
Write-Host "You will be prompted for the certificate password now"
$pfx = Get-PfxCertificate -FilePath $PFXFilePath

Write-Host "Outputting thumbprint to $OutputName.pfx.thumbprint.txt"
$pfx.Thumbprint | Out-File "$OutputName.pfx.thumbprint.txt"

Write-Host "Outputting Base64 of the PFX to $OutputName.pfx.b64.txt"
$pfxContentBytes = get-content -encoding byte $PFXFilePath
$pfxContentEncoded = [System.Convert]::ToBase64String($pfxContentBytes)
$pfxContentEncoded | set-content ("$OutputName.pfx.b64.txt")

Write-Host "Converting to DER"
$der = $pfx | Export-Certificate -FilePath "$OutputName.pfx.der" -Type CERT
$cerBytes =  get-content -encoding byte "$OutputName.pfx.der"

Write-Host "Outputting Base64 of the DER to $OutputName.cer.b64.txt"
$cerBytesContentEncoded = [System.Convert]::ToBase64String($cerBytes)
$cerBytesContentEncoded | set-content ("$OutputName.cer.b64.txt")

Write-Host "Deleting temporary DER file"
Remove-Item "$OutputName.pfx.der"