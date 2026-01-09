# Build AAB for com.alkhatm.app2
Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan
Write-Host " Building AAB for com.alkhatm.app2 v1.0.0  " -ForegroundColor Yellow
Write-Host " Start Time: $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════`n" -ForegroundColor Cyan

# Ensure we're in the correct directory
Set-Location "d:\XAMPP\htdocs\wordpress\alkhatm"
Write-Host "Current Directory: $(Get-Location)`n" -ForegroundColor Gray

# Run the build
flutter build appbundle --release

# Check result
if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✅ BUILD SUCCESSFUL!" -ForegroundColor Green
    Write-Host "Completion Time: $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor Green
    
    # Display file info
    $aabPath = "d:\XAMPP\htdocs\wordpress\alkhatm\build\app\outputs\bundle\release\app-release.aab"
    if (Test-Path $aabPath) {
        $aab = Get-Item $aabPath
        Write-Host "`n📦 AAB File Information:" -ForegroundColor Cyan
        Write-Host "   Location: $($aab.FullName)" -ForegroundColor White
        Write-Host "   Size: $([math]::Round($aab.Length/1MB, 2)) MB" -ForegroundColor White
        Write-Host "   Created: $($aab.LastWriteTime)" -ForegroundColor White
    }
} else {
    Write-Host "`n❌ BUILD FAILED!" -ForegroundColor Red
    Write-Host "Exit Code: $LASTEXITCODE" -ForegroundColor Red
}
