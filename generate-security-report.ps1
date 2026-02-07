# Security Findings Report Generator
# Parses NPM audit and Trivy scan results into comprehensive markdown

Write-Host "============================================"
Write-Host "GENERATING COMPREHENSIVE SECURITY REPORT"
Write-Host "============================================"

# Initialize variables
$npmTotal = 0
$npmInfo = 0
$npmLow = 0
$npmModerate = 0
$npmHigh = 0
$npmCritical = 0

$trivyTotal = 0
$trivyCritical = 0
$trivyHigh = 0
$trivyMedium = 0
$trivyLow = 0

# Start building report
$report = "# Security Scan Results - Build #$env:BUILD_NUMBER`n`n"
$report += "**Date:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n"
$report += "**Project:** $env:JOB_NAME`n"
$report += "**Build:** #$env:BUILD_NUMBER`n`n"
$report += "---`n`n"

# ========================================
# SECTION 1: NPM AUDIT RESULTS
# ========================================

$report += "## 1. NPM Dependency Security Audit`n`n"

try {
    if (Test-Path "npm-audit-full.json") {
        Write-Host "Processing NPM audit results..."
        
        $npmAudit = Get-Content "npm-audit-full.json" -Raw | ConvertFrom-Json
        
        if ($npmAudit.metadata.vulnerabilities) {
            $npmTotal = if ($npmAudit.metadata.vulnerabilities.total) { $npmAudit.metadata.vulnerabilities.total } else { 0 }
            $npmInfo = if ($npmAudit.metadata.vulnerabilities.info) { $npmAudit.metadata.vulnerabilities.info } else { 0 }
            $npmLow = if ($npmAudit.metadata.vulnerabilities.low) { $npmAudit.metadata.vulnerabilities.low } else { 0 }
            $npmModerate = if ($npmAudit.metadata.vulnerabilities.moderate) { $npmAudit.metadata.vulnerabilities.moderate } else { 0 }
            $npmHigh = if ($npmAudit.metadata.vulnerabilities.high) { $npmAudit.metadata.vulnerabilities.high } else { 0 }
            $npmCritical = if ($npmAudit.metadata.vulnerabilities.critical) { $npmAudit.metadata.vulnerabilities.critical } else { 0 }
        }
        
        $report += "### Summary`n"
        $report += "- **Total Vulnerabilities:** $npmTotal`n"
        $report += "- **Critical:** $npmCritical`n"
        $report += "- **High:** $npmHigh`n"
        $report += "- **Moderate:** $npmModerate`n"
        $report += "- **Low:** $npmLow`n"
        $report += "- **Info:** $npmInfo`n`n"
        
        if ($npmTotal -eq 0) {
            $report += "**Status:** CLEAN - No vulnerabilities found in NPM dependencies!`n`n"
        } else {
            $report += "**Status:** VULNERABILITIES FOUND - Review required`n`n"
            
            # Add detailed vulnerability information
            if ($npmAudit.vulnerabilities) {
                $report += "### Detailed Findings`n`n"
                
                $vulnCount = 0
                foreach ($vulnProp in $npmAudit.vulnerabilities.PSObject.Properties) {
                    $vulnCount++
                    if ($vulnCount -le 10) {
                        $vuln = $vulnProp.Value
                        $severity = if ($vuln.severity) { $vuln.severity.ToUpper() } else { "UNKNOWN" }
                        $name = if ($vuln.name) { $vuln.name } else { $vulnProp.Name }
                        
                        $via = "Direct vulnerability"
                        if ($vuln.via -and $vuln.via.Count -gt 0) {
                            if ($vuln.via[0] -is [string]) {
                                $via = $vuln.via[0]
                            } elseif ($vuln.via[0].title) {
                                $via = $vuln.via[0].title
                            }
                        }
                        
                        $report += "#### $vulnCount. $name`n"
                        $report += "- **Severity:** $severity`n"
                        $report += "- **Issue:** $via`n"
                        
                        if ($vuln.range) {
                            $report += "- **Affected Versions:** $($vuln.range)`n"
                        }
                        
                        if ($vuln.fixAvailable) {
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
        
        # Recommendations
        $report += "### Recommended Actions`n`n"
        
        if ($npmCritical -gt 0) {
            $report += "**CRITICAL PRIORITY:**`n"
            $report += "- Immediately review and fix $npmCritical critical vulnerabilities`n"
            $report += "- Run ``npm audit fix --force`` (test thoroughly after)`n"
            $report += "- Consider updating affected packages manually`n`n"
        }
        
        if ($npmHigh -gt 0) {
            $report += "**HIGH PRIORITY:**`n"
            $report += "- Review $npmHigh high-severity vulnerabilities`n"
            $report += "- Run ``npm audit fix`` to auto-fix compatible issues`n"
            $report += "- Plan manual updates for packages without auto-fix`n`n"
        }
        
        if ($npmModerate -gt 0 -or $npmLow -gt 0) {
            $report += "**MEDIUM PRIORITY:**`n"
            $report += "- Schedule updates for moderate/low severity issues`n"
            $report += "- Test in development environment first`n`n"
        }
        
        if ($npmTotal -eq 0) {
            $report += "No action required - All dependencies are secure!`n`n"
        }
        
    } else {
        $report += "NPM audit file not found - Scan may not have run successfully.`n`n"
    }
} catch {
    $report += "Error parsing NPM audit results: $($_.Exception.Message)`n`n"
}

# ========================================
# SECTION 2: DOCKER IMAGE SECURITY SCAN
# ========================================

$report += "---`n`n"
$report += "## 2. Docker Image Security Scan (Trivy)`n`n"

try {
    if (Test-Path "trivy-report.json") {
        Write-Host "Processing Trivy scan results..."
        
        $trivyReport = Get-Content "trivy-report.json" -Raw | ConvertFrom-Json
        
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
        
        $report += "### Summary`n"
        $report += "- **Total Vulnerabilities:** $trivyTotal`n"
        $report += "- **Critical:** $trivyCritical`n"
        $report += "- **High:** $trivyHigh`n"
        $report += "- **Medium:** $trivyMedium`n"
        $report += "- **Low:** $trivyLow`n`n"
        $report += "**Image:** ``$env:DOCKER_IMAGE```n`n"
        
        if ($trivyTotal -eq 0) {
            $report += "**Status:** CLEAN - No vulnerabilities found in Docker image!`n`n"
        } else {
            $report += "**Status:** VULNERABILITIES FOUND - Review required`n`n"
            
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
                    
                    if ($vuln.PrimaryURL) {
                        $report += "- **Reference:** $($vuln.PrimaryURL)`n"
                    }
                    $report += "`n"
                }
                
                if (($trivyCritical + $trivyHigh) -gt 15) {
                    $remaining = ($trivyCritical + $trivyHigh) - 15
                    $report += "_... and $remaining more critical/high vulnerabilities. See trivy-report.json for complete details._`n`n"
                }
            }
        }
        
        # Recommendations
        $report += "### Recommended Actions`n`n"
        
        if ($trivyCritical -gt 0) {
            $report += "**CRITICAL PRIORITY:**`n"
            $report += "- Update base Docker image to latest patched version`n"
            $report += "- Review $trivyCritical critical vulnerabilities immediately`n"
            $report += "- Rebuild container with updated dependencies`n`n"
        }
        
        if ($trivyHigh -gt 0) {
            $report += "**HIGH PRIORITY:**`n"
            $report += "- Plan updates for $trivyHigh high-severity vulnerabilities`n"
            $report += "- Update system packages in Dockerfile`n"
            $report += "- Consider using minimal base images (alpine, distroless)`n`n"
        }
        
        if ($trivyTotal -eq 0) {
            $report += "No action required - Docker image is secure!`n`n"
        }
        
    } else {
        $report += "Trivy scan results not available - Docker scan may not have run.`n`n"
    }
} catch {
    $report += "Error parsing Trivy results: $($_.Exception.Message)`n`n"
}

# ========================================
# SECTION 3: OVERALL SUMMARY
# ========================================

$report += "---`n`n"
$report += "## 3. Overall Security Summary`n`n"

$totalCritical = $npmCritical + $trivyCritical
$totalHigh = $npmHigh + $trivyHigh
$totalVulns = $npmTotal + $trivyTotal

if ($totalVulns -eq 0) {
    $report += "### Security Status: EXCELLENT`n`n"
    $report += "**All security scans passed with no vulnerabilities found!**`n`n"
    $report += "Your application and its dependencies are currently secure.`n`n"
} elseif ($totalCritical -gt 0) {
    $report += "### Security Status: CRITICAL - IMMEDIATE ACTION REQUIRED`n`n"
    $report += "**$totalCritical critical vulnerabilities detected!**`n`n"
    $report += "This represents a HIGH SECURITY RISK. Address immediately before deploying to production.`n`n"
} elseif ($totalHigh -gt 0) {
    $report += "### Security Status: HIGH RISK - ACTION REQUIRED`n`n"
    $report += "**$totalHigh high-severity vulnerabilities detected.**`n`n"
    $report += "These vulnerabilities pose a significant security risk and should be prioritized.`n`n"
} else {
    $report += "### Security Status: MODERATE RISK`n`n"
    $report += "**$totalVulns low/medium severity vulnerabilities detected.**`n`n"
    $report += "Address these in upcoming maintenance cycles.`n`n"
}

# ========================================
# SECTION 4: NEXT STEPS
# ========================================

$report += "---`n`n"
$report += "## 4. Next Steps`n`n"

$report += "### Immediate Actions (Today)`n"
$report += "1. Review this security report`n"
$report += "2. Archive this report in Jenkins artifacts`n"
$report += "3. Assess business impact of identified vulnerabilities`n`n"

$report += "### Short-term (This Week)`n"

if ($npmCritical -gt 0 -or $trivyCritical -gt 0) {
    $report += "1. **FIX CRITICAL VULNERABILITIES** - Do not deploy until resolved`n"
    $report += "2. Update dependencies with ``npm audit fix`` or manual updates`n"
    $report += "3. Rebuild and re-scan Docker images`n"
    $report += "4. Re-run security pipeline to verify fixes`n`n"
} elseif ($npmHigh -gt 0 -or $trivyHigh -gt 0) {
    $report += "1. Plan remediation for high-severity vulnerabilities`n"
    $report += "2. Update affected packages and dependencies`n"
    $report += "3. Test thoroughly in staging environment`n"
    $report += "4. Re-run security scan to verify fixes`n`n"
} else {
    $report += "1. Schedule updates for identified vulnerabilities`n"
    $report += "2. Review and plan dependency updates`n"
    $report += "3. Monitor for new security advisories`n`n"
}

$report += "### Long-term (Ongoing)`n"
$report += "1. Run security scans on every build`n"
$report += "2. Enable automated dependency updates (Dependabot/Renovate)`n"
$report += "3. Subscribe to security advisories for used packages`n"
$report += "4. Regular security audits and penetration testing`n`n"

# ========================================
# FOOTER
# ========================================

$report += "---`n`n"
$report += "## Attachments`n`n"
$report += "The following detailed reports are available as Jenkins artifacts:`n"
$report += "- ``npm-audit-full.json`` - Complete NPM vulnerability report`n"
$report += "- ``npm-audit-summary.txt`` - NPM audit text summary`n"
$report += "- ``trivy-report.json`` - Complete Trivy scan results`n"
$report += "- ``trivy-summary.txt`` - Trivy scan text summary`n`n"

$report += "---`n`n"
$report += "**Report Generated:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n"
$report += "**Pipeline:** $env:JOB_NAME`n"
$report += "**Build:** #$env:BUILD_NUMBER`n`n"
$report += "_This is an automated security report._`n"

# ========================================
# WRITE REPORT TO FILE
# ========================================

try {
    $report | Out-File -FilePath "SECURITY_FINDINGS.md" -Encoding UTF8 -Force
    Write-Host "============================================"
    Write-Host "Security report generated: SECURITY_FINDINGS.md"
    Write-Host "Total vulnerabilities:"
    Write-Host "  NPM: Total=$npmTotal, Critical=$npmCritical, High=$npmHigh"
    Write-Host "  Trivy: Total=$trivyTotal, Critical=$trivyCritical, High=$trivyHigh"
    Write-Host "============================================"
} catch {
    Write-Host "Error writing report: $($_.Exception.Message)"
    exit 1
}

Write-Host "SECURITY REPORT GENERATION COMPLETE"
