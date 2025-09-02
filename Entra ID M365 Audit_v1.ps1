#Entra + M365 PowerShell Script v1.0
#Clement Maillioux 

#README : Si le script propose d'installer des modules PowerShell Microsoft Graph, il faudra penser à lancer le script de nettoyage pour les effacer!

$banniere = (
"'##::::'##::'#######:::'#######::'########:::::::::::::::'########:'##::: ##:'########:'########:::::'###:::::::'####:'########::::::::'###::::'##::::'##:'########::'####:'########:`r`n" +
" ###::'###:'##.... ##:'##.... ##: ##.....:::::::'##:::::: ##.....:: ###:: ##:... ##..:: ##.... ##:::'## ##::::::. ##:: ##.... ##::::::'## ##::: ##:::: ##: ##.... ##:. ##::... ##..::`r`n" +
" ####'####:..::::: ##: ##::::..:: ##:::::::::::: ##:::::: ##::::::: ####: ##:::: ##:::: ##:::: ##::'##:. ##:::::: ##:: ##:::: ##:::::'##:. ##:: ##:::: ##: ##:::: ##:: ##::::: ##::::`r`n" +
" ## ### ##::'#######:: ########:: #######:::::'######:::: ######::: ## ## ##:::: ##:::: ########::'##:::. ##::::: ##:: ##:::: ##::::'##:::. ##: ##:::: ##: ##:::: ##:: ##::::: ##::::`r`n" +
" ##. #: ##::...... ##: ##.... ##:...... ##::::.. ##.::::: ##...:::: ##. ####:::: ##:::: ##.. ##::: #########::::: ##:: ##:::: ##:::: #########: ##:::: ##: ##:::: ##:: ##::::: ##::::`r`n" +
" ##:.:: ##:'##:::: ##: ##:::: ##:'##::: ##:::::: ##:::::: ##::::::: ##:. ###:::: ##:::: ##::. ##:: ##.... ##::::: ##:: ##:::: ##:::: ##.... ##: ##:::: ##: ##:::: ##:: ##::::: ##::::`r`n" +
" ##:::: ##:. #######::. #######::. ######:::::::..::::::: ########: ##::. ##:::: ##:::: ##:::. ##: ##:::: ##::::'####: ########::::: ##:::: ##:. #######:: ########::'####:::: ##::::`r`n" +
"..:::::..:::.......::::.......::::......:::::::::::::::::........::..::::..:::::..:::::..:::::..::..:::::..:::::....::........::::::..:::::..:::.......:::........:::....:::::..:::::`r`n" +
"v 1.0")

$TypicalAuthId = ("Password : 28c10230-6103-485e-b985-444c60001490`r`n" +
"Email : 3ddfcfc8-9383-446f-83cc-3ab9be4be18f`r`n" +
"Phone (alternate, office or mobile) : b6332ec1-7057-4abe-9331-3d72feddfe41, e37fc753-ff3b-4958-9484-eaa9425c82bc, 3179e48a-750b-4051-897c-87b9720928f7'r"
)

#Ouverture du programme
Write-Host $banniere
Out-File -FilePath ".\resultat_audit_entra-M365.txt" -InputObject $banniere -Append -Encoding utf8 

# Définition de la fonction d'affichage -----------
Function Afficher_couleurs {
    param($mon_texte,
        $mon_type,
        $ecrire_fichier)
    if ($ecrire_fichier -eq "oui") {
        if ($mon_type -eq "info") {
            $data = "[*] " + $mon_texte
            Out-File -FilePath ".\resultat_audit_entra-M365.txt" -InputObject $data -Append -Encoding utf8
        } elseif ($mon_type -eq "probleme") {
            $data = "[!] " + $mon_texte
            Out-File -FilePath ".\resultat_audit_entra-M365.txt" -InputObject $data -Append -Encoding utf8
        } elseif ($mon_type -eq "good") {
            $data = "[+] " + $mon_texte
            Out-File -FilePath ".\resultat_audit_entra-M365.txt" -InputObject $data -Append -Encoding utf8
        } else {
            $data = "[-] " + $mon_texte
            Out-File -FilePath ".\resultat_audit_entra-M365.txt" -InputObject $data -Append -Encoding utf8
        }
    }
    if ($mon_type -eq "info") {
        Write-host "[*] "$mon_texte -ForegroundColor DarkYellow 
    } elseif ($mon_type -eq "probleme") {
        Write-host "[!] "$mon_texte -ForegroundColor Red
    } elseif ($mon_type -eq "good") {
        Write-host "[+] "$mon_texte -ForegroundColor Green
    } else {
        Write-host "[-] "$mon_texte
    }
    $data = ""
}

