# Lokal tekshirish (deploysiz): web build + shu kompyuterda server.
#
# Ishlatish (app/ papkasida):   powershell -ExecutionPolicy Bypass -File .\lokal.ps1
# Keyin telefonda (bir xil Wi-Fi):  http://<kompyuter IP>:8080   (IP pastda chiqadi)
# Kompyuterda:                       http://localhost:8080
#
# NEGA .dart_tool/flutter_build o'chiriladi: Flutter web build'ining kesh
# papkasida `web_plugin_registrant.dart` eskirib qolishi mumkin (2026-09-12 da
# shunday bo'ldi: audioplayers qo'shilishidan OLDINGI ro'yxat qolib ketgan,
# natijada ovoz plagini JS ichiga kirmay, ilova butunlay ovozsiz bo'lgan).
# Papkani o'chirish uni har safar yangidan yaratishga majbur qiladi.

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

if (Test-Path ".dart_tool/flutter_build") {
    Remove-Item -Recurse -Force ".dart_tool/flutter_build"
}

flutter build web --release
if ($LASTEXITCODE -ne 0) { throw "flutter build web muvaffaqiyatsiz" }

# Ovoz plagini haqiqatan kirganini tekshirish (audioplayers_web belgisi).
$js = Get-Content "build/web/main.dart.js" -Raw
if ($js -notmatch "WebAudioError") {
    throw "DIQQAT: build ichida audioplayers web plagini yo'q - ovoz chiqmaydi. .dart_tool ni to'liq o'chirib qayta urinib ko'ring."
}
Write-Host "OK: ovoz plagini build ichida." -ForegroundColor Green

$ip = (Get-NetIPAddress -AddressFamily IPv4 |
    Where-Object { $_.IPAddress -notlike "127.*" -and $_.IPAddress -notlike "169.254.*" } |
    Select-Object -First 1).IPAddress
Write-Host ""
Write-Host "Kompyuterda:  http://localhost:8080" -ForegroundColor Cyan
Write-Host "Telefonda:    http://${ip}:8080   (bir xil Wi-Fi)" -ForegroundColor Cyan
Write-Host "To'xtatish:   Ctrl+C" -ForegroundColor DarkGray
Write-Host ""

python -m http.server 8080 --bind 0.0.0.0 --directory build/web
