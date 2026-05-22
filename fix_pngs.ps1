Add-Type -AssemblyName System.Drawing
$resPath = "C:\Users\yusf2000.runnervm3zftq\Downloads\qalay muslmanv3\qalay muslman\qalay muslman\recovery_app\android\app\src\main\res"
Get-ChildItem -Path $resPath -Filter "ic_launcher*.png" -Recurse | ForEach-Object {
    try {
        $img = [System.Drawing.Image]::FromFile($_.FullName)
        $tempPath = $_.FullName + ".tmp"
        $img.Save($tempPath, [System.Drawing.Imaging.ImageFormat]::Png)
        $img.Dispose()
        Remove-Item $_.FullName -Force
        Rename-Item $tempPath $_.Name
        Write-Host "Successfully fixed $($_.FullName)"
    } catch {
        Write-Host "Failed to fix $($_.FullName): $_"
    }
}