$DateActuelle = Get-Date
Afficher_couleurs -mon_type "info" -mon_texte $dateActuelle -ecrire_fichier "oui"

# Vérification des pré-requis ------
Afficher_couleurs -mon_type "info" -mon_texte "Verification de la présence du module Microsoft Graph" -ecrire_fichier "non"
$Modules = Get-Module Microsoft.Graph* -ListAvailable

if ($Modules.Count -eq 0) {
    Afficher_couleurs -mon_type "probleme" -mon_texte "Absence du module Microsoft Graph !" -ecrire_fichier "non"
    $InstallKPMG = Read-host "[?] Le module Microsoft Graph est nécessaire. Voulez-vous l'installer? (o/n)"
    if ($InstallKPMG -eq "o") {
        Afficher_couleurs -mon_type "good" -mon_texte "C'est une longue operation, soyez patient!" -ecrire_fichier "non"
        Install-module Microsoft.graph
    }
} else {
    Afficher_couleurs -mon_type "good" -mon_texte "Le module Microsoft Graph semble installé." -ecrire_fichier "non"
}


$TenantIDRep = Read-host "[?] Veuillez indiquer l'ID du Tenant à Auditer"
# Connexion et établissement des permissions ------
Afficher_couleurs -mon_type "info" -mon_texte "Connexion au Tenant" -ecrire_fichier "oui"
Connect-MgGraph -TenantId $TenantIDRep -Scopes "OrgSettings-Forms.Read.All, OrgSettings-AppsAndServices.Read.All, Domain.Read.All, RoleManagement.Read.All, AuditLog.Read.All, UserAuthenticationMethod.Read.All, Directory.Read.All, Policy.Read.All, User.Read.All, Group.Read.all, AccessReview.Read.All" -NoWelcome

Get-MgContext
Out-File -FilePath ".\resultat_audit_entra-M365.txt" -InputObject (Get-MgContext) -Append -Encoding utf8


# --- Audit Entra ID -----

Afficher_couleurs -mon_type info -mon_texte "5.1.2.3 (L1) Ensure 'Restrict non-admin users from creating tenants' is set to 'Yes'" -ecrire_fichier "oui"
$reponse = (Get-MgPolicyAuthorizationPolicy).DefaultUserRolePermissions | Select-Object AllowedToCreateTenants
Write-Host $reponse
Out-File -FilePath ".\resultat_audit_entra-M365.txt" -InputObject $reponse -Append -Encoding utf8
$reponse = ""

Afficher_couleurs -mon_type info -mon_texte "5.1.3.1 (L1) Ensure a dynamic group for guest users is created" -ecrire_fichier "oui"
$groups = Get-MgGroup | Where-Object { $_.GroupTypes -contains "DynamicMembership" }
$reponse = ($groups | ft DisplayName,GroupTypes,MembershipRule)
Write-Host $reponse
Out-File -FilePath ".\resultat_audit_entra-M365.txt" -InputObject $reponse -Append -Encoding utf8
$reponse = ""

Afficher_couleurs -mon_type info -mon_texte "5.1.5.2 (L1) Ensure the admin consent workflow is enabled" -ecrire_fichier "oui"
$reponse = Get-MgPolicyAdminConsentRequestPolicy | fl IsEnabled,NotifyReviewers,RemindersEnabled
Write-Host $reponse
Out-File -FilePath ".\resultat_audit_entra-M365.txt" -InputObject $reponse -Append -Encoding utf8
$reponse = ""

