# Reads .env and launches the app with values passed as --dart-define.
# Usage:  ./run.ps1        (PowerShell, defaults to chrome)
#         ./run.ps1 edge   (or another device id)
param([string]$Device = "chrome")

Get-Content .env | ForEach-Object {
  $line = $_.Trim()
  if ($line -and -not $line.StartsWith("#") -and $line.Contains("=")) {
    $parts = $line.Split("=", 2)
    Set-Variable -Name $parts[0].Trim() -Value $parts[1].Trim()
  }
}

flutter run -d $Device `
  --dart-define=SUPABASE_URL="$SUPABASE_URL" `
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" `
  --dart-define=FLW_PUBLIC_KEY="$FLW_PUBLIC_KEY"
