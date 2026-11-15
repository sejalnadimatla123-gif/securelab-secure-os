
# Mission 20: Secure Remote Access

## 1. Objective
Understand the security boundary created when a user connects remotely using SSH.

## 2. Concepts
- Secure Shell (SSH)
- Authentication
- Authorization
- Password-based authentication
- SSH service and port 22
- Login logging

## 3. Experiment 1: Install SSH Server

Command:
```bash
sudo apt install -y openssh-server
```

Observation:
OpenSSH Server was successfully installed in the Ubuntu VM.

## 4. Experiment 2: Check SSH Service

Command:
```bash
sudo systemctl status ssh --no-pager
```

Observation:
The SSH service was initially inactive. After starting it, its status showed active (running).

## 5. Experiment 3: Verify Listening Port

Command:
```bash
ss -lnt | grep ':22' || true
```

Observation:
The SSH server was listening on port 22 for IPv4 and IPv6 connections.

## 6. Experiment 4: Local SSH Connection

Command:
```bash
ssh localhost
```

Observation:
A successful SSH connection was established to the local Ubuntu machine. Password authentication succeeded and an interactive shell was opened.

## 7. Authentication vs Authorization

Authentication:
Verifies the identity of the user connecting to the system.

Authorization:
Determines what resources and actions the authenticated user is permitted to access.

SSH authentication does not automatically grant administrative privileges. The user's permissions determine what they can do after logging in.

## 8. Login Evidence

SSH service logs can be inspected using:

```bash
sudo journalctl -u ssh --no-pager
```

These logs can help administrators investigate SSH connections and authentication activity.

## 9. Security Considerations

- Use strong authentication methods.
- Prefer SSH keys over passwords where appropriate.
- Restrict access to authorized users.
- Monitor SSH login activity.
- Avoid exposing SSH to the public internet without appropriate security controls.

## 10. Conclusion

The experiment demonstrated successful local SSH authentication and an interactive shell connection. It also illustrated the distinction between authentication and authorization in secure remote access.
