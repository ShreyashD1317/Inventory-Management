# ═══════════════════════════════════════════════════════════════════
# Security Findings Report Generator
# Parses NPM audit and Trivy scan results into comprehensive markdown
# ═══════════════════════════════════════════════════════════════════

Write-Host "============================================"
Write-Host "GENERATING COMPREHENSIVE SECURITY REPORT"
Write-Host "============================================"

# Initialize report
$report = @"
# 🔒 Security Scan Results - Build #$env:BUILD_NUMBER

**Date:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  
**Project:** $env:JOB_NAME  
**Build:** #$env:BUILD_NUMBER  

---

"@

# ═══════════════════════════════════════════════════════════════════
# SECTION 1: NPM AUDIT RESULTS
# ═══════════════════════════════════════════════════════════════════

$report += @"
## 📦 1. NPM Dependency Security Audit

"@

try {
    if (Test-Path "npm-audit-full.json") {
        Write-Host "✓ Processing NPM audit results..."
        
        $npmAudit = Get-Content "npm-audit-full.json" -Raw | ConvertFrom-Json
        
        $npmTotal = if ($npmAudit.metadata.vulnerabilities.total) { $npmAudit.metadata.vulnerabilities.total } else { 0 }
        $npmInfo = if ($npmAudit.metadata.vulnerabilities.info) { $npmAudit.metadata.vulnerabilities.info } else { 0 }
        $npmLow = if ($npmAudit.metadata.vulnerabilities.low) { $npmAudit.metadata.vulnerabilities.low } else { 0 }
        $npmModerate = if ($npmAudit.metadata.vulnerabilities.moderate) { $npmAudit.metadata.vulnerabilities.moderate } else { 0 }
        $npmHigh = if ($npmAudit.metadata.vulnerabilities.high) { $npmAudit.metadata.vulnerabilities.high } else { 0 }
        $npmCritical = if ($npmAudit.metadata.vulnerabilities.critical) { $npmAudit.metadata.vulnerabilities.critical } else { 0 }
        
        $report += @"
### Summary
- **Total Vulnerabilities:** $npmTotal
- **Critical:** $npmCritical 🔴
- **High:** $npmHigh 🟠
- **Moderate:** $npmModerate 🟡
- **Low:** $npmLow 🔵
- **Info:** $npmInfo ℹ️

"@

        if ($npmTotal -eq 0) {
            $report += "**Status:** ✅ **CLEAN** - No vulnerabilities found in NPM dependencies!`n`n"
        } else {
            $report += "**Status:** ⚠️ **VULNERABILITIES FOUND** - Review required`n`n"
            
            # Add detailed vulnerability information if available
            if ($npmAudit.vulnerabilities) {
                $report += "### Detailed Findings`n`n"
                
                $vulnCount = 0
                foreach ($vuln in $npmAudit.vulnerabilities.PSObject.Properties) {
                    $vulnCount++
                    if ($vulnCount -le 10) {  # Limit to first 10 for readability
                        $v = $vuln.Value
                        $severity = if ($v.severity) { $v.severity.ToUpper() } else { "UNKNOWN" }
                        $name = if ($v.name) { $v.name } else { $vuln.Name }
                        $via = if ($v.via -and $v.via.Count -gt 0) { 
                            if ($v.via[0] -is [string]) { $v.via[0] } 
                            elseif ($v.via[0].title) { $v.via[0].title }
                            else { "See npm-audit-full.json for details" }
                        } else { "Direct vulnerability" }
                        
                        $report += "#### $vulnCount. $name`n"
                        $report += "- **Severity:** $severity`n"
                        $report += "- **Issue:** $via`n"
                        if ($v.range) { $report += "- **Affected Versions:** $($v.range)`n" }
                        if ($v.fixAvailable) { 
                            $report += "- **Fix Available:** Yes`n" 
                        } else {
                            $report += "- **Fix Available:** No (manual intervention required)`n"
                        }
                        $report += "`n"
                    }
                }
                
                if ($vulnCount -gt 10) {
                    $report += "_... and $($vulnCount - 10) more. See npm-audit-full.json for complete details._`n`n"
                }
            }
        }
        
        $report += @"
### Recommended Actions
"@
        if ($npmCritical -gt 0) {
            $report += @"

🔴 **CRITICAL PRIORITY:**
- Immediately review and fix $npmCritical critical vulnerabilities
- Run ``npm audit fix --force`` (test thoroughly after)
- Consider updating affected packages manually if auto-fix breaks functionality

"@
        }
        
        if ($npmHigh -gt 0) {
            $report += @"
🟠 **HIGH PRIORITY:**
- Review $npmHigh high-severity vulnerabilities
- Run ``npm audit fix`` to auto-fix compatible issues
- Plan manual updates for packages without auto-fix

"@
        }
        
        if ($npmModerate -gt 0 -or $npmLow -gt 0) {
            $report += @"
🟡 **MEDIUM PRIORITY:**
- Schedule updates for moderate/low severity issues
- Test in development environment before production deployment

"@
        }
        
        if ($npmTotal -eq 0) {
            $report += @"
✅ **No action required** - All dependencies are secure!

"@
        }
        
    } else {
        $report += "⚠️ **NPM audit file not found** - Scan may not have run successfully.`n`n"
    }
} catch {
    $report += "⚠️ **Error parsing NPM audit results:** $($_.Exception.Message)`n`n"
}

