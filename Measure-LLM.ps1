param([int]$ServerProcessId, [int]$Seconds = 240, [string]$Output = "$PSScriptRoot\logs\memory.csv")
$rows = [System.Collections.Generic.List[object]]::new()
for ($i = 0; $i -lt $Seconds; $i++) {
    $proc = Get-Process -Id $ServerProcessId -ErrorAction SilentlyContinue
    if (!$proc) { break }
    $gpu = Get-CimInstance Win32_PerfFormattedData_GPUPerformanceCounters_GPUProcessMemory | Where-Object Name -Like "pid_${ServerProcessId}_*"
    $adapter = Get-CimInstance Win32_PerfFormattedData_GPUPerformanceCounters_GPUAdapterMemory
    $os = Get-CimInstance Win32_OperatingSystem
    $rows.Add([pscustomobject]@{
        Timestamp = (Get-Date).ToString('o')
        WorkingSetMiB = [math]::Round($proc.WorkingSet64 / 1MB, 2)
        PrivateMiB = [math]::Round($proc.PrivateMemorySize64 / 1MB, 2)
        GpuDedicatedMiB = [math]::Round(($gpu | Measure-Object DedicatedUsage -Sum).Sum / 1MB, 2)
        GpuSharedMiB = [math]::Round(($gpu | Measure-Object SharedUsage -Sum).Sum / 1MB, 2)
        TotalGpuDedicatedMiB = [math]::Round(($adapter | Measure-Object DedicatedUsage -Sum).Sum / 1MB, 2)
        SystemUsedMiB = [math]::Round(($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / 1024, 2)
    })
    $rows | Export-Csv -NoTypeInformation -Path $Output
    Start-Sleep -Seconds 1
}
