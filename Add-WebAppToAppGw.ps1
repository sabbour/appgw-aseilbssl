# End-to-End SSL
# .\Add-WebAppToAppGw.ps1 -ResourceGroupName "appgw-aseilbssl3" -ApplicationGatewayName "appgw" -BackendPoolName "ase_pool" -BackendIPAddress "172.16.3.9" -BackendFQDN "webapp1.internal.sabbour.pw" -WebappName "webapp1" -FrontendHost "ssle2e" -FrontendRootZoneName "sabbour.pw" -FrontendSSLCertificateName "wildcard-frontend-sslcertificate" -BackendSSLCertificateThumbprint "E9378D10723A3335556408F1FE4E56D81F501F86" -BackendWhitelistSSLCertificateFile "C:\Users\asabbour\Documents\Git\appgw-aseilbssl\certs\wildcard_sabbour_pw.cer" -SSLEndToEnd

# SSL Termination
# .\Add-WebAppToAppGw.ps1 -ResourceGroupName "appgw-aseilbssl3" -ApplicationGatewayName "appgw" -BackendPoolName "ase_pool" -BackendIPAddress "172.16.3.9" -BackendFQDN "webapp1.internal.sabbour.pw" -WebappName "webapp1" -FrontendHost "ssloffload" -FrontendRootZoneName "sabbour.pw" -FrontendSSLCertificateName "wildcard-frontend-sslcertificate" -SSLTermination

Param(
    [Parameter(Mandatory = $true)][string] $ResourceGroupName,
    [Parameter(Mandatory = $true)][string] $ApplicationGatewayName,
    [Parameter(Mandatory = $false)][string] $BackendPoolName = "ase-pool",
    [Parameter(Mandatory = $true)][string] $BackendIPAddress,
    [Parameter(Mandatory = $true)][string] $BackendFQDN,
    [Parameter(Mandatory = $true)][string] $WebappName,
    [Parameter(Mandatory = $true)][string] $FrontendHost,
    [Parameter(Mandatory = $true)][string] $FrontendRootZoneName,
    [Parameter(Mandatory = $false)][string] $FrontendSSLCertificateName,
    [Parameter(Mandatory = $false)][string] $BackendSSLCertificateThumbprint,
    [Parameter(Mandatory = $false)] $BackendWhitelistSSLCertificateFile,
    [switch] $SSLOnly,
    [switch] $SSLEndToEnd,
    [switch] $SSLTermination,
    [switch] $NoDNS
)

# Define names
$FrontendFQDN = $FrontendHost+"."+$FrontendRootZoneName
$frontendPortHttpName = "appgw-frontendPort-http"
$frontendPortHttpsName = "appgw-frontendPort-https"
$fqdnListnerHttpName = "${FrontendFQDN}-listener-http"
$fqdnListnerHttpsName = "${FrontendFQDN}-listener-https"
$backendHttpProbeName = "${FrontendFQDN}-${BackendFQDN}-probe-http"
$backendHttpsProbeName = "${FrontendFQDN}-${BackendFQDN}-probe-https"
$backendHttpSettingName = "${FrontendFQDN}-${BackendFQDN}-backendsetting-http"
$backendHttpsSettingName = "${FrontendFQDN}-${BackendFQDN}-backendsetting-https"
$backendHttpRuleName = "${FrontendFQDN}-${BackendFQDN}-rule-http"
$backendHttpsRuleName = "${FrontendFQDN}-${BackendFQDN}-rule-https"
$backendHttpsTerminationRuleName = "${FrontendFQDN}-${BackendFQDN}-rule-offload-https"

$placeholderBackendPoolName = "placeholder_pool"
$placeholderHttpSettingName = "placeholder-setting-http"
$placeholderHttpListenerName = "placeholder-listener-http"
$placeholderHttpRuleName = "placeholder-rule"

# Load the application gateway
Write-Host -foregroundcolor Magenta "SSL Only switch: $SSLOnly"
Write-Host -foregroundcolor Magenta "SSLEndToEnd switch: $SSLEndToEnd"
Write-Host -foregroundcolor Magenta "SSLTermination switch: $SSLTermination"

