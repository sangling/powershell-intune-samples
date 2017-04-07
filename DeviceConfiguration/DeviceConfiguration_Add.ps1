﻿
<#
 
.COPYRIGHT
Copyright (c) Microsoft Corporation. All rights reserved. Licensed under the MIT license.
See LICENSE in the project root for license information.

#>

####################################################
 
function Get-AuthToken {

<#
.SYNOPSIS
This function is used to authenticate with the Graph API REST interface
.DESCRIPTION
The function authenticate with the Graph API Interface with the tenant name
.EXAMPLE
Get-AuthToken
Authenticates you with the Graph API interface
.NOTES
NAME: Get-AuthToken
.REFERENCE
Acknowledgement to Paolo Marques
https://blogs.technet.microsoft.com/paulomarques/2016/03/21/working-with-azure-active-directory-graph-api-from-powershell/

#>

[cmdletbinding()]

param
(
    [Parameter(Mandatory=$true)]
    $TenantName
)
 
$adal = "${env:ProgramFiles(x86)}\Microsoft SDKs\Azure\PowerShell\ServiceManagement\Azure\Services\Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
 
$adalforms = "${env:ProgramFiles(x86)}\Microsoft SDKs\Azure\PowerShell\ServiceManagement\Azure\Services\Microsoft.IdentityModel.Clients.ActiveDirectory.WindowsForms.dll"
 
    if((test-path "$adal") -eq $false){
 
    write-host
    write-host "Azure Powershell module not installed..." -f Red
    write-host "Please install Azure SDK for Powershell - https://azure.microsoft.com/en-us/downloads/" -f Yellow
    write-host "Script can't continue..." -f Red
    write-host
    exit
 
    }
 
[System.Reflection.Assembly]::LoadFrom($adal) | Out-Null
 
[System.Reflection.Assembly]::LoadFrom($adalforms) | Out-Null
 
$clientId = "1950a258-227b-4e31-a9cf-717495945fc2"
 
$redirectUri = "urn:ietf:wg:oauth:2.0:oob"
 
$resourceAppIdURI = "https://graph.microsoft.com"
 
$authority = "https://login.windows.net/$TenantName"
 
    try {

    $authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $authority
 
    # https://msdn.microsoft.com/en-us/library/azure/microsoft.identitymodel.clients.activedirectory.promptbehavior.aspx
    # Change the prompt behaviour to force credentials each time: Auto, Always, Never, RefreshSession

    $authResult = $authContext.AcquireToken($resourceAppIdURI,$clientId,$redirectUri, "Always")

        # Building Rest Api header with authorization token
        $authHeader = @{
        'Content-Type'='application\json'
        'Authorization'=$authResult.CreateAuthorizationHeader()
        'ExpiresOn'=$authResult.ExpiresOn
        }

    return $authHeader

    }

    catch {

    write-host $_.Exception.Message -f Red
    write-host $_.Exception.ItemName -f Red
    write-host
    break

    }

}
 
####################################################

Function Add-DeviceConfigurationPolicy(){

<#
.SYNOPSIS
This function is used to add an device configuration policy using the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and adds a device configuration policy
.EXAMPLE
Add-DeviceConfigurationPolicy -JSON $JSON
Adds a device configuration policy in Intune
.NOTES
NAME: Add-DeviceConfigurationPolicy
#>

[cmdletbinding()]

param
(
    $JSON
)

$graphApiVersion = "Beta"
$DCP_resource = "deviceManagement/deviceConfigurations"
Write-Verbose "Resource: $DCP_resource"

    try {

        if($JSON -eq "" -or $JSON -eq $null){

        write-host "No JSON specified, please specify valid JSON for the Android Policy..." -f Red

        }

        else {

        Test-JSON -JSON $JSON

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($DCP_resource)"
        Invoke-RestMethod -Uri $uri -Headers $authToken -Method Post -Body $JSON -ContentType "application/json"

        }

    }

    catch {

    $ex = $_.Exception
    $errorResponse = $ex.Response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($errorResponse)
    $reader.BaseStream.Position = 0
    $reader.DiscardBufferedData()
    $responseBody = $reader.ReadToEnd();
    Write-Host "Response content:`n$responseBody" -f Red
    Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
    write-host
    break

    }

}

####################################################

Function Test-JSON(){

<#
.SYNOPSIS
This function is used to test if the JSON passed to a REST Post request is valid
.DESCRIPTION
The function tests if the JSON passed to the REST Post is valid
.EXAMPLE
Test-JSON -JSON $JSON
Test if the JSON is valid before calling the Graph REST interface
.NOTES
NAME: Test-AuthHeader
#>

param (

$JSON

)

    try {

    $TestJSON = ConvertFrom-Json $JSON -ErrorAction Stop
    $validJson = $true

    }

    catch {

    $validJson = $false
    $_.Exception

    }

    if (!$validJson){

    Write-Host "Provided JSON isn't in valid JSON format" -f Red
    break

    }

}