# ═══════════════════════════════════════════════════════════════════
# SECTION 2: DOCKER IMAGE SECURITY SCAN (TRIVY)
# ═══════════════════════════════════════════════════════════════════

$report += @"
---

## 🐳 2. Docker Image Security Scan (Trivy)

"@

try {
    if (Test-Path "trivy-report.json") {
        Write-Host "✓ Processing Trivy scan results..."
        
        $trivyReport = Get-Content "trivy-report.json" -Raw | ConvertFrom-Json
        
        # Count vulnerabilities
        $trivyTotal = 0
        $trivyCritical = 0
        $trivyHigh = 0
        $trivyMedium = 0
        $trivyLow = 0
        
        $allVulns = @()
        
        if ($trivyReport.Results) {
            foreach ($result in $trivyReport.Results) {
                if ($result.Vulnerabilities) {
                    foreach ($vuln in $result.Vulnerabilities) {
                        $trivyTotal++
                        $allVulns += $vuln
                        
                        switch ($vuln.Severity) {
                            "CRITICAL" { $trivyCritical++ }
                            "HIGH" { $trivyHigh++ }
                            "MEDIUM" { $trivyMedium++ }
                            "LOW" { $trivyLow++ }
                        }
                    }
                }
            }
        }
        
        $report += @"
### Summary
- **Total Vulnerabilities:** $trivyTotal
- **Critical:** $trivyCritical 🔴
- **High:** $trivyHigh 🟠
- **Medium:** $trivyMedium 🟡
- **Low:** $trivyLow 🔵

**Image:** ``$env:DOCKER_IMAGE``

"@

        if ($trivyTotal -eq 0) {
            $report += "**Status:** ✅ **CLEAN** - No vulnerabilities found in Docker image!`n`n"
        } else {
            $report += "**Status:** ⚠️ **VULNERABILITIES FOUND** - Review required`n`n"
            
            # Show critical and high severity vulnerabilities
            $criticalAndHigh = $allVulns | Where-Object { $_.Severity -eq "CRITICAL" -or $_.Severity -eq "HIGH" } | Select-Object -First 15
            
            if ($criticalAndHigh.Count -gt 0) {
                $report += "### Critical & High Severity Findings`n`n"
                
                $vulnNum = 0
                foreach ($vuln in $criticalAndHigh) {
                    $vulnNum++
                    $vulnId = if ($vuln.VulnerabilityID) { $vuln.VulnerabilityID } else { "UNKNOWN" }
                    $pkgName = if ($vuln.PkgName) { $vuln.PkgName } else { "Unknown Package" }
                    $installedVer = if ($vuln.InstalledVersion) { $vuln.InstalledVersion } else { "unknown" }
                    $fixedVer = if ($vuln.FixedVersion) { $vuln.FixedVersion } else { "No fix available" }
                    $severity = if ($vuln.Severity) { $vuln.Severity } else { "UNKNOWN" }
                    $title = if ($vuln.Title) { $vuln.Title } else { $vulnId }
                    
                    $report += "#### $vulnNum. $vulnId - $title`n"
                    $report += "- **Package:** $pkgName`n"
                    $report += "- **Severity:** $severity`n"
                    $report += "- **Installed Version:** $installedVer`n"
                    $report += "- **Fixed Version:** $fixedVer`n"
                    if ($vuln.PrimaryURL) { $report += "- **Reference:** $($vuln.PrimaryURL)`n" }
                    $report += "`n"
                }
                
                if ($trivyCritical + $trivyHigh -gt 15) {
                    $report += "_... and $(($trivyCritical + $trivyHigh) - 15) more critical/high vulnerabilities. See trivy-report.json for complete details._`n`n"
                }
            }
        }
        
        $report += @"
### Recommended Actions
"@
        if ($trivyCritical -gt 0) {
            $report += @"

🔴 **CRITICAL PRIORITY:**
- Update base Docker image to latest patched version
- Review $trivyCritical critical vulnerabilities immediately
- Rebuild container with updated dependencies

"@
        }
        
        if ($trivyHigh -gt 0) {
            $report += @"
🟠 **HIGH PRIORITY:**
- Plan updates for $trivyHigh high-severity vulnerabilities
- Update system packages in Dockerfile
- Consider using minimal base images (alpine, distroless)

"@
        }
        
        if ($trivyMedium -gt 0 -or $trivyLow -gt 0) {
            $report += @"
🟡 **MEDIUM PRIORITY:**
- Review medium/low severity issues during next maintenance window
- Update non-critical packages

"@
        }
        
        if ($trivyTotal -eq 0) {
            $report += @"
✅ **No action required** - Docker image is secure!

"@
        }
        
    } else {
        $report += "⚠️ **Trivy scan results not available** - Docker scan may not have run.`n`n"
    }
} catch {
    $report += "⚠️ **Error parsing Trivy results:** $($_.Exception.Message)`n`n"
}

