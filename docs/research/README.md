# SevenSeas research

Why a jailbroken iPhone 13 cannot simply share the Wi-Fi it is joined to, and what would have to be true for it to.

**Target.** iPhone 13 (iPhone14,5), iOS 17.0 build 21A329, arm64e, Broadcom BCM4387 (`lilac`), rootless jailbreak
(Dopamine, prefix `/var/jb`). Every address in these pages is an **unslid virtual address** and is only meaningful with
the image it names; the preferred image base is `0x100000000`, and DriverKit has its own address space. A runtime
address is the unslid address plus that image's ASLR slide. **Do not apply any address here to another build.**

- [The device and its environment](device.md)
- [Binary inventory and provenance](binary-inventory.md)
- [`wifid`: the concurrency policy that drops Wi-Fi](wifid.md)
- [`misd`: the sharing service, NAT, routes and DNS](misd.md)
- [The Broadcom driver and firmware](broadcom-driver.md)
- [`hostapd`, `bootpd`, `mDNSResponder`, `wifip2pd`](supporting-daemons.md)
- [What the shared caches added](shared-cache.md)
- [What the phone actually did](device-observations.md)
- [Features mapped to evidence](feature-map.md)
- [Open questions and the next experiments](open-questions.md)
- [Reproducing this, and the read-only probe](tools/README.md)

## The finding, in one paragraph

Starting the stock Personal Hotspot while the phone is joined to Wi-Fi tears the Wi-Fi connection down **before any
NAT or routing is configured**. `wifid` decides this: a concurrency predicate reads a capability byte, and when the
requested SoftAP role is refused it calls an infrastructure-disconnect helper with reason `0x3EF`. A second,
independent path inside the stock sharing coordinator can disconnect for channel reasons (6 GHz, width above 80 MHz,
a DFS or coexistence-denied channel). Repointing a NAT rule at `en0` therefore cannot work: by the time NAT exists,
the upstream association is already gone. Which of the two paths fired on this phone is **not yet established**, and
that single question decides whether SevenSeas is feasible at all.

## Evidence labels

Each claim carries one of these, as in the reports this is drawn from:

| Label | Meaning |
|---|---|
| **VERIFIED STATIC** | Bytes, instructions or metadata in a supplied image were inspected. Not a runtime claim. |
| **VERIFIED RUNTIME** | Observed on the phone. Where it says one run, it was observed once. |
| **INFERRED** | A supported reading of the evidence, not a measurement. |
| **NEEDS DEVICE TEST** | Open. Nothing here settles it. |

Decompiled C is explanatory. It is not Apple source, and it is not a certified ABI; argument roles recovered from a
decompiler must be checked against the disassembly and call sites before anything is built on them.

## What is not here

No Apple executables, no shared-cache files, no firmware, and no recovered Apple code. The analysis was performed on
copies taken from the owner's own device and kept outside this repository. Device snapshots are summarized rather than
committed: the raw captures contain local addresses and the MAC addresses of the owner's own hardware.
