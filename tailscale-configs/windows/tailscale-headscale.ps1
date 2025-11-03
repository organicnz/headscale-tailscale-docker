# PowerShell Script to Connect Tailscale to Headscale
# Run as Administrator

# Configuration
$LoginServer = "http://YOUR_HEADSCALE_HOST:8000"
$AuthKey = "YOUR_PREAUTH_KEY"  # Generate with: docker exec headscale headscale preauthkeys create --user 1 --reusable --expiration 24h

# Optional parameters
$AcceptRoutes = $true
$AdvertiseExitNode = $false
$AdvertiseRoutes = ""  # Example: "192.168.1.0/24,10.0.0.0/24"
$Hostname = ""  # Leave empty for default

# Build the command
$TailscaleCmd = "tailscale up --login-server=$LoginServer --authkey=$AuthKey"

if ($AcceptRoutes) {
    $TailscaleCmd += " --accept-routes"
}

if ($AdvertiseExitNode) {
    $TailscaleCmd += " --advertise-exit-node"
}

if ($AdvertiseRoutes -ne "") {
    $TailscaleCmd += " --advertise-routes=$AdvertiseRoutes"
}

if ($Hostname -ne "") {
    $TailscaleCmd += " --hostname=$Hostname"
}

# Check if Tailscale is installed
$TailscalePath = Get-Command tailscale -ErrorAction SilentlyContinue

if (-not $TailscalePath) {
    Write-Host "ERROR: Tailscale is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Download from: https://tailscale.com/download/windows" -ForegroundColor Yellow
    exit 1
}

# Execute the command
Write-Host "Connecting to Headscale..." -ForegroundColor Green
Write-Host "Command: $TailscaleCmd" -ForegroundColor Cyan

try {
    Invoke-Expression $TailscaleCmd
    Write-Host "`nSuccessfully connected to Headscale!" -ForegroundColor Green
    Write-Host "Check status with: tailscale status" -ForegroundColor Cyan
} catch {
    Write-Host "`nERROR: Failed to connect to Headscale" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
