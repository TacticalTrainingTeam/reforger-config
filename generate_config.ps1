# generate_config.ps1
# This script reads config.json and applies overrides from .env using jq.
# The .env file should contain lines in the format: .path.to.key="value"

$templateFile = "config.json"
$envFile = ".env"
$outputFile = "generated_config.json"

if (-not (Test-Path $templateFile)) {
    Write-Error "Template file $templateFile not found."
    exit 1
}

if (-not (Test-Path $envFile)) {
    Write-Error "Environment file $envFile not found."
    exit 1
}

# Start with the template content
$currentConfig = Get-Content -Raw $templateFile

# Read .env file
$envLines = Get-Content $envFile | Where-Object { $_ -match "=" }

foreach ($line in $envLines) {
    # Split by the first '='
    $parts = $line -split '=', 2
    if ($parts.Count -eq 2) {
        $path = $parts[0].Trim()
        $rawValue = $parts[1].Trim()
        $value = $rawValue
        
        # Remove surrounding quotes from value if they exist
        if ($value -match '^"(.*)"$') {
            $value = $matches[1]
        }
        
        Write-Host "Applying $path"
        
        # Determine if the value is a number or boolean (unquoted in .env) 
        # or if it should be treated as a string.
        # If it was quoted in .env, we'll treat it as a string.
        # If it wasn't quoted, we check if it's a number/boolean.
        
        if ($rawValue -match '^"(.*)"$') {
            # Quoted: use --arg to ensure it's a JSON string
            $currentConfig = $currentConfig | jq --arg val "$value" "($path) = `$val"
        } elseif ($value -eq "true" -or $value -eq "false" -or $value -match '^-?\d+(\.\d+)?$') {
            # Boolean or Number: use --argjson to parse it
            $currentConfig = $currentConfig | jq --argjson val "$value" "($path) = `$val"
        } else {
            # Otherwise default to string
            $currentConfig = $currentConfig | jq --arg val "$value" "($path) = `$val"
        }
        
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to apply $path"
            exit 1
        }
    }
}

# Save the final config
$currentConfig | Out-File -FilePath $outputFile -Encoding utf8
Write-Host "Success! Config saved to $outputFile"