# Quick sanity checks
if($SSLOnly -and !($SSLEndToEnd -or $SSLTermination)) {
    Write-Host -foregroundcolor Red "Invalid state: You requested SSL only but you didn't specify the SSL Mode. You need to pass in either -SSLEndToEnd or -SSLTermination."
    Exit 1
}
if($SSLEndToEnd -and $SSLTermination) {
    Write-Host -foregroundcolor Red "Invalid state: You requested both SSL End-to-End and SSL Termination. You need to pass in either -SSLEndToEnd or -SSLTermination but not both."
    Exit 1
}


Write-Host "Getting Application Gateway '$ApplicationGatewayName' details`n"
$appgw = Get-AzureRmApplicationGateway -ResourceGroupName $ResourceGroupName -Name $ApplicationGatewayName -ErrorAction Stop

# Clean up the placeholder Backend Pool created with the ARM template, as it will interfere with the proper operations
Write-Host -foregroundcolor Yellow "Checking if Placeholder Backend Pool '$placeholderBackendPoolName' exists"
$placeholderPool = $appgw.BackendAddressPools | Where-Object {$_.Name -eq $placeholderBackendPoolName}
if($placeholderPool) {
    Write-Host -foregroundcolor Cyan "`tIt exist. Deleting it."  
	$appgw = Remove-AzureRmApplicationGatewayBackendAddressPool -ApplicationGateway $appgw -Name $placeholderBackendPoolName
}
else {
    Write-Host -foregroundcolor Green "`tBackend Pool '$placeholderBackendPoolName' doesn't exist. Moving on."  
}

# Clean up the placeholder Http Setting created with the ARM template, as it will interfere with the proper operations
Write-Host -foregroundcolor Yellow "Checking if Placeholder HTTP Setting '$placeholderHttpSettingName' exists"
$placeholderHttpSetting = $appgw.BackendHttpSettingsCollection | Where-Object {$_.Name -eq $placeholderHttpSettingName}
if($placeholderHttpSetting) {
    Write-Host -foregroundcolor Cyan "`tIt exist. Deleting it."  
	$appgw = Remove-AzureRmApplicationGatewayBackendHttpSettings -ApplicationGateway $appgw -Name $placeholderHttpSettingName
}
else {
    Write-Host -foregroundcolor Green "`tHTTP Setting '$placeholderBackendPoolName' doesn't exist. Moving on."  
}

# Clean up the placeholder Http Listener created with the ARM template, as it will interfere with the proper operations
Write-Host -foregroundcolor Yellow "Checking if Placeholder HTTP Listener '$placeholderHttpListenerName' exists"
$placeholderHttpListener = $appgw.HttpListeners | Where-Object {$_.Name -eq $placeholderHttpListenerName}
if($placeholderHttpListener) {
    Write-Host -foregroundcolor Cyan "`tIt exist. Deleting it."  
	$appgw = Remove-AzureRmApplicationGatewayHttpListener -ApplicationGateway $appgw -Name $placeholderHttpListenerName
}
else {
    Write-Host -foregroundcolor Green "`tHTTP Listener '$placeholderHttpListenerName' doesn't exist. Moving on."  
}

# Clean up the placeholder Request Routing Rule created with the ARM template, as it will interfere with the proper operations
Write-Host -foregroundcolor Yellow "Checking if Placeholder Request Routing Rule '$placeholderHttpRuleName' exists"
$placeholderRule = $appgw.RequestRoutingRules | Where-Object {$_.Name -eq $placeholderHttpRuleName}
if($placeholderRule) {
    Write-Host -foregroundcolor Cyan "`tIt exist. Deleting it."  
	$appgw = Remove-AzureRmApplicationGatewayRequestRoutingRule -ApplicationGateway $appgw -Name $placeholderHttpRuleName
}
else {
    Write-Host -foregroundcolor Green "`tRequest Routing Rule '$placeholderHttpRuleName' doesn't exist. Moving on."  
}

