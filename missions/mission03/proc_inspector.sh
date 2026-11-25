#!/usr/bin/env bash
# Mission 3: Process Detective — inspect a process's /proc/<PID> directory.
# Usage: ./proc_inspector.sh <PID>

PID="$1"

if [ -z "$PID" ]; then
    echo "Usage: $0 <PID>"
    exit 1
fi

if [ ! -d "/proc/$PID" ]; then
    echo "Process $PID does not exist."
    exit 1
fi

echo "PID: $PID"
echo "Command: $(tr '\0' ' ' < "/proc/$PID/cmdline")"
echo "Status:"
grep -E '^(Name|State|PPid|Uid|Gid|Threads|VmSize|VmRSS):' "/proc/$PID/status"
echo "Open file descriptors: $(ls "/proc/$PID/fd" 2>/dev/null | wc -l)"

# Security-relevant addition: process start time, derived from clock ticks
# since boot (field 22 of /proc/<PID>/stat), converted to wall-clock time.
# A process start time that doesn't match a known deploy/login time is a
# useful anomaly indicator during an investigation.
if [ -r "/proc/$PID/stat" ] && [ -r /proc/uptime ]; then
    HZ=$(getconf CLK_TCK 2>/dev/null || echo 100)
    START_TICKS=$(awk '{print $22}' "/proc/$PID/stat")
    UPTIME_SEC=$(awk '{print $1}' /proc/uptime)
    BOOT_EPOCH=$(($(date +%s) - ${UPTIME_SEC%.*}))
    START_EPOCH=$((BOOT_EPOCH + START_TICKS / HZ))
    echo "Start time: $(date -d @"$START_EPOCH" 2>/dev/null || date -r "$START_EPOCH")"
fi
