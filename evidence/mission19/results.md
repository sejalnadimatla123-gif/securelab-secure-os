# Mission 19: Harden the Machine

## 1. Objective

Perform a baseline security audit of the Ubuntu virtual machine, identify areas for improvement, apply justified hardening changes, and verify that the changes work.

## 2. System Baseline (Before Hardening)

The following checks were performed before making security changes.

| Check | Baseline observation |
|---|---|
| Upgradable packages | 122 lines from the command output, including the heading (approximately 121 package entries) |
| Running services | 36 output lines |
| Listening ports | 13 output lines |
| UFW firewall | Inactive |
| Kernel version | `7.0.0-43-generic` |

**Commands used:**

```bash
sudo apt update
apt list --upgradable 2>/dev/null | wc -l
systemctl --type=service --state=running --no-pager | wc -l
ss -lntup 2>/dev/null | wc -l
sudo ufw status verbose
uname -r
```

Note: Package metadata was refreshed using `apt update`. No full system upgrade was performed.

## 3. Hardening Changes

### Change 1: Enable UFW Firewall

**Initial state:** Firewall was inactive.

**Commands used:**

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow OpenSSH
sudo ufw enable
sudo ufw status verbose
```

**Justification:**

A firewall reduces the machine's network attack surface by controlling incoming and outgoing connections. Denying incoming connections by default prevents unsolicited connections, while allowing outgoing connections preserves normal network access. SSH was explicitly allowed to avoid blocking the remote-access service used in the lab.

**Verification:**

- UFW reported `Status: active`.
- Default incoming policy: deny.
- Default outgoing policy: allow.
- SSH was added as an allowed firewall rule.

### Change 2: Disable IPv4 ICMP Redirect Acceptance and Sending

**Initial setting:** The system's IPv4 redirect settings were not explicitly hardened as part of the baseline.

**Commands used:**

```bash
sudo sysctl -w net.ipv4.conf.all.accept_redirects=0
sudo nano /etc/sysctl.d/99-securelab.conf
```

The following configuration was added:

```ini
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
```

The settings were applied using:

```bash
sudo sysctl --system
```

**Justification:**

ICMP redirects can influence routing decisions. Disabling their acceptance reduces the risk of an attacker influencing the machine's network routing through redirect messages. Disabling redirect sending also prevents the machine from sending these redirects.

**Verification:**

```bash
sysctl net.ipv4.conf.all.accept_redirects net.ipv4.conf.default.accept_redirects net.ipv4.conf.all.send_redirects
```

All three settings returned `0`.

The settings were checked again after restarting the VM and remained `0`, confirming persistence across reboot.

### Change 3: Strengthen SSH Configuration

**Initial setting:** The SSH configuration reported:

```text
permitrootlogin prohibit-password
```

A configuration drop-in file was created:

```bash
sudo nano /etc/ssh/sshd_config.d/99-securelab.conf
```

The following settings were added:

```ini
PermitRootLogin no
MaxAuthTries 3
```

The configuration was validated using:

```bash
sudo sshd -t
```

No errors were reported.

**Justification:**

Disabling root login over SSH prevents direct remote login using the root account. Limiting authentication attempts to three reduces repeated login attempts against the SSH service.

**Verification:**

```bash
sudo sshd -T | grep -E 'permitrootlogin|maxauthtries'
```

The output confirmed:

```text
permitrootlogin no
maxauthtries 3
```

The SSH service was subsequently started and enabled:

```bash
sudo systemctl start ssh
sudo systemctl enable ssh
sudo systemctl is-active ssh
sudo systemctl is-enabled ssh
```

Final results:

- SSH service: `active`
- SSH startup at boot: `enabled`

During recovery from an unresponsive VM session, SSH was found inactive and was manually started again. The configuration was retained.

## 4. Before-and-After Checklist

| Security control | Before | After |
|---|---|---|
| UFW firewall | Inactive | Active |
| Incoming traffic policy | Not enforced by UFW | Deny by default |
| Outgoing traffic policy | Not enforced by UFW | Allow by default |
| IPv4 redirect acceptance | Not explicitly hardened | Disabled |
| IPv4 redirect sending | Not explicitly hardened | Disabled |
| SSH root login | `prohibit-password` | `no` |
| SSH authentication attempts | Default setting | Limited to 3 |
| SSH service | Running before VM shutdown | Active and enabled after recovery |

## 5. Answers to Think About Questions

### 58. Which services are needed?

Services required for the operating system's normal functioning, networking, user sessions, and essential system operations should remain enabled. SSH is needed for the remote-access experiment in Mission 20. Services that are not required should be investigated before being disabled.

### 59. Which ports should be exposed?

Only ports required for legitimate services should be accessible. Unnecessary listening ports increase the attack surface. SSH port 22 is required for the lab's SSH experiment, but SSH should remain within the VM/lab network and should not be exposed to the public internet.

### 60. Why is patch management a security control?

Software updates can fix known vulnerabilities, correct bugs, and improve security. Keeping software patched reduces the opportunity for attackers to exploit publicly known weaknesses. Updates should be assessed and applied carefully, especially in a controlled laboratory environment.

### 61. Why should every hardening change be documented and reversible?

Documentation makes it possible to understand what was changed and why. Reversibility allows administrators to recover if a change causes unexpected problems or interrupts an essential service. It also makes security configurations easier to audit, verify, and maintain.

## 6. Conclusion

The baseline audit identified an inactive firewall and several areas where additional network and SSH hardening could be applied.

Three hardening changes were implemented: enabling UFW, disabling IPv4 ICMP redirect acceptance and sending, and strengthening SSH login restrictions.

The firewall, network settings, and SSH configuration were verified. The network settings persisted after reboot, and SSH was restored to an active and enabled state.

This experiment demonstrated how firewall configuration, network-level controls, and secure remote-access settings work together to reduce a Linux machine's attack surface.
