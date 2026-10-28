#!/usr/bin/env python3
"""obfuscate_ps.py - strip comments/help and rename internal functions to defeat
content signatures (Trellix on landing, AMSI at runtime). Entry-point names in
KEEP are left stable so callers keep working. Pure text transform, no semantics
change beyond identifier renaming."""
import re, random, string, sys, pathlib

KEEP = {
    # PowerUp: only the one entry we call
    "Invoke-AllChecks",
    # PowerView public surface (interactive API, call by name)
    "Get-Domain", "Get-DomainController", "Get-DomainTrust", "Get-DomainUser",
    "Get-DomainComputer", "Get-DomainGroup", "Get-DomainGroupMember",
    "Get-DomainObjectAcl", "Get-DomainObject", "Get-DomainGPO",
    "Get-DomainOU", "Get-DomainSPNTicket", "Get-DomainPolicyData",
    "Find-DomainUserLocation", "Find-DomainProcess", "Find-LocalAdminAccess",
    "Get-NetLocalGroup", "Get-NetLocalUser", "Get-IPAddress",
    "Convert-LDAPProperty", "Convert-ADName", "Set-DomainObject",
    "Add-DomainObjectAcl", "Get-DomainDFSShare", "Get-DomainFileServer",
    # SessionGopher
    "Invoke-SessionGopher",
    # JAWS / PrivescCheck run on dot-source or one entry
    "Invoke-PrivescCheck", "Invoke-JAWS",
}


def rand_name():
    return "fn_" + "".join(random.choices(string.ascii_lowercase, k=10))


def strip_comments(src: str) -> str:
    # block comments <# ... #> (keep none of the help text - it carries signatures)
    src = re.sub(r"<#.*?#>", "", src, flags=re.S)
    # line comments: careful not to touch `#` inside strings; good enough for these tools
    out_lines = []
    for ln in src.splitlines():
        # skip pure comment lines
        if ln.lstrip().startswith("#"):
            continue
        # trailing comments after code (naive but works: ` # ` or `\t#`)
        ln = re.sub(r"(\s)#.*$", r"\1", ln)
        out_lines.append(ln)
    return "\n".join(out_lines)


def obfuscate(src: str):
    src = strip_comments(src)
    # collect function names
    names = re.findall(r"(?im)^\s*function\s+([A-Za-z][\w-]*)", src)
    mapping = {}
    used = set()
    for n in names:
        if n in KEEP or n.lower() in {k.lower() for k in KEEP}:
            continue
        new = rand_name()
        while new in used:
            new = rand_name()
        used.add(new)
        mapping[n] = new
    # rename: longest-first so prefixes don't collide
    for old in sorted(mapping, key=len, reverse=True):
        src = re.sub(r"\b" + re.escape(old) + r"\b", mapping[old], src)
    # collapse blank runs
    src = re.sub(r"\n{3,}", "\n\n", src)
    return src, mapping


def main():
    root = pathlib.Path(__file__).resolve().parent.parent
    src_dir = root / "tools"
    dst_dir = root / "tools-obf"
    dst_dir.mkdir(exist_ok=True)
    files = ["PowerUp.ps1", "PowerView.ps1", "jaws-enum.ps1",
             "SessionGopher.ps1", "PrivescCheck.ps1"]
    random.seed(20261028)  # reproducible build
    for f in files:
        p = src_dir / f
        if not p.exists():
            print(f"[!] missing {f}")
            continue
        out, mapping = obfuscate(p.read_text(encoding="utf-8", errors="replace"))
        (dst_dir / f).write_text(out, encoding="utf-8")
        n_fn = len(re.findall(r"(?im)^\s*function\s+", out))
        print(f"[+] {f}: {p.stat().st_size} -> {len(out)} bytes, {n_fn} fns left, {len(mapping)} renamed")


if __name__ == "__main__":
    main()