# Try to get the pool by name. If it doesn't exist, create it with its backend ip address
Write-Host -foregroundcolor Yellow "Checking if Backend Pool '$BackendPoolName' exists"
$pool = $appgw.BackendAddressPools | Where-Object {$_.Name -eq $BackendPoolName}
if(!$pool) {
    Write-Host -foregroundcolor Cyan "`tIt doesn't exist. Creating Backend Pool '$BackendPoolName'"        
    $pool = New-AzureRmApplicationGatewayBackendAddressPool -Name $BackendPoolName
}
else {
    Write-Host -foregroundcolor Green "`tBackend Pool '$BackendPoolName' exists"  
}

# Check if the existing (or just created) pool contains the Backend IP address
Write-Host -foregroundcolor Yellow "Checking if Backend Pool '$BackendPoolName' contains Backend IP '$BackendIPAddress'"    
$backendAddressExists = $pool | Where-Object {$_.BackendAddresses | Where-Object {$_.IpAddress -eq $BackendIPAddress}}
if(!$backendAddressExists) {
    # Add the IP to the pool's Backend IPs
    Write-Host -foregroundcolor Cyan "`tAdding Backend IP '$BackendIPAddress' to Backend Pool '$BackendPoolName'"    
    $appgw = Add-AzureRmApplicationGatewayBackendAddressPool -ApplicationGateway $appgw -Name $BackendPoolName -BackendIPAddresses $BackendIPAddress
	$pool = $appgw.BackendAddressPools | Where-Object {$_.Name -eq $BackendPoolName}
}
else {
    Write-Host -foregroundcolor Green "`tBackend Pool '$BackendPoolName' contains Backend IP '$BackendIPAddress'"  
}

# Public Frontend IP Configuration
$fipConfig = $appgw.FrontendIPConfigurations | Where-Object {$_.PublicIPAddress -ne $null}

