# Binary inventory and provenance

**VERIFIED STATIC.** Seven images were copied from the phone and analysed in Ghidra 12.1.4. Their SHA-256 digests were
re-checked against the live phone during a later session and matched.

| Binary | Bytes | SHA-256 | LC_UUID |
|---|---:|---|---|
| `com.apple.DriverKit-AppleBCMWLAN` | 4,633,520 | `2c6ed3876f938962f748c72c490865bbc9cc71d8924c26c91c88aa7dbf4d66b9` | `D0707D1F-1F56-3EF6-BE4D-0CA064B4CCA7` |
| `wifid` | 2,642,368 | `df6ea02144ae2046df77b989a96b5e8d572e9278d5b3655ce1ad5416975eb8d8` | `D24A1E31-CE8B-3A23-B127-E7361FAA5FD7` |
| `wifip2pd` | 5,441,088 | `63bc58cd67c6755a870ad3f7d3130d4c89d74faa2048b4d70ebd9962b1ed9908` | `56C8D8A1-C8B4-347B-A2EA-52EA9B71789D` |
| `misd` | 258,624 | `4a25c9b9fd1d7bfe647711fc007beb3e735eee78b596763b412a862debe14932` | `C3DD0E90-C963-38EA-9A55-33B8B6D2ED5D` |
| `hostapd` | 313,488 | `0c42002675ddcbc50f34adf271bedd436a4531e748e47bea8166b82cae6d0bef` | `A2678A85-02F8-3AFA-93BF-006AA50A13DB` |
| `bootpd` | 161,840 | `e381a9c4812b202c4cc7096229e7daf4b9753f297078e7afe31d8da27ab9940c` | `E9527088-3403-3810-AACE-A419D83BF0CA` |
| `mDNSResponder` | 1,643,376 | `fe3e3411dd1773329d12a0f34fe115a055e3e4740c16252beadb9965fb038c56` | `85D3EC1E-0114-30A1-8BF6-2A9EB964C427` |

All seven are arm64e Mach-O (`cputype=0x0100000c`, `cpusubtype=0x80000002`). `wifid`, `wifip2pd`, `misd`, `hostapd` and
`bootpd` declare iOS minimum and SDK 17.0; `mDNSResponder` declares minimum 16.0, SDK 17.0. The dext declares DriverKit
platform 10, version 23.0 (**not** iOS 23), identifies `driverkit.iphoneos23.0.internal` and build `21A322`.

Firmware `lilac.trx` is 1,808,563 bytes, SHA-256
`bc9d5735aaa578d340531c49e096160c648c94218484aa7a50167cb5252a852f`, with its printable firmware tag at file offset
`0x1B9735`.

## Shared caches

The device's own shared caches were copied and unpacked with `ipsw` 3.1.743; all 54 main-cache files matched their
SHA-256 manifest.

| Cache | Bytes (primary file) | Cache UUID | SHA-256 |
|---|---:|---|---|
| Main `dyld_shared_cache_arm64e` | 475,136 | `671A0725-36B8-3099-8297-8D225B415A76` | `b8eea1ab590021816f71632ae1d999672c099c5eb5e5c2b05c98355e7f61b0aa` |
| DriverKit `dyld_shared_cache_arm64e` | 9,879,552 | `D0A197A9-E554-3E2E-A6BF-9A67BBA7103F` | `f81f89059fb1e4638e1696b08b5231ab3355d1b9e5974e167573461383116af4` |

## BroadcomWLANDriverKit: a dead end, measured

The BCM dext imports `@rpath/BroadcomWLANDriverKit.framework/BroadcomWLANDriverKit`, which appears in neither cache
catalog (3,326 main entries, 32 DriverKit entries). It was copied from the phone separately.

| Fact | Value |
|---|---|
| Device path | `/System/DriverKit/System/Library/PrivateFrameworks/BroadcomWLANDriverKit.framework/BroadcomWLANDriverKit` |
| Size | 34,992 bytes (`0x88B0`) |
| SHA-256 | `9cae3906d27cd472bb6756c70345da51dfe1fae611684a856448972da0e31016` |
| LC_UUID | `A60E1AAF-0B68-3E1E-A7E7-7F4FA77FE5A7` |
| Contents | `__TEXT,__text` has **size zero**. Two data symbols only: `_BroadcomWLANDriverKitVersionString` (VA `0x3FB8`) and `_BroadcomWLANDriverKitVersionNumber` (VA `0x3FF8`). `LC_FUNCTION_STARTS` is eight zero bytes; the symbol table has zero external definitions and zero undefined entries. |

**VERIFIED STATIC:** it is a version-only stub with no executable instructions. **INFERRED:** its import by the dext
gives no evidence about feature-bit setters, the capability producer or channel arbitration. Those questions stay with
`wifid`, the dext and `IO80211DriverKit`.

## What provenance this does and does not establish

**VERIFIED STATIC:** every binary's primary CodeDirectory carries flags `0x2`, the ad hoc signing flag, and each CMS
wrapper has zero payload bytes. Every code-page hash matches its embedded CodeDirectory, and the inputs' hashes were
unchanged after analysis. `CodeResources` has empty `files` and `files2`.

This establishes that the supplied copies are internally consistent. It does **not** authenticate them as byte-for-byte
Apple IPSW files, identify who exported or re-signed them, or establish trust-cache membership on the phone. The
archive contained no `SystemVersion.plist`, so the OS build above is the owner's description corroborated by SDK
versions, not independently verified provenance.