Afficher_couleurs -mon_type info -mon_texte "5.1.6.2 (L1) Ensure that guest user access is restricted" -ecrire_fichier "oui"
$reponse = Get-MgPolicyAuthorizationPolicy | fl GuestUserRoleId
Write-Host $reponse
Out-File -FilePath ".\resultat_audit_entra-M365.txt" -InputObject $reponse -Append -Encoding utf8
$reponse = ""

Afficher_couleurs -mon_type info -mon_texte "5.2.3.2 (L1) Ensure custom banned passwords lists are used" -ecrire_fichier "oui"
$reponse = (Get-MgGroupSetting | Where-Object TemplateId -eq '5cf42378-d67d-4f36-ba46-e8b86229381d' | Select-Object -ExpandProperty Values)
Out-File -FilePath ".\resultat_audit_entra-M365.txt" -InputObject $reponse -Append -Encoding utf8
Write-Host $reponse
$reponse = (Get-MgGroupSetting)
Out-File -FilePath ".\resultat_audit_entra-M365.txt" -InputObject $reponse -Append -Encoding utf8
Write-Host $reponse
$reponse = ""

Afficher_couleurs -mon_type info -mon_texte "5.2.3.4 (L1) Ensure all member users are 'MFA capable'" -ecrire_fichier "oui"
$reponse = Get-MgReportAuthenticationMethodUserRegistrationDetail -Filter "IsMfaCapable eq false and UserType eq 'Member'" | ft UserPrincipalName,IsMfaCapable,IsAdmin
Write-Host $reponse
Out-File -FilePath ".\resultat_audit_entra-M365.txt" -InputObject $reponse -Append -Encoding utf8
$reponse = ""

Afficher_couleurs -mon_type info -mon_texte "5.2.3.5 (L1) Ensure weak authentication methods are disabled" -ecrire_fichier "oui"
$reponse = (Get-MgPolicyAuthenticationMethodPolicy).AuthenticationMethodConfigurations
Write-Host $reponse
Out-File -FilePath ".\resultat_audit_entra-M365.txt" -InputObject $reponse -Append -Encoding utf8
$reponse = ""

Afficher_couleurs -mon_type info -mon_texte "5.3.2 (L1) Ensure 'Access reviews' for Guest Users are configured" -ecrire_fichier "oui"
$Uri = 'https://graph.microsoft.com/v1.0/identityGovernance/accessReviews/definitions' 
$AccessReviews = Invoke-MgGraphRequest -Uri $Uri -Method Get | Select-Object -ExpandProperty Value 
$AccessReviewReport = [System.Collections.Generic.List[Object]]::new() 
$GuestReviews = $AccessReviews | Where-Object { $_.scope.query -match "userType eq 'Guest'" -or $_.scope.principalscopes.query -match "userType eq 'Guest'" } 
foreach ($review in $GuestReviews) { 
	$value = $review.settings 
	$obj = [PSCustomObject]@{ 
		Name = $review.DisplayName 
		Status = $review.Status 
		mailNotificationsEnabled = $value.mailNotificationsEnabled 
		Reminders = $value.reminderNotificationsEnabled 
		justificationRequiredOnApproval = $value.justificationRequiredOnApproval 
		Frequency = $value.recurrence.pattern.type 
		autoApplyDecisionsEnabled = $value.autoApplyDecisionsEnabled 
		defaultDecision = $value.defaultDecision 
	}
	$AccessReviewReport.Add($obj) 
}
Write-Host $AccessReviewReport
Out-File -FilePath ".\resultat_audit_entra-M365.txt" -InputObject $reponse -Append -Encoding utf8
$reponse = ""