####################################################

#region Authentication

write-host

# Checking if authToken exists before running authentication
if($global:authToken){

    # Setting DateTime to Universal time to work in all timezones
    $DateTime = (Get-Date).ToUniversalTime()

    # If the authToken exists checking when it expires
    $TokenExpires = ($authToken.ExpiresOn.datetime - $DateTime).Minutes

        if($TokenExpires -le 0){

        write-host "Authentication Token expired" $TokenExpires "minutes ago" -ForegroundColor Yellow
        write-host

            # Defining Azure AD tenant name, this is the name of your Azure Active Directory (do not use the verified domain name)

            if($tenant -eq $null -or $tenant -eq ""){

            $tenant = Read-Host -Prompt "Please specify your tenant name"
            Write-Host

            }

        $global:authToken = Get-AuthToken -TenantName $tenant

        }
}

# Authentication doesn't exist, calling Get-AuthToken function

else {

    if($tenant -eq $null -or $tenant -eq ""){

    # Defining Azure AD tenant name, this is the name of your Azure Active Directory (do not use the verified domain name)

    $tenant = Read-Host -Prompt "Please specify your tenant name"

    }

# Getting the authorization token
$global:authToken = Get-AuthToken -TenantName $tenant

}

#endregion

####################################################

$iOS = @"

{
    "@odata.type": "#microsoft.graph.iosGeneralDeviceConfiguration",
    "description": "iOS Device Restriction Policy",
    "displayName": "iOS Device Restriction Policy",
    "accountBlockModification": false,
    "activationLockAllowWhenSupervised": false,
    "airDropBlocked": false,
    "airDropForceUnmanagedDropTarget": false,
    "airPlayForcePairingPasswordForOutgoingRequests": false,
    "appleWatchBlockPairing": false,
    "appleWatchForceWristDetection": false,
    "appleNewsBlocked": false,
    "appsVisibilityList": [],
    "appsVisibilityListType": "none",
    "appStoreBlockAutomaticDownloads": false,
    "appStoreBlocked": false,
    "appStoreBlockInAppPurchases": false,
    "appStoreBlockUIAppInstallation": false,
    "appStoreRequirePassword": false,
    "bluetoothBlockModification": false,
    "cameraBlocked": false,
    "cellularBlockDataRoaming": false,
    "cellularBlockGlobalBackgroundFetchWhileRoaming": false,
    "cellularBlockPerAppDataModification": false,
    "cellularBlockVoiceRoaming": false,
    "certificatesBlockUntrustedTlsCertificates": false,
    "classroomAppBlockRemoteScreenObservation": false,
    "compliantAppsList": [],
    "compliantAppListType": "none",
    "configurationProfileBlockChanges": false,
    "definitionLookupBlocked": false,
    "deviceBlockEnableRestrictions": false,
    "deviceBlockEraseContentAndSettings": false,
    "deviceBlockNameModification": false,
    "diagnosticDataBlockSubmission": false,
    "diagnosticDataBlockSubmissionModification": false,
    "documentsBlockManagedDocumentsInUnmanagedApps": false,
    "documentsBlockUnmanagedDocumentsInManagedApps": false,
    "emailInDomainSuffixes": [],
    "enterpriseAppBlockTrust": false,
    "enterpriseAppBlockTrustModification": false,
    "faceTimeBlocked": false,
    "findMyFriendsBlocked": false,
    "gamingBlockGameCenterFriends": true,
    "gamingBlockMultiplayer": false,
    "gameCenterBlocked": false,
    "hostPairingBlocked": false,
    "iBooksStoreBlocked": false,
    "iBooksStoreBlockErotica": false,
    "iCloudBlockActivityContinuation": false,
    "iCloudBlockBackup": true,
    "iCloudBlockDocumentSync": true,
    "iCloudBlockManagedAppsSync": false,
    "iCloudBlockPhotoLibrary": false,
    "iCloudBlockPhotoStreamSync": true,
    "iCloudBlockSharedPhotoStream": false,
    "iCloudRequireEncryptedBackup": false,
    "iTunesBlockExplicitContent": false,
    "iTunesBlockMusicService": false,
    "iTunesBlockRadio": false,
    "keyboardBlockAutoCorrect": false,
    "keyboardBlockPredictive": false,
    "keyboardBlockShortcuts": false,
    "keyboardBlockSpellCheck": false,
    "kioskModeAllowAssistiveSpeak": false,
    "kioskModeAllowAssistiveTouchSettings": false,
    "kioskModeAllowAutoLock": false,
    "kioskModeAllowColorInversionSettings": false,
    "kioskModeAllowRingerSwitch": false,
    "kioskModeAllowScreenRotation": false,
    "kioskModeAllowSleepButton": false,
    "kioskModeAllowTouchscreen": false,
    "kioskModeAllowVoiceOverSettings": false,
    "kioskModeAllowVolumeButtons": false,
    "kioskModeAllowZoomSettings": false,
    "kioskModeAppStoreUrl": null,
    "kioskModeRequireAssistiveTouch": false,
    "kioskModeRequireColorInversion": false,
    "kioskModeRequireMonoAudio": false,
    "kioskModeRequireVoiceOver": false,
    "kioskModeRequireZoom": false,
    "kioskModeManagedAppId": null,
    "lockScreenBlockControlCenter": false,
    "lockScreenBlockNotificationView": false,
    "lockScreenBlockPassbook": false,
    "lockScreenBlockTodayView": false,
    "mediaContentRatingAustralia": null,
    "mediaContentRatingCanada": null,
    "mediaContentRatingFrance": null,
    "mediaContentRatingGermany": null,
    "mediaContentRatingIreland": null,
    "mediaContentRatingJapan": null,
    "mediaContentRatingNewZealand": null,
    "mediaContentRatingUnitedKingdom": null,
    "mediaContentRatingUnitedStates": null,
    "mediaContentRatingApps": "allAllowed",
    "messagesBlocked": false,
    "notificationsBlockSettingsModification": false,
    "passcodeBlockFingerprintUnlock": false,
    "passcodeBlockModification": false,
    "passcodeBlockSimple": true,
    "passcodeExpirationDays": null,
    "passcodeMinimumLength": 4,
    "passcodeMinutesOfInactivityBeforeLock": null,
    "passcodeMinutesOfInactivityBeforeScreenTimeout": null,
    "passcodeMinimumCharacterSetCount": null,
    "passcodePreviousPasscodeBlockCount": null,
    "passcodeSignInFailureCountBeforeWipe": null,
    "passcodeRequiredType": "deviceDefault",
    "passcodeRequired": true,
    "podcastsBlocked": false,
    "safariBlockAutofill": false,
    "safariBlockJavaScript": false,
    "safariBlockPopups": false,
    "safariBlocked": false,
    "safariCookieSettings": "browserDefault",
    "safariManagedDomains": [],
    "safariPasswordAutoFillDomains": [],
    "safariRequireFraudWarning": false,
    "screenCaptureBlocked": false,
    "siriBlocked": false,
    "siriBlockedWhenLocked": false,
    "siriBlockUserGeneratedContent": false,
    "siriRequireProfanityFilter": false,
    "spotlightBlockInternetResults": false,
    "voiceDialingBlocked": false,
    "wallpaperBlockModification": false
}