# Non-SSL operations, executed if the SSL Only flag is false
if(!$SSLOnly) {
    Write-Host -foregroundcolor Magenta "`nRunning through Non-SSL functionality.."
    # Get listeners for hostname
    $listenerHttp = $appgw.HttpListeners | Where-Object {$_.Name -eq $fqdnListnerHttpName}

    # If HTTP listener doesn't exist and we didn't pass the SSL only switch, create it
    Write-Host -foregroundcolor Yellow "`tChecking if HTTP Listener exists for frontend FQDN '$FrontendFQDN'."
    if(!$listenerHttp) {
        Write-Host -foregroundcolor Cyan "`t`tNo HTTP Listener exists for '$FrontendFQDN'. Creating it."    
        $fpHttp = $appgw.FrontendPorts| Where-Object {$_.Port -eq 80}
        if(!$fpHttp) {
            Write-Host -foregroundcolor Cyan "`tCreating Frontend Port 80" 
            $appgw = Add-AzureRmApplicationGatewayFrontendPort -ApplicationGateway $appgw -Name $frontendPortHttpName -Port 80
            $fpHttp = $appgw.FrontendPorts| Where-Object {$_.Name -eq $frontendPortHttpName}
        }
        $appgw = Add-AzureRmApplicationGatewayHttpListener -ApplicationGateway $appgw -Name $fqdnListnerHttpName -Protocol Http -FrontendIPConfiguration $fipconfig -FrontendPort $fpHttp -HostName $FrontendFQDN
        $listenerHttp = $appgw.HttpListeners | Where-Object {$_.Name -eq $fqdnListnerHttpName}    
    }
    else {
        Write-Host -foregroundcolor Green "`t`tHTTP Listener exists for '$FrontendFQDN'."  
    }
    
    # Get probes for backend
    $probeHttp = $appgw.Probes | Where-Object {$backendHttpProbeName}

    # If HTTP probe doesn't exist and we didn't pass the SSL only switch, create it
    Write-Host -foregroundcolor Yellow "`tChecking if HTTP Probe exists for backend FQDN '$BackendFQDN'."
    if(!$probeHttp) {
        Write-Host -foregroundcolor Cyan "`t`tNo HTTP Probe exists for '$BackendFQDN'. Creating it."        
        $appgw = Add-AzureRmApplicationGatewayProbeConfig -ApplicationGateway $appgw -Name $backendHttpProbeName -Protocol Http -HostName $BackendFQDN -Path "/" -Interval 30 -Timeout 120 -UnhealthyThreshold 8
		$probeHttp = $appgw.Probes | Where-Object {$backendHttpProbeName}
    }
    else {
        Write-Host -foregroundcolor Green "`t`tHTTP Probe exists for '$BackendFQDN'."  
    }

    # Get backend setting associated with probe
    $backendSettingHttp = $appgw.BackendHttpSettingsCollection | Where-Object {$_.Name -eq $backendHttpSettingName}

    Write-Host -foregroundcolor Yellow "`tChecking if HTTP Backend Setting exists for the created probe."
    if(!$backendSettingHttp) {
        Write-Host -foregroundcolor Cyan "`t`tNo HTTP Backend Setting exists for HTTP probe. Creating it."        
        $appgw = Add-AzureRmApplicationGatewayBackendHttpSettings -ApplicationGateway $appgw -Name $backendHttpSettingName -Port 80 -Protocol Http -CookieBasedAffinity Disabled -Probe $probeHttp -RequestTimeout 30
        $backendSettingHttp = $appgw.BackendHttpSettingsCollection| Where-Object {$_.Name -eq $backendHttpSettingName}
    }
    else {
        Write-Host -foregroundcolor Green "`t`tHTTP Backend Setting exists for probe."  
    }

     # Finally, create the rule if it doesn't exist
    Write-Host -foregroundcolor Yellow "`tChecking if Request Routing Rule exists for the pool, listener and backend setting combination."
    $ruleHttp = $appgw.RequestRoutingRules | Where-Object {$_.Name -eq $backendHttpRuleName}
    if(!$ruleHttp) {
        Write-Host -foregroundcolor Cyan "`t`tNo Request Routing Rule exists for the pool, listener and backend setting combination. Creating it."        
        $appgw = Add-AzureRmApplicationGatewayRequestRoutingRule -ApplicationGateway $appgw -Name $backendHttpRuleName -RuleType basic -BackendHttpSettings $backendSettingHttp -HttpListener $listenerHttp -BackendAddressPool $pool    
        $ruleHttp = $appgw.RequestRoutingRules | Where-Object {$_.Name -eq $backendHttpRuleName}
    }
    else {        
        Write-Host -foregroundcolor Green "`t`tBackend HTTP Setting exists for this probe."  
    }
}



