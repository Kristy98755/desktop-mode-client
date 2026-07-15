# pc_info.ps1 - Быстрый опрос железа ПК через WMI
# Вывод: ключ=значение (одна строка на поле)
# Использование: powershell -NoProfile -ExecutionPolicy Bypass -File pc_info.ps1

$ErrorActionPreference = "SilentlyContinue"

# Windows
$os = Get-CimInstance Win32_OperatingSystem -Property Caption,Version,BuildNumber,OSArchitecture -ErrorAction SilentlyContinue
if ($os) {
    "PC_WINDOWS=$($os.Caption)"
    "PC_WIN_VER=$($os.Version)"
    "PC_WIN_BUILD=$($os.BuildNumber)"
    "PC_WIN_ARCH=$($os.OSArchitecture)"
}
"PC_PS_VER=$($PSVersionTable.PSVersion)"

# CPU
$cpu = Get-CimInstance Win32_Processor -Property Name,NumberOfCores,NumberOfLogicalProcessors,MaxClockSpeed,LoadPercentage -ErrorAction SilentlyContinue | Select-Object -First 1
if ($cpu) {
    $cpuName = $cpu.Name -replace '\s+',' '
    "PC_CPU=$cpuName"
    "PC_CPU_CORES=$($cpu.NumberOfCores)"
    "PC_CPU_THREADS=$($cpu.NumberOfLogicalProcessors)"
    "PC_CPU_MHZ=$($cpu.MaxClockSpeed)"
    "PC_CPU_LOAD=$($cpu.LoadPercentage)"
}

# GPU
$gpus = Get-CimInstance Win32_VideoController -Property Name,AdapterRAM,DriverVersion,CurrentHorizontalResolution,CurrentVerticalResolution,CurrentRefreshRate -ErrorAction SilentlyContinue
$gi = 0
foreach ($gpu in $gpus) {
    $gi++
    $gName = $gpu.Name -replace '\s+',' '
    "PC_GPU${gi}=$gName"
    "PC_GPU${gi}_RAM=$($gpu.AdapterRAM)"
    "PC_GPU${gi}_DRV=$($gpu.DriverVersion)"
    "PC_GPU${gi}_RES=$($gpu.CurrentHorizontalResolution)x$($gpu.CurrentVerticalResolution)"
    "PC_GPU${gi}_HZ=$($gpu.CurrentRefreshRate)"
}
"PC_GPU_COUNT=$gi"

# RAM
$os2 = Get-CimInstance Win32_OperatingSystem -Property TotalVisibleMemorySize,FreePhysicalMemory -ErrorAction SilentlyContinue
if ($os2) {
    $totalMB = [math]::Round([long]$os2.TotalVisibleMemorySize / 1024)
    $freeMB = [math]::Round([long]$os2.FreePhysicalMemory / 1024)
    "PC_RAM_TOTAL=${totalMB}MB"
    "PC_RAM_FREE=${freeMB}MB"
    "PC_RAM_USED=$($totalMB - $freeMB)MB"
}

# RAM modules
$mem = Get-CimInstance Win32_PhysicalMemory -Property Capacity,Speed,FormFactor -ErrorAction SilentlyContinue
if ($mem) {
    $modCount = 0
    $totalPhys = 0
    foreach ($m in $mem) {
        $modCount++
        $totalPhys += [long]$m.Capacity
        if ($modCount -le 4) {
            $capGB = [math]::Round([long]$m.Capacity / 1GB, 1)
            $ff = if ($m.FormFactor -eq 12) {"SODIMM"} else {"DIMM"}
            "PC_MOD${modCount}=${capGB}GB $($m.Speed)MHz $ff"
        }
    }
    "PC_MOD_COUNT=$modCount"
    "PC_RAM_PHYS=$([math]::Round($totalPhys / 1GB))GB"
}

# Displays (Screen class)
try {
    Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
    $screens = [System.Windows.Forms.Screen]::AllScreens
    $di = 0
    foreach ($s in $screens) {
        $di++
        "PC_DISP${di}=$($s.Bounds.Width)x$($s.Bounds.Height) DPI=$($s.DpiX) Scale=$([math]::Round($s.DpiX/96*100))%% $(if($s.Primary){'PRIMARY'}else{''})"
        "PC_DISP${di}_WORK=$($s.WorkingArea.Width)x$($s.WorkingArea.Height)"
    }
    "PC_DISP_COUNT=$di"
} catch {
    "PC_DISP_COUNT=0"
}

# Monitors (WMI)
$monitors = Get-CimInstance -Namespace "root\wmi" -ClassName WmiMonitorBasicDisplayParams -Property MaxHorizontalImageSize,MaxVerticalImageSize -ErrorAction SilentlyContinue
$monitorIds = Get-CimInstance -Namespace "root\wmi" -ClassName WmiMonitorID -Property ManufacturerName,UserFriendlyName -ErrorAction SilentlyContinue
$monConn = Get-CimInstance -Namespace "root\wmi" -ClassName WmiMonitorConnectionParams -Property VideoOutputTechnology -ErrorAction SilentlyContinue
$mi = 0
if ($monitors) {
    foreach ($m in $monitors) {
        $mi++
        $diag = [math]::Sqrt([math]::Pow($m.MaxHorizontalImageSize,2) + [math]::Pow($m.MaxVerticalImageSize,2))
        $diagInch = [math]::Round($diag, 1)
        $mfg = ""
        $model = ""
        if ($monitorIds -and $mi -le $monitorIds.Count) {
            $id = $monitorIds[$mi - 1]
            try { $mfg = ($id.ManufacturerName | Where-Object {$_ -ne 0} | ForEach-Object {[char]$_}) -join '' } catch {}
            try { $model = ($id.UserFriendlyName | Where-Object {$_ -ne 0} | ForEach-Object {[char]$_}) -join '' } catch {}
        }
        $connType = ""
        if ($monConn -and $mi -le $monConn.Count) {
            $connType = switch ($monConn[$mi-1].VideoOutputTechnology) {
                3 {"HDMI"}; 4 {"DisplayPort"}; 1 {"DVI"}; 0 {"VGA"}; 10 {"Internal"}; default {"Unknown"}
            }
        }
        "PC_MON${mi}=${diagInch}in ${mfg} ${model} [$connType]"
    }
}
"PC_MON_COUNT=$mi"

# Disks
$disks = Get-CimInstance Win32_DiskDrive -Property Model,Size,InterfaceType,MediaType -ErrorAction SilentlyContinue
$dk = 0
foreach ($d in $disks) {
    $dk++
    $sizeGB = [math]::Round([long]$d.Size / 1GB)
    "PC_DISK${dk}=$($d.Model) ${sizeGB}GB $($d.InterfaceType) [$($d.MediaType)]"
}
"PC_DISK_COUNT=$dk"
