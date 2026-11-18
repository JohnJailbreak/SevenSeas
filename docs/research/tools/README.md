# Reproducing the analysis, and the read-only probe

## [`wifid_probe.js`](wifid_probe.js)

A **read-only** Frida script. It logs the arguments and results of two `wifid` functions and never changes an
argument, a return value or any memory.

It prints, on each role check: the request, the capability byte at manager `+0x1750`, the role mask `+0x1751`, the band
preference `+0x1748`, the NAN band `+0x174C` and the MIS force flag `+0x10E1`; and on each infrastructure disconnect:
the reason code and which caller asked for it. That is enough to answer
[question 1](../open-questions.md) in one hotspot start.

**It refuses to run against the wrong build.** Before hooking, it compares the first 16 bytes of each function with the
bytes recorded during the static analysis:

| Function | Unslid VA | First 16 bytes |
|---|---|---|
| Role check | `0x1000F90DC` | `7f2303d5ff4302d1fa6704a9f85f05a9` |
| Infrastructure disconnect | `0x1000E9C08` | `7f2303d5ff0304d1fa670ba9f85f0ca9` |

It also knows the call sites the analysis named, so each disconnect line says whether it came from the role gate in
`0x1000D059C` or from the stock MIS coordinator.

### Running it

`frida-server` is already installed on the phone at `/var/jb/usr/sbin/frida-server` with LaunchDaemon
`re.frida.server.plist`. From a computer on the same network:

```bash
# 1. Match versions. frida and frida-server must be the same version.
ssh mobile@<phone-ip> '/var/jb/usr/sbin/frida-server --version'
frida --version

# 2. Tunnel Frida's port over SSH rather than exposing it on the network.
ssh -L 27042:127.0.0.1:27042 mobile@<phone-ip>

# 3. In another terminal, attach and load the probe.
frida -H 127.0.0.1:27042 -n wifid -l wifid_probe.js
```

Then start the stock Personal Hotspot on the phone while it is joined to Wi-Fi, and read the output. Record the
upstream band and channel at the same time; see [question 2](../open-questions.md).

Reading the probe's lines:

| Line | Meaning |
|---|---|
| `roleCheck request=4 ... -> REFUSED` | `wifid` says the hotspot role cannot run next to the active Wi-Fi client. `cap=0` is the cause. |
| `infraDisconnect reason=0x3ef` | The role-gate path in `0x1000D059C` dropped Wi-Fi. |
| `infraDisconnect ... stock MIS` | The stock coordinator dropped Wi-Fi: a channel rule (DFS, coexistence, width, 6 GHz). |

## How the static analysis was produced

Ghidra 12.1.4, language `AARCH64:LE:64:AppleSilicon:default`, with chained arm64e pointers fixed by Ghidra's loader.
Seven standalone binaries first, then eleven shared-cache images extracted with `ipsw` 3.1.743 using the same export
scripts. Counts are in [the cache page](../shared-cache.md); identities and digests are in
[the inventory](../binary-inventory.md).

Reproducing it needs the images, which are not in this repository: copy them from a matching device and verify the
SHA-256 digests before reusing any address.

## A note on reading decompiler output

The recovered C has imperfect types, varargs, Swift and Objective-C recovery. Check the disassembly and the call sites
before declaring an ABI or writing a hook. Automatic coverage is not the same as every function having been read. For
Objective-C calls, `x0` is self and `x1` is the selector, with explicit arguments from `x2`; do not treat decompiler
temporaries as complete declarations, and remember that selector stubs mean a missing direct cross-reference is not
evidence of no callers.