Afficher_couleurs -mon_type info -mon_texte "Vérifier la mise en place de la 2FA" -ecrire_fichier "oui"
Import-Module Microsoft.Graph.Identity.Signins
$UserList = Get-MgUser | Select-Object Id, UserPrincipalName
foreach ($userID in $UserList) {
    $reponse = (Get-MgUserAuthenticationMethod -UserId $userID.UserPrincipalName)
    write-host $reponse
    Out-File -FilePath ".\resultat_audit_entra-M365.txt" -InputObject $userID.UserPrincipalName -Append -Encoding utf8
    Out-File -FilePath ".\resultat_audit_entra-M365.txt" -InputObject $reponse -Append -Encoding utf8
}
Out-File -FilePath ".\resultat_audit_entra-M365.txt" -InputObject $TypicalAuthId -Append -Encoding utf8
$reponse = ""

Afficher_couleurs -mon_type info -mon_texte "Deconnexion de Microsoft Graph" -ecrire_fichier "oui"


# --- End of audit Entra ID ---

# --- Audit M365 -----

Afficher_couleurs -mon_type info -mon_texte "1.1.1 (L1) Ensure Administrative accounts are cloud-only" -ecrire_fichier "oui"
$DirectoryRoles = Get-MgDirectoryRole 
# Get privileged role IDs 
$PrivilegedRoles = $DirectoryRoles | Where-Object { 
	$_.DisplayName -like "*Administrator*" -or $_.DisplayName -eq "Global Reader"
} 
# Get the members of these various roles 
$RoleMembers = $PrivilegedRoles | ForEach-Object { Get-MgDirectoryRoleMember -DirectoryRoleId $_.Id } | Select-Object Id -Unique 
# Retrieve details about the members in these roles 
$PrivilegedUsers = $RoleMembers | ForEach-Object { Get-MgUser -UserId $_.Id -Property UserPrincipalName, DisplayName, Id, OnPremisesSyncEnabled } 
$reponse = ($PrivilegedUsers | Where-Object { $_.OnPremisesSyncEnabled -eq $true } | ft DisplayName,UserPrincipalName,OnPremisesSyncEnabled)
Write-Host $reponse
Out-File -FilePath ".\resultat_audit_m365.txt" -InputObject $reponse -Append -Encoding utf8
$reponse = ""


Afficher_couleurs -mon_type info -mon_texte "1.1.3 (L1) Ensure that between two and four global admins are designated" -ecrire_fichier "oui"
# Determine Id of GA role using the immutable RoleTemplateId value. 
$GlobalAdminRole = Get-MgDirectoryRole -Filter "RoleTemplateId eq '62e90394-69f5-4237-9190-012177145e10'" 

$RoleMembers = Get-MgDirectoryRoleMember -DirectoryRoleId $GlobalAdminRole.Id

$GlobalAdmins = [System.Collections.Generic.List[Object]]::new() 
foreach ($object in $RoleMembers) { 
	$Type = $object.AdditionalProperties.'@odata.type' 
	# Check for and process role assigned groups
	if ($Type -eq '#microsoft.graph.group') {
		$GroupId = $object.Id 
		$GroupMembers = (Get-MgGroupMember -GroupId $GroupId).AdditionalProperties 

		foreach ($member in $GroupMembers) { 
			if ($member.'@odata.type' -eq '#microsoft.graph.user') {
				$GlobalAdmins.Add([PSCustomObject][Ordered]@{ 
					DisplayName = $member.displayName 
					UserPrincipalName = $member.userPrincipalName
				})
			} 
		} 
	} elseif ($Type -eq '#microsoft.graph.user') { 
		$DisplayName = $object.AdditionalProperties.displayName
		$UPN = $object.AdditionalProperties.userPrincipalName
		$GlobalAdmins.Add([PSCustomObject][Ordered]@{ 
			DisplayName = $DisplayName 
			UserPrincipalName = $UPN 
		}) 
	} 
} 
$GlobalAdmins = $GlobalAdmins | select DisplayName,UserPrincipalName -Unique 
$reponse = $GlobalAdmins
Write-Host $reponse
Out-File -FilePath ".\resultat_audit_m365.txt" -InputObject $reponse -Append -Encoding utf8
$reponse = "*** There are " + $GlobalAdmins.Count + " Global Administrators in the organization.`r`n"
Write-Host $reponse
Out-File -FilePath ".\resultat_audit_m365.txt" -InputObject $reponse -Append -Encoding utf8
$reponse = ""