# ═══════════════════════════════════════════════════════════════════
# SECTION 3: OVERALL SUMMARY & RISK ASSESSMENT
# ═══════════════════════════════════════════════════════════════════

$report += @"
---

## 📊 3. Overall Security Summary

"@

# Calculate total risk
$totalCritical = $npmCritical + $trivyCritical
$totalHigh = $npmHigh + $trivyHigh
$totalVulns = $npmTotal + $trivyTotal

if ($totalVulns -eq 0) {
    $report += @"
### ✅ Security Status: **EXCELLENT**

**All security scans passed with no vulnerabilities found!**

Your application and its dependencies are currently secure. Continue monitoring for new vulnerabilities with each build.

"@
} elseif ($totalCritical -gt 0) {
    $report += @"
### 🔴 Security Status: **CRITICAL - IMMEDIATE ACTION REQUIRED**

**$totalCritical critical vulnerabilities detected!**

This represents a **HIGH SECURITY RISK**. Critical vulnerabilities should be addressed immediately before deploying to production.

"@
} elseif ($totalHigh -gt 0) {
    $report += @"
### 🟠 Security Status: **HIGH RISK - ACTION REQUIRED**

**$totalHigh high-severity vulnerabilities detected.**

These vulnerabilities pose a significant security risk and should be prioritized for remediation.

"@
} else {
    $report += @"
### 🟡 Security Status: **MODERATE RISK**

**$totalVulns low/medium severity vulnerabilities detected.**

While not immediately critical, these should be addressed in upcoming maintenance cycles.

"@
}

# ═══════════════════════════════════════════════════════════════════
# SECTION 4: NEXT STEPS
# ═══════════════════════════════════════════════════════════════════

$report += @"
---

## 🔧 4. Next Steps

### Immediate Actions (Today)
1. ✅ Review this security report
2. ✅ Archive this report in Jenkins artifacts
3. ✅ Assess business impact of identified vulnerabilities

### Short-term (This Week)
"@

if ($npmCritical -gt 0 -or $trivyCritical -gt 0) {
    $report += @"
1. 🔴 **FIX CRITICAL VULNERABILITIES** - Do not deploy until resolved
2. Update dependencies with ``npm audit fix`` or manual updates
3. Rebuild and re-scan Docker images
4. Re-run security pipeline to verify fixes

"@
} elseif ($npmHigh -gt 0 -or $trivyHigh -gt 0) {
    $report += @"
1. 🟠 Plan remediation for high-severity vulnerabilities
2. Update affected packages and dependencies
3. Test thoroughly in staging environment
4. Re-run security scan to verify fixes

"@
} else {
    $report += @"
1. 🟡 Schedule updates for identified vulnerabilities
2. Review and plan dependency updates
3. Monitor for new security advisories

"@
}

$report += @"
### Long-term (Ongoing)
1. Run security scans on every build
2. Enable automated dependency updates (Dependabot/Renovate)
3. Subscribe to security advisories for used packages
4. Regular security audits and penetration testing
5. Security training for development team

---

## 📎 Attachments

The following detailed reports are available as Jenkins artifacts:
- ``npm-audit-full.json`` - Complete NPM vulnerability report
- ``npm-audit-summary.txt`` - NPM audit text summary
- ``trivy-report.json`` - Complete Trivy scan results
- ``trivy-summary.txt`` - Trivy scan text summary

---

**Report Generated:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  
**Pipeline:** $env:JOB_NAME  
**Build:** #$env:BUILD_NUMBER  

_This is an automated security report. For questions, contact the DevOps team._
"@

# ═══════════════════════════════════════════════════════════════════
# WRITE REPORT TO FILE
# ═══════════════════════════════════════════════════════════════════

try {
    $report | Out-File -FilePath "SECURITY_FINDINGS.md" -Encoding UTF8 -Force
    Write-Host "✅ Security report generated: SECURITY_FINDINGS.md"
    Write-Host "   Total vulnerabilities: NPM=$npmTotal, Trivy=$trivyTotal"
    Write-Host "   Critical: NPM=$npmCritical, Trivy=$trivyCritical"
    Write-Host "   High: NPM=$npmHigh, Trivy=$trivyHigh"
} catch {
    Write-Host "❌ Error writing report: $($_.Exception.Message)"
    exit 1
}

Write-Host "============================================"
Write-Host "✅ SECURITY REPORT GENERATION COMPLETE"
Write-Host "============================================"