"@

####################################################

$Android = @"

{
    "@odata.type": "#microsoft.graph.androidGeneralDeviceConfiguration",
    "description": "Android Device Restriction Policy",
    "displayName": "Android Device Restriction Policy",
    "appsBlockClipboardSharing": false,
    "appsBlockCopyPaste": false,
    "appsBlockYouTube": false,
    "bluetoothBlocked": false,
    "cameraBlocked": false,
    "cellularBlockDataRoaming": true,
    "cellularBlockMessaging": false,
    "cellularBlockVoiceRoaming": false,
    "cellularBlockWiFiTethering": false,
    "compliantAppsList": [],
    "compliantAppListType": "none",
    "diagnosticDataBlockSubmission": false,
    "locationServicesBlocked": false,
    "googleAccountBlockAutoSync": false,
    "googlePlayStoreBlocked": false,
    "kioskModeBlockSleepButton": false,
    "kioskModeBlockVolumeButtons": false,
    "kioskModeManagedAppId": null,
    "nfcBlocked": false,
    "passwordBlockFingerprintUnlock": true,
    "passwordBlockTrustAgents": false,
    "passwordExpirationDays": null,
    "passwordMinimumLength": 4,
    "passwordMinutesOfInactivityBeforeScreenTimeout": null,
    "passwordPreviousPasswordBlockCount": null,
    "passwordSignInFailureCountBeforeFactoryReset": null,
    "passwordRequiredType": "deviceDefault",
    "passwordRequired": true,
    "powerOffBlocked": false,
    "factoryResetBlocked": false,
    "screenCaptureBlocked": false,
    "deviceSharingBlocked": false,
    "storageBlockGoogleBackup": true,
    "storageBlockRemovableStorage": false,
    "storageRequireDeviceEncryption": true,
    "storageRequireRemovableStorageEncryption": true,
    "voiceAssistantBlocked": false,
    "voiceDialingBlocked": false,
    "webBrowserAllowPopups": false,
    "webBrowserBlockAutofill": false,
    "webBrowserBlockJavaScript": false,
    "webBrowserBlocked": false,
    "webBrowserCookieSettings": "browserDefault",
    "wiFiBlocked": false
}

"@

####################################################

Add-DeviceConfigurationPolicy -Json $Android

Add-DeviceConfigurationPolicy -Json $iOS
