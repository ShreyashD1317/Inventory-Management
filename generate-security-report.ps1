# Generate SECURITY_FINDINGS.md
# This script creates a comprehensive security report

param(
    [string]$BuildNumber = $env:BUILD_NUMBER,
    [string]$AppName = $env:APP_NAME,
    [string]$JobName = $env:JOB_NAME,
    [string]$NPM_Total = $env:NPM_TOTAL_VULNS,
    [string]$NPM_Critical = $env:NPM_CRITICAL_VULNS,
    [string]$NPM_High = $env:NPM_HIGH_VULNS,
    [string]$Trivy_Total = $env:TRIVY_TOTAL_VULNS,
    [string]$Trivy_Critical = $env:TRIVY_CRITICAL_VULNS,
    [string]$Trivy_High = $env:TRIVY_HIGH_VULNS,
    [string]$DockerImage = $env:DOCKER_IMAGE
)

$report = @"
# Security Scan Results - Build #$BuildNumber

**Project:** $AppName
**Build Number:** $BuildNumber
**Scan Date:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
**Jenkins Job:** $JobName

---

## Executive Summary

This document contains the automated security scan results for build #$BuildNumber.
Two types of scans were performed:

1. **NPM Dependency Audit** - Scans Node.js packages for known vulnerabilities
2. **Docker Image Scan (Trivy)** - Scans container images for OS and library vulnerabilities

---

## 1. NPM Dependency Security Scan

### Summary

- **Status:** $NPM_Total vulnerabilities found
- **Critical:** $NPM_Critical
- **High:** $NPM_High

"@

if ($NPM_Total -eq "0") {
    $report += @"

### Result: ✅ PASS

**No vulnerabilities found in NPM dependencies!**

Your Node.js packages are secure and up-to-date.

"@
} else {
    $report += @"

### Result: ⚠️ REQUIRES ATTENTION

**Vulnerabilities detected in NPM dependencies.**

See detailed findings below.

"@
}

$report += @"

### Detailed Findings

``````txt
"@

if (Test-Path "npm-audit-summary.txt") {
    $report += Get-Content "npm-audit-summary.txt" -Raw
}

$report += @"
``````

"@

if ($NPM_Total -ne "0") {
    $report += @"

### Recommended Actions

1. Review the detailed findings above
2. Run ``npm audit fix`` to automatically fix compatible issues
3. Run ``npm audit fix --force`` for fixes requiring breaking changes
4. Manually update packages that cannot be automatically fixed
5. Re-run security scan to verify fixes

"@
}

$report += @"

---

## 2. Docker Image Security Scan (Trivy)

### Summary

- **Status:** $Trivy_Total vulnerabilities found
- **Critical:** $Trivy_Critical
- **High:** $Trivy_High
- **Image:** $DockerImage

"@

if ($Trivy_Total -eq "0") {
    $report += @"

### Result: ✅ PASS

**No vulnerabilities found in Docker image!**

"@
} elseif ($Trivy_Total -eq "N/A") {
    $report += @"

### Result: ⚠️ SCAN NOT PERFORMED

Docker was not available during the build.

"@
} else {
    $report += @"

### Result: ⚠️ REQUIRES ATTENTION

**Vulnerabilities detected in Docker base image.**

These are typically in the base Alpine/Ubuntu image, not your application code.

"@
}

if (Test-Path "trivy-summary.txt") {
    $report += @"

### Detailed Findings

``````txt
"@
    $report += Get-Content "trivy-summary.txt" -Raw
    $report += @"
``````

"@
}

if ($Trivy_Total -ne "0" -and $Trivy_Total -ne "N/A") {
    $report += @"

### Recommended Actions

**Option 1: Update Base Image (Recommended)**

Update your Dockerfile:

``````dockerfile
# Update from
FROM node:18-alpine

# To latest
FROM node:18-alpine3.20
``````

**Option 2: Update Packages in Dockerfile**

``````dockerfile
FROM node:18-alpine
RUN apk update && apk upgrade --no-cache
``````

**Option 3: Accept Risk (If Low Impact)**

If vulnerabilities are MEDIUM/LOW and don't affect your application:

- Document the decision to accept the risk
- Explain why (e.g., container runs as non-root, affected packages not used)
- Set a review date to re-evaluate

"@
}

$report += @"

---

## Severity Levels Explained

- **CRITICAL** (9.0-10.0): Immediate action required - actively exploitable vulnerabilities
- **HIGH** (7.0-8.9): Should be fixed soon - significant security risk
- **MEDIUM** (4.0-6.9): Should be reviewed - potential security concerns
- **LOW** (0.1-3.9): Minor issues - fix when convenient
- **INFO** (0.0): Informational only - no immediate action needed

---

## Overall Recommendation

"@

if ($NPM_Total -eq "0" -and $Trivy_Total -eq "0") {
    $report += "✅ **ALL CLEAR** - No security vulnerabilities found. Your application is secure!`n"
} else {
    $criticalOrHigh = ($NPM_Critical -ne "0") -or ($NPM_High -ne "0") -or 
                     (($Trivy_Critical -ne "0" -and $Trivy_Critical -ne "N/A")) -or 
                     (($Trivy_High -ne "0" -and $Trivy_High -ne "N/A"))
    
    if ($criticalOrHigh) {
        $report += @"
⚠️ **ACTION REQUIRED** - Critical or High severity vulnerabilities found.

Please address these vulnerabilities before deploying to production.
"@
    } else {
        $report += @"
ℹ️ **REVIEW RECOMMENDED** - Medium or Low severity vulnerabilities found.

Review and address when convenient. Not critical for production deployment.
"@
    }
}

$report += @"

---

## Additional Resources

- [NPM Audit Documentation](https://docs.npmjs.com/cli/v8/commands/npm-audit)
- [Trivy Documentation](https://aquasecurity.github.io/trivy/)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Node.js Security Best Practices](https://github.com/goldbergyoni/nodebestpractices#6-security-best-practices)

---

*Report generated automatically by Jenkins Pipeline*
*Build URL: $env:BUILD_URL*
"@

# Write to file
$report | Out-File -FilePath "SECURITY_FINDINGS.md" -Encoding UTF8

Write-Host "✅ SECURITY_FINDINGS.md generated successfully"