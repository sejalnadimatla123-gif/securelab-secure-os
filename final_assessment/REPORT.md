# Mission 22 — Final Challenge: Secure the Machine

**Status: scaffold only.** This report cannot be completed until the team has:
1. Imported the instructor-provided target (`.ova`, e.g. Metasploitable or another
   public vulnerable VM) into VirtualBox on a real machine, **or**
2. Treated an existing SECURELAB VM snapshot as the assessment target,

and has the instructor's separate rules/resources document in hand. Nothing
in this file is a real finding yet — fill in each section with genuine
command output from `bash final_assessment/baseline.sh` and your own
investigation. Do not invent findings to fill the template.

## Workflow checklist (handout items 68–75)
- [ ] 68. Baseline captured (`final_assessment/baseline_<timestamp>.txt`)
- [ ] 69. At least 5 security observations identified
- [ ] 70. Each observation classified (confidentiality / integrity /
      availability / authentication / authorization / isolation / attack surface)
- [ ] 71. OS-level control chosen per observation
- [ ] 72. Control applied
- [ ] 73. Original condition re-tested
- [ ] 74. Evidence captured (before/after)
- [ ] 75. This report written

## Executive summary
_One paragraph: what was the target, what did we find, what did we fix._

## System profile
_Fill from `baseline.sh`: OS/kernel version, users, running services, listening
ports, notable files._

## Threat model
_Who is the attacker (local unprivileged user? remote network attacker?), what
do they want, what do they already have access to._

## Attack surface
_List the entry points identified in the baseline: network services, SUID
binaries, writable files, weak accounts, etc._

## Findings and evidence

### Finding 1
- **Observation:**
- **Classification:**
- **Evidence (before):**
- **Control applied:**
- **Evidence (after):**

### Finding 2
_(repeat for at least 5 findings — see "Possible findings" in the handout for
categories: excess file permission, unnecessary service, excess process
privilege, undetectable file modification, unnecessary listening service,
unconfined application, insufficient logs, missing updates)_

## Remediation and rationale
_Why each specific OS-level control (not a generic "harden everything") was
chosen for each finding._

## Verification
_Show the original vulnerable condition no longer reproduces, without
breaking the system's legitimate function._

## Reflection
76. Which protection mechanism surprised you most?
77. Which security problem required more than one OS mechanism to solve?
78. Which experiment made process isolation or memory protection clearer?
79. Where did least privilege appear repeatedly?
80. What would happen if the kernel itself were compromised?

## Future improvements
_What would you do with more time/privilege (e.g. SELinux instead of
AppArmor, intrusion detection, automated patch management)._
