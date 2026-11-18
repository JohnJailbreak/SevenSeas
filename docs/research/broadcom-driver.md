# The Broadcom driver and firmware

`com.apple.DriverKit-AppleBCMWLAN` SHA-256 `2c6ed387…`, UUID `D0707D1F-1F56-3EF6-BE4D-0CA064B4CCA7`. DriverKit has its
own address space; these VAs are not in the `0x100000000` user-space image space of the daemons.

## The dext's personalities • VERIFIED STATIC

The Info.plist has a `DriverKit_IO80211SoftAP` personality whose IOUserClass is
**`AppleBCMWLANIO80211APSTAInterface`**, role `SoftAP`, interface unit 1. Infrastructure uses
`AppleBCMWLANSkywalkInterface`; other personalities cover AWDL, proximity and NAN. The existence of an APSTA interface
class is configuration evidence. It does not prove which instances are live in the running IORegistry.

## Concurrency: where the capability comes from • VERIFIED STATIC

| Function | VA | What it does |
|---|---|---|
| `configureTethering` | `0x100126B00` | Derives a tethering feature bit from the configuration manager, checks `shouldSupportTethering`, writes four-byte value 1 via `runIOVarSet(..., "apsta", ...)`, then reads it back with `runIOVarGet`. Failures are logged; the return does not prove the firmware accepted the command. |
| `IssueFwCap` | `0x100121670` | Tests firmware capability word `rsdb`. On that path it sets feature bits `0x2E` and `0x46`. A present boot argument `wlan.concurrentmode=0` clears `0x46`. |
| `processFwFeatures` | `0x1001233B0` | Bitmap handling for the same thing: byte 5, bit 1 drives those feature bits, with the same boot-argument disable path. |
| `isConcurrencyEnabled` | `0x10013C170` | Reads feature bit `0x46`. |
| `isApStaSDBMode` | `0x1001BEFDC` | Reads a **different** bit, `0x3F`. Do not conflate the two. |
| SoftAP concurrency check | `0x1000DB294` | Also requires an active op-mode bit among 1, 2, 8, 16. |
| `setHOSTAP_MODE` | `0x1000CA3F8` | Real firmware virtual-interface lifecycle: `interface_create`, `interface_remove`, `bsscfg:ssid`, interface-id completion, `ssid`, `wsec`, `idauth`, `ap_isolate`, `bss`, `closednet`. An APSTA SDB capability check changes part of the creation request; if SDB, a request byte is set to 1 and flags are OR'd with 4 for `interface_create`. Also changes concurrency state through `0x1001B19E0`. |

So the chip firmware declares `rsdb`, the driver turns that into feature bit `0x46`, and `wifid` reads *a* capability
byte that gates the SoftAP role. **NEEDS DEVICE TEST:** the correspondence between the driver's `0x46`/`0x3F` and
`wifid`'s `+0x1750` byte (bit 6 of `+0x25` in its device object) is **not** established. No setter for `0x3F` was found
in the dext.

## What this does not license

The code shows the boot argument's *disable* behaviour. It does **not** show that adding `wlan.concurrentmode=1`
creates firmware capability that is absent, nor that a rootless jailbreak can change effective boot arguments. There is
no basis here for a boot-argument or regulatory-data modification, and no firmware patch is justified by anything
measured so far.

## Station and AP controls that exist at driver level • VERIFIED STATIC

| Operation | VA | Observed implementation and its limit |
|---|---|---|
| Enumerate associated stations | `0x1000C9960` | Station-list request, with async response and conversion helpers |
| Set maximum associations | `0x1000CF718` | Writes per-interface `maxassoc`; the addition plus existing count must not exceed a stored bound |
| Hidden SSID | `0x1000D1120`, `0x1000CA3F8` | Hidden/AP configuration and the `closednet` path exist; no simple public setter is established |
| SSID | `0x1000D17D0` | Setter exists; caller ownership and sequence matter |
| Channel | `0x1000D18F8` | Converts Apple channel/width flags to a chanspec and issues `chanspec`; invalid parameters fail |
| AP parameters | `0x1000D2658` | Beacon interval and power-related configuration fields |
| RSN and management-frame protection | `0x1000D2AC0`, `0x1000CF490` | Security configuration paths; negotiated operation still needs client tests |
| Disconnect a station | `0x1000D37A8` | Per-virtual-interface ioctl `0xC9`; diagnostics identify `WLC_SCB_DEAUTHENTICATE_FOR_REASON` |
| Deauth wrapper | `0x1000D3724` | An indirect virtual-dispatch wrapper, not the full implementation |
| Station statistics | `0x1000D4160` | Getter exists; units, layout and reset behaviour need validation |

These are driver-level operations. Entitlements, user-client permissions, request numbers, structure layouts and state
ordering all still sit between them and anything an app can call. `cur_etheraddr` appearing during interface creation
supports *investigating* MAC configuration; arbitrary hot changes and isolation from the infrastructure MAC are not
verified.

A deauth is a kick, not a block: the client can come back. Persistent exclusion needs an enforcement path that has not
been established.