# SSL operations, executed if SSLEndToEnd or SSLTermination flags are true
if($SSLEndToEnd -or $SSLTermination) {
    Write-Host -foregroundcolor Magenta "`nRunning through SSL functionality.."

    # Get listeners for hostname
    $listenerHttps = $appgw.HttpListeners | Where-Object {$_.Name -eq $fqdnListnerHttpsName}

    # If the HTTPS listener doesn't exist and we passed in either SSL End to End or SSL Termination switches, create it
    Write-Host -foregroundcolor Yellow "`tChecking if HTTPS Listener exists for frontend FQDN '$FrontendFQDN'."
    if(!$listenerHttps) {
        Write-Host -foregroundcolor Cyan "`t`tNo HTTPS Listener exists for '$FrontendFQDN'. Creating it with SSL certificate named '$FrontendSSLCertificateName'"        
        $cert = $appgw.SslCertificates | Where-Object {$_.Name -eq $FrontendSSLCertificateName}
        $fpHttps = $appgw.FrontendPorts| Where-Object {$_.Port -eq 443}
        if(!$fpHttps) {
            Write-Host -foregroundcolor Green "`tCreating Frontend Port 443" 
            $appgw = Add-AzureRmApplicationGatewayFrontendPort -ApplicationGateway $appgw -Name $frontendPortHttpsName  -Port 443
            $fpHttps = $appgw.FrontendPorts| Where-Object {$_.Name -eq $frontendPortHttpsName}
        }
        $appgw = Add-AzureRmApplicationGatewayHttpListener -ApplicationGateway $appgw -Name $fqdnListnerHttpsName -Protocol Https -FrontendIPConfiguration $fipconfig -FrontendPort $fpHttps -HostName $FrontendFQDN -RequireServerNameIndication true -SslCertificate $cert
        $listenerHttps = $appgw.HttpListeners | Where-Object {$_.Name -eq $fqdnListnerHttpsName}
    }
    else {
        Write-Host -foregroundcolor Green "`t`tHTTPS Listener exists for '$FrontendFQDN'."  
    }

    # Now it is time to check the SSL mode requested
    # MODE: SSL End to End
    if($SSLEndToEnd) {
        Write-Host -foregroundcolor Magenta "`n`tRunning through End-to-End SSL functionality.."        
        # Get probes for backend. Probe will be SSL since we're doing end-to-end SSL.
        $probeHttps = $appgw.Probes | Where-Object {$_.Name -eq $backendHttpsProbeName}

        # If HTTPS probe doesn't exist, create it
        Write-Host -foregroundcolor Yellow "`t`tChecking if HTTPS Probe exists for backend FQDN '$BackendFQDN'."
        if(!$probeHttps) {
            Write-Host -foregroundcolor Cyan "`t`t`tNo HTTPS Probe exists for '$BackendFQDN'. Creating it."        
            $appgw = Add-AzureRmApplicationGatewayProbeConfig -ApplicationGateway $appgw -Name $backendHttpsProbeName -Protocol Https -HostName $BackendFQDN -Path "/" -Interval 30 -Timeout 120 -UnhealthyThreshold 8
            $probeHttps = $appgw.Probes | Where-Object {$_.Name -eq $backendHttpsProbeName}
        }
        else {
            Write-Host -foregroundcolor Green "`t`t`tHTTPS Probe exists for '$BackendFQDN'."  
        }

        Write-Host -foregroundcolor Yellow "`t`tEnd-to-End SSL was requested. Will check if the backend authentication certificate exists, otherwise will create it."

        # Load the backend authentication certificate from disk (use the command below to parse it into a comparable object)
        $authcert = New-AzureRmApplicationGatewayAuthenticationCertificate -Name "ase-ilb-sslcertificate" -CertificateFile $BackendWhitelistSSLCertificateFile
        if(!$authcert) {
            Write-Host -foregroundcolor Red "Invalid state: End to end SSL requested but unable to load Backend Authentication Certificate from path '$BackendWhitelistSSLCertificateFile'. Did you miss to pass the -BackendWhitelistSSLCertificateFile parameter?"
            Exit 1
        }

        # Try and find a matching certificate on the Application Gateway
        $backendAuthCertificate = $appgw.AuthenticationCertificates | Where-Object { $_.Data -eq $authcert.Data }
        if(!$backendAuthCertificate) {
            Write-Host -foregroundcolor Cyan "`t`t`tBackend Authentication Certificate doesn't exist. Creating it."
            $appgw = Add-AzureRmApplicationGatewayAuthenticationCertificate -ApplicationGateway $appgw -Name "ase-ilb-sslcertificate" -CertificateFile $BackendWhitelistSSLCertificateFile
        }
        else {        
            Write-Host -foregroundcolor Green "`t`t`tBackend Authentication Certificate exists."  
        }
        
        # Now that we have the certificate in place, create the probe and bind them using an HTTP setting
        # Get backend setting associated with HTTPS probe. 
        $backendSettingHttps = $appgw.BackendHttpSettingsCollection | Where-Object {$_.Name -eq $backendHttpsSettingName}

        Write-Host -foregroundcolor Yellow "`t`tChecking if HTTPS Backend Setting exists for the created probe."
        if(!$backendSettingHttps) {
            Write-Host -foregroundcolor Cyan "`t`t`tNo HTTPS Backend Setting exists for HTTP probe. Creating End-to-End SSL setting."        
            $appgw = Add-AzureRmApplicationGatewayBackendHttpSettings -ApplicationGateway $appgw -Name $backendHttpsSettingName -Port 443 -AuthenticationCertificates $authcert -Protocol Https -CookieBasedAffinity Disabled -Probe $probeHttps -RequestTimeout 30
            $backendSettingHttps = $appgw.BackendHttpSettingsCollection| Where-Object {$_.Name -eq $backendHttpsSettingName}
        }
        else {        
            Write-Host -foregroundcolor Green "`t`t`tBackend HTTPS Setting exists for this probe."  
        }

        # Finally, create the rule if it doesn't exist
        Write-Host -foregroundcolor Yellow "`t`tChecking if Request Routing Rule exists for the pool, listener and backend setting combination."
        $ruleHttps = $appgw.RequestRoutingRules | Where-Object {$_.Name -eq $backendHttpsRuleName}
        if(!$ruleHttps) {
            Write-Host -foregroundcolor Cyan "`t`t`tNo Request Routing Rule exists for the pool, listener and backend setting combination. Creating it."        
            $appgw = Add-AzureRmApplicationGatewayRequestRoutingRule -ApplicationGateway $appgw -Name $backendHttpsRuleName -RuleType basic -BackendHttpSettings $backendSettingHttps -HttpListener $listenerHttps -BackendAddressPool $pool    
            $ruleHttps = $appgw.RequestRoutingRules | Where-Object {$_.Name -eq $backendHttpsRuleName}
        }
        else {        
            Write-Host -foregroundcolor Green "`t`t`tBackend HTTPS Setting exists for this probe."  
        }
    }
    # MODE: SSL Termination
    elseif($SSLTermination) {
        Write-Host -foregroundcolor Magenta "`n`tRunning through SSL Termination functionality.."

        # Get probes for backend. Probe will be non-SSL since we're doing SSL termination on the gateway
        $probeHttp = $appgw.Probes | Where-Object {$_.Name -eq $backendHttpProbeName}

        # If HTTP probe doesn't exist, create it
        Write-Host -foregroundcolor Yellow "`t`tChecking if HTTP Probe exists for backend FQDN '$BackendFQDN'."
        if(!$probeHttp) {
            Write-Host -foregroundcolor Cyan "`t`t`tNo HTTP Probe exists for '$BackendFQDN'. Creating it."        
            $appgw = Add-AzureRmApplicationGatewayProbeConfig -ApplicationGateway $appgw -Name $backendHttpProbeName -Protocol Http -HostName $BackendFQDN -Path "/" -Interval 30 -Timeout 120 -UnhealthyThreshold 8
            $probeHttp = $appgw.Probes | Where-Object {$_.Name -eq $backendHttpProbeName}
        }
        else {
            Write-Host -foregroundcolor Green "`t`t`tHTTP Probe exists for '$BackendFQDN'."  
        }
        
        # Get backend setting associated with HTTP probe. 
        $backendSettingHttp = $appgw.BackendHttpSettingsCollection | Where-Object {$_.Name -eq $backendHttpSettingName}

        Write-Host -foregroundcolor Yellow "`t`tChecking if HTTP Backend Setting exists for the created probe."
        if(!$backendSettingHttp) {
            Write-Host -foregroundcolor Cyan "`t`t`tNo HTTP Backend Setting exists for HTTP probe. Creating it."        
            $appgw = Add-AzureRmApplicationGatewayBackendHttpSettings -ApplicationGateway $appgw -Name $backendHttpSettingName -Port 80 -Protocol Http -CookieBasedAffinity Disabled -Probe $probeHttp -RequestTimeout 30
            $backendSettingHttp = $appgw.BackendHttpSettingsCollection| Where-Object {$_.Name -eq $backendHttpSettingName}
        }
        else {        
            Write-Host -foregroundcolor Green "`t`t`tBackend HTTP Setting exists for this probe."  
        }

        # Finally, create the rule if it doesn't exist
        Write-Host -foregroundcolor Yellow "`t`tChecking if Request Routing Rule exists for the pool, listener and backend setting combination."
        $ruleHttpOffload = $appgw.RequestRoutingRules | Where-Object {$_.Name -eq $backendHttpsTerminationRuleName}
        if(!$ruleHttpOffload) {
            Write-Host -foregroundcolor Cyan "`t`t`tNo Request Routing Rule exists for the pool, listener and backend setting combination. Creating it."        
            $appgw = Add-AzureRmApplicationGatewayRequestRoutingRule -ApplicationGateway $appgw -Name $backendHttpsTerminationRuleName -RuleType basic -BackendHttpSettings $backendSettingHttp -HttpListener $listenerHttps -BackendAddressPool $pool    
            $ruleHttpOffload = $appgw.RequestRoutingRules | Where-Object {$_.Name -eq $backendHttpsTerminationRuleName}
        }
        else {        
            Write-Host -foregroundcolor Green "`t`t`tBackend HTTP Setting exists for this probe."  
        }
    }
}