Afficher_couleurs -mon_type info -mon_texte "1.1.4 (L1) Ensure administrative accounts use licenses with a reduced application footprint" -ecrire_fichier "oui"
$DirectoryRoles = Get-MgDirectoryRole

# Get privileged role IDs 
$PrivilegedRoles = $DirectoryRoles | Where-Object {
	$_.DisplayName -like "*Administrator*" -or $_.DisplayName -eq "Global Reader"
}

# Get the members of these various roles 
$RoleMembers = $PrivilegedRoles | ForEach-Object {
	Get-MgDirectoryRoleMember -DirectoryRoleId $_.Id 
} | Select-Object Id -Unique

# Retrieve details about the members in these roles 
$PrivilegedUsers = $RoleMembers | ForEach-Object { 
	Get-MgUser -UserId $_.Id -Property UserPrincipalName, DisplayName, Id
}

$Report = [System.Collections.Generic.List[Object]]::new()

foreach ($Admin in $PrivilegedUsers) {
	$License = $null
	$License = (Get-MgUserLicenseDetail -UserId $Admin.id).SkuPartNumber -join ", " 
	$Object = [pscustomobject][ordered]@{ 
		DisplayName = $Admin.DisplayName 
		UserPrincipalName = $Admin.UserPrincipalName 
		License = $License 
	} 
	$Report.Add($Object) 
}

$Report
$reponse = $Report
Write-Host $reponse
Out-File -FilePath ".\resultat_audit_m365.txt" -InputObject $reponse -Append -Encoding utf8
$reponse = ""


Afficher_couleurs -mon_type info -mon_texte "1.2.1 (L2) Ensure that only organizationally managed/approved public groups exist" -ecrire_fichier "oui"
$reponse = (Get-MgGroup -All | where {$_.Visibility -eq "Public"} | select DisplayName,Visibility)
Write-Host $reponse
Out-File -FilePath ".\resultat_audit_m365.txt" -InputObject $reponse -Append -Encoding utf8
$reponse = ""


Afficher_couleurs -mon_type info -mon_texte "1.3.1 (L1) Ensure the 'Password expiration policy' is set to 'Set passwords to never expire (recommended)" -ecrire_fichier "oui"
$reponse = (Get-MgDomain | ft id,PasswordValidityPeriodInDays)
Write-Host $reponse
Out-File -FilePath ".\resultat_audit_m365.txt" -InputObject $reponse -Append -Encoding utf8
$reponse = ""

Afficher_couleurs -mon_type info -mon_texte "1.3.4 (L1) Ensure 'User owned apps and services' is restricted" -ecrire_fichier "oui"
$Uri = "https://graph.microsoft.com/beta/admin/appsAndServices/settings" 
$reponse = (Invoke-MgGraphRequest -Uri $Uri)
Write-Host $reponse
Out-File -FilePath ".\resultat_audit_m365.txt" -InputObject $reponse -Append -Encoding utf8
$reponse = ""

Afficher_couleurs -mon_type info -mon_texte "1.3.5 (L1) Ensure internal phishing protection for Forms is enabled" -ecrire_fichier "oui"
$uri = 'https://graph.microsoft.com/beta/admin/forms/settings' 
$reponse = (Invoke-MgGraphRequest -Uri $uri | select isInOrgFormsPhishingScanEnabled)
Write-Host $reponse
Out-File -FilePath ".\resultat_audit_m365.txt" -InputObject $reponse -Append -Encoding utf8
$reponse = ""


# End of audit M365 ---

Disconnect-MgGraph
<#
Afficher_couleurs -mon_type info -mon_texte "" -ecrire_fichier "oui"
$reponse = 
Write-Host $reponse
Out-File -FilePath ".\resultat_audit_entra-M365.txt" -InputObject $reponse -Append -Encoding utf8
$reponse = ""
#>
