# Get-DomainInfo.ps1 - quiet domain recon via plain LDAP/ADSI (custom code, no known-tool strings)
# Covers what Day2 needs from PowerView: trusts, privileged users, delegation, GPOs, DCs.
# Run: powershell -ep bypass -file Get-DomainInfo.ps1
$ErrorActionPreference = 'Continue'
$outDir = Join-Path (Split-Path $PSScriptRoot -Parent) 'out'
if (!(Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }
$out = Join-Path $outDir 'directory-summary.txt'
"[*] Get-DomainInfo $(Get-Date)" | Set-Content $out
function W($t, $b) { "" | Add-Content $out; "=== $t ===" | Add-Content $out; $b | Out-String | Add-Content $out }

$root = [ADSI]"LDAP://RootDSE"
$dse = $root.distinguishedName
$dom = [ADSI]"LDAP://$dse"

function Q($filter, $props) {
    $ds = New-Object DirectoryServices.DirectorySearcher([ADSI]"LDAP://$dse")
    $ds.Filter = $filter
    $ds.PageSize = 200
    foreach ($p in $props) { [void]$ds.PropertiesToLoad.Add($p) }
    $ds.FindAll() | ForEach-Object {
        $o = [ordered]@{}
        foreach ($p in $props) {
            $v = $_.Properties[$p]
            $o[$p] = if ($v.Count -eq 1) { $v[0] } elseif ($v.Count -gt 1) { ($v | ForEach-Object { "$_" }) -join '; ' } else { $null }
        }
        [pscustomobject]$o
    }
}

W 'distinguishedName' $dse
W 'domain controllers' (Q '(&(objectCategory=computer)(userAccountControl:1.2.840.113556.1.4.803:=8192))' @('dnshostname','operatingsystem','lastlogon'))
W 'trusts' (Q '(objectClass=trustedDomain)' @('name','trustdirection','trusttype','trustattributes'))
W 'adminCount=1 (privileged users)' (Q '(&(objectCategory=person)(objectClass=user)(adminCount=1))' @('samaccountname','memberof','useraccountcontrol'))
W 'unconstrained delegation computers' (Q '(&(objectCategory=computer)(userAccountControl:1.2.840.113556.1.4.803:=524288))' @('dnshostname','operatingsystem'))
W 'unconstrained delegation users' (Q '(&(objectCategory=person)(objectClass=user)(userAccountControl:1.2.840.113556.1.4.803:=524288))' @('samaccountname'))
W 'kerberoastable (spn users)' (Q '(&(objectCategory=person)(objectClass=user)(serviceprincipalname=*))' @('samaccountname','serviceprincipalname'))
W 'GPOs' (Q '(objectClass=groupPolicyContainer)' @('displayname','gpcfilesyspath'))
W 'OUs' (Q '(objectCategory=organizationalUnit)' @('ou','distinguishedname'))
W 'domain policy (pwd)' (Q '(objectClass=domainDNS)' @('maxpwdage','minpwdlength','pwdhistorylength','lockoutthreshold'))

# weak ACL spots on domain root / OUs (GenericAll|WriteDacl|WriteOwner|ExtendedRight)
W 'interesting ACLs (slow, best-effort)' {
    try {
        $acl = $dom.psbase.ObjectSecurity.GetAccessRules($true, $true, [Security.Principal.SecurityIdentifier])
        $rights = 'GenericAll|WriteDacl|WriteOwner|ExtendedRight|GenericWrite|WriteProperty'
        $acl | Where-Object {
            $_.AccessControlType -eq 'Allow' -and $_.ActiveDirectoryRights.ToString() -match $rights -and
            $_.IdentityReference.Value -notmatch '^(S-1-5-.*|.*Domain Admins.*|.*Enterprise Admins.*|.*Administrators.*)$'
        } | Select-Object IdentityReference, ActiveDirectoryRights, AccessControlType
    } catch { "acl read failed: $($_.Exception.Message)" }
}

"[+] done $(Get-Date)" | Add-Content $out
Write-Host "[+] saved $out"