# Make sure that the web app is configured to accept requests from this FrontendFQDN
Write-Host -foregroundcolor Yellow "`nMaking sure the Azure Web App is configured to accept requests from '$FrontendFQDN'.."
$webapp = Get-AzureRmWebApp -ResourceGroupName $ResourceGroupName -Name $WebappName
$frontendFQDNIsEnabled =  $webapp.HostNames -contains $FrontendFQDN
if(!$frontendFQDNIsEnabled) {
    Write-Host -foregroundcolor Cyan "`tAdding '$FrontendFQDN' to HostNames"            
    $webapp.HostNames.Add($FrontendFQDN)
    $webapp = Set-AzureRmWebApp -ResourceGroupName $ResourceGroupName -Name $WebappName -HostNames $webapp.HostNames
    Write-Host -foregroundcolor Cyan "`tConfiguring SSL Binding for '$FrontendFQDN'" 
	New-AzureRmWebAppSSLBinding -ResourceGroupName $ResourceGroupName -WebAppName $WebappName -Thumbprint $BackendSSLCertificateThumbprint -Name $FrontendFQDN
}
else {
    Write-Host -foregroundcolor Green "`tHostname already enabled."  
}

# Make sure that the web app has the SSL Binding for the domain, in case we're using End-to-End SSL
if($SSLEndToEnd) {
	Write-Host -foregroundcolor Yellow "`nMaking sure the Azure Web App has an SSL Binding for '$FrontendFQDN'.."
	$sslBinding = Get-AzureRmWebAppSSLBinding -ResourceGroupName $ResourceGroupName -WebappName $WebappName -Name $FrontendFQDN
	if(!$sslBinding) {
		Write-Host -foregroundcolor Cyan "`tConfiguring SSL Binding for '$FrontendFQDN'"        
		$sslBinding = New-AzureRmWebAppSSLBinding -ResourceGroupName $ResourceGroupName -WebAppName $WebappName -Thumbprint $BackendSSLCertificateThumbprint -Name $FrontendFQDN
	}
	else {
		Write-Host -foregroundcolor Green "`tSSL Binding already exists."  
	}
}

# Set DNS A records pointing the FQDN to the Frontend IP of the Application Gateway, only if the NoDNS flag is not passed
if(!$NoDNS) {
	Write-Host -foregroundcolor Yellow "`nChecking if there is an A Record for '$FrontendHost' in zone '$FrontendRootZoneName'"
	$aRecord = Get-AzureRmDnsRecordSet -ResourceGroupName $ResourceGroupName -RecordType A -Name $FrontendHost -ZoneName $FrontendRootZoneName
	if(!$aRecord) {
		Write-Host -foregroundcolor Cyan "`tSetting DNS A Record for '$FrontendHost' in zone '$FrontendRootZoneName'"  
		New-AzureRmDnsRecordSet -Name $FrontendHost -RecordType A -ZoneName $FrontendRootZoneName -ResourceGroupName $ResourceGroupName -Ttl 3600 -DnsRecords (New-AzureRmDnsRecordConfig -IPv4Address $appgwPublicIp.IpAddress)
	}
	else {
		Write-Host -foregroundcolor Green "`tA Record already exists."  
	}
}

# Update the configuration
Write-Host "`nUpdating Application Gateway configuration.."
$appgw = $appgw | Set-AzureRmApplicationGateway

# Done
Write-Host "`nDone!"