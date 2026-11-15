
# Mission 14: What Happened While I Was Away?

## 1. Objective
Use Linux system logs to reconstruct a timeline of recent system activity and understand the importance of logging and auditing.

## 2. Tools Used
- journalctl
- systemctl
- last

## 3. Experiments Performed

### Experiment 1: Inspect Recent System Logs

Command:
```bash
journalctl -n 30 --no-pager
```

Observation:
The system journal displayed GNOME session activity, graphics-related warnings, kernel messages, background services and Ubuntu Insights activity.

### Experiment 2: Filter Logs by Time

Command:
```bash
journalctl --since "15 minutes ago" --no-pager
```

Observation:
The command filtered journal entries to show recent system activity, including Ubuntu Insights activity, kernel warnings and background service events.

### Experiment 3: Inspect SSH Service Status

Command:
```bash
sudo systemctl status ssh --no-pager
```

Observation:
The SSH service unit could not be found because OpenSSH Server had not yet been installed.

### Experiment 4: Inspect Login History

Command:
```bash
last | head -10
```

Observation:
The output showed local login sessions for user `sejal`, including terminal `tty2` and login timestamps from November 13 to November 15, 2026.

### Experiment 5: Inspect SSH Logs

Command:
```bash
sudo journalctl -u ssh --no-pager -n 20
```

Observation:
No SSH journal entries were available at the time of inspection.

## 4. Event Timeline

| Event | Timestamp (November 15, 2026) | Observation |
|---|---|---|
| 1 | 23:15:05 | Ubuntu Insights collection reported that a report already existed for the period. |
| 2 | 23:15:09 | Kernel reported a blk_mq_run_work_fn workqueue CPU warning. |
| 3 | 23:15:10 | systemd-timedated service was deactivated successfully. |
| 4 | 23:16:03 | Launchpad cache-clean service skipped cleanup because its condition was not met. |
| 5 | 23:16:23 | Kernel reported an e1000_watchdog CPU warning. |

## 5. Limitations of System Logs

- Logs may not record every activity.
- Logs can be rotated or deleted.
- Privileged users may be able to modify or remove logs.
- Logs require interpretation and may not explain the complete cause of an event.

## 6. Security Relevance

Logging and auditing help system administrators:
- Investigate suspicious activity.
- Reconstruct event timelines.
- Identify service failures.
- Monitor authentication attempts.
- Detect unusual system behavior.

## 7. Conclusion

Linux journald and login history provide useful information for reconstructing system activity. However, logs must be interpreted carefully because they may be incomplete or altered.
