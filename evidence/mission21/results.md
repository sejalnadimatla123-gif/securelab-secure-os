# Mission 21: Who Protects the VM?

## Objective
Map the trust boundaries from application, through the guest OS, down to the physical hardware — for the laptop/desktop running VirtualBox and the Ubuntu guest inside it.

This mission is conceptual (diagram + reflection); no commands or VM access are required.

## Question
When I run a program inside the SECURELAB Ubuntu VM, how many layers actually stand between that program and the physical CPU/RAM/disk, and who is trusted at each layer?

## Prediction
There should be at least two full OS stacks (guest and host), separated by a hypervisor that mediates all access to "hardware" the guest sees — meaning a bug or compromise in the hypervisor or host OS undermines every security control built inside the guest, no matter how carefully configured.

## Diagram

```
┌──────────────────────────────────────────────────────────────┐
│ Host hardware (CPU w/ VT-x·AMD-V, RAM, disk, NIC)             │
└──────────────────────────────────────────────────────────────┘
                 ▲ real privileged instructions / DMA
┌──────────────────────────────────────────────────────────────┐
│ Host OS (macOS / Windows / Linux) + VirtualBox hypervisor     │
│  - schedules the VM like a process                            │
│  - presents VIRTUAL hardware to the guest (virtual disk,      │
│    virtual NIC, virtual CPU via VT-x/AMD-V traps)              │
└──────────────────────────────────────────────────────────────┘
                 ▲ virtual hardware interface (traps/VM exits)
┌──────────────────────────────────────────────────────────────┐
│ Guest kernel (Ubuntu Linux)                                    │
│  - believes it is talking to real hardware                     │
│  - everything from Missions 1–20 (DAC, capabilities,          │
│    AppArmor, cgroups…) is enforced HERE                        │
└──────────────────────────────────────────────────────────────┘
                 ▲ system calls (Mission 2)
┌──────────────────────────────────────────────────────────────┐
│ Guest user space                                                │
│  - alice, bob, our C programs, Docker containers (Mission 16) │
└──────────────────────────────────────────────────────────────┘
```

## Think About It

**65. Which components are inside the guest OS trust boundary?**
Everything from the guest kernel down into guest user space: the Ubuntu kernel itself, `systemd`/services, `alice`/`bob`, our compiled programs, and any containers running inside the guest. All of Missions 1–20's protections (DAC, ACLs, capabilities, AppArmor, process isolation) are enforced entirely *within* this boundary and know nothing about the host.

**66. Which component controls the virtual hardware presented to the guest?**
The **hypervisor** (VirtualBox, running as a privileged process/driver on the host OS). It decides what CPU features, how much RAM, which virtual disk image and which virtual NIC the guest sees, and it intercepts (traps) any guest instruction that would otherwise need real hardware access, emulating or forwarding it.

**67. Why does virtualization create another layer of security dependencies?**
Every guest-side guarantee is conditional on the hypervisor and host OS being correct and uncompromised — a hypervisor escape or a bug in the host's virtualization driver lets an attacker who only controls the guest step *outside* the guest's trust boundary entirely, bypassing every in-guest control simultaneously. The guest's security model can only ever be as strong as the layer enforcing it from below, which is exactly the Trusted Computing Base idea from Mission 2, repeated one level down.

## Evidence to submit
- [x] Application → guest kernel → virtual hardware → hypervisor → host architecture diagram (above).
- [x] One paragraph on the VM's additional attack surface:

Virtualization adds an entire extra interface that doesn't exist on bare metal: the boundary between guest and hypervisor. Anything the guest can influence that the hypervisor must interpret — virtual-device emulation code, shared-clipboard/drag-and-drop ("guest additions") features, virtual disk/NIC drivers — is new attack surface that a bare-metal Linux install would not have. A vulnerability in VirtualBox's emulated hardware (for example, in its virtual USB, audio, or networking device code) could let a malicious or compromised guest process break out and execute code on the host, defeating the entire point of using a VM as an isolated lab.

## Concept
Trusted Computing Base, extended: the guest's TCB is not just its own kernel, but *also* the hypervisor and host OS underneath it, because nothing the guest kernel enforces can survive a compromise one layer down.

## Defense
Keep VirtualBox and the host OS patched, disable unneeded virtual devices/shared folders/clipboard features that aren't needed for the lab, and use NAT (not bridged) networking so the guest's own attack surface toward the outside world stays minimal (as the handout's recommended standard already does).

## Verification
Not applicable as an executable check — this mission's "evidence" is the diagram and the trust-boundary reasoning above, which is what the handout asks for.

## Reflection
If the hypervisor itself were compromised, every snapshot ("SECURELAB-CLEAN"), every hardening change from Mission 19, and every access-control mechanism demonstrated across the whole project would be irrelevant, because the attacker would already be operating from a trust level that sits below and outside all of them.
