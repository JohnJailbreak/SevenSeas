# `wifid`: the concurrency policy that drops Wi-Fi

`wifid` SHA-256 `df6ea021…`, UUID `D24A1E31-CE8B-3A23-B127-E7361FAA5FD7`. Unslid VAs, base `0x100000000`.

This is the page that matters most. The Wi-Fi connection is not lost as a side effect of NAT or bridging; `wifid`
decides to drop it, and it decides before the sharing service configures anything.

## Two independent start paths • VERIFIED STATIC

| Path | VA | What it does |
|---|---|---|
| Hosted network start | `0x1000D059C` | Validates the requesting client and the network role. For roles 2/3, if an infrastructure network exists, calls the concurrency predicate `0x1000F90DC(manager, 4)`. When the check fails it logs `Enabling SoftAP. Now disconnecting from %@` and calls `0x1000E9C08` with reason `0x3EF`. |
| Stock MIS startup and channel selection | `0x10012D548` | Performs an analogous concurrency check, and also tests a separate force-disconnect field at manager offset `0x10E1`. Contains channel and band selection, coexistence and regulatory checks, authentication setup and MIS session handling. |

Blocking one call in the first path leaves the second unresolved. That is the single most important structural fact
here.

```text
wifid 0x1000D0804   check(manager, role=4)
      0x1000D085C   disconnect(manager, interface, 0x3EF) on rejected concurrency
      0x10012DFF0   stock MIS disconnect call; another branch calls at 0x10012EEF0
```

## The concurrency predicate • VERIFIED STATIC

`0x1000F90DC` reads a capability byte at manager `+0x1750` and role state at `+0x1751`. It is a role-compatibility
switch, not an always-disconnect rule: in the supported-concurrency branch, state 1 permits requests 2 or 4, and state
4 permits requests 1 or 2. Call sites establish 4 as the SoftAP request in the investigated paths. Role naming for
other combinations should be checked against the logging and driver mappings before anything relies on it.

Manager initialization `0x1000E88B0` fills `+0x1750` from `0x1000537E4`, whose body returns **bit 6 of byte `+0x25`**
in its device object. That is a concrete chain for *observing* the capability. **NEEDS DEVICE TEST:** how that device
byte corresponds to the driver's feature bits (`0x46`, `0x3F`; see [the driver](broadcom-driver.md)) is not
established.

Manager fields the reports name, all read-only in the probe:

| Offset | Meaning |
|---|---|
| `+0x1748` | SoftAP user preferred band |
| `+0x174C` | NAN concurrency band field, reached by CoreWiFi `-[CWFInterface updateSoftAPBand:]` at `0x1B4018674` |
| `+0x1750` | Concurrency capability byte |
| `+0x1751` | Role state |
| `+0x10E1` | The MIS path's separate force-disconnect flag |

## Why the stock hotspot can also drop Wi-Fi for channel reasons • VERIFIED STATIC

The MIS function can force an infrastructure disconnect for conditions named in its own diagnostics: a 6 GHz (6E)
connection, associated bandwidth above 80 MHz, a DFS or coexistence-denied channel, or an unsupported requested
concurrency. It also contains country-dependent channel decisions. The channel selector can reuse a suitable same-band
upstream channel or consider a channel on the other band, and the two band settings differ.

Other relevant paths: AWDL/NAN coexistence handling, idle shutdown `0x1000E49A8`, autojoin `0x1000FE220`, SoftAP
restart `0x1000F58DC`, and `WiFiDeviceManagerSetSoftAPUserPreferredBand` at `0x1000F5A4C`, which stores a boolean
preference and may restart SoftAP. None of that exposes an arbitrary channel selector.

## How the stock hotspot actually starts • VERIFIED STATIC

```text
wifid 0x100180450   mov x1, #0       // external name: none
      0x100180454   mov w2, #201     // operation mode
      0x100180458   mov w3, #302     // bridge type
      0x100180460   bl  0x10017B750  // local NETRBClientStartService
```

The DHCP callback obtains the literal `ap1` from `0x100052F28` (`MISStartServiceDHCP` at `0x10018039C`, interface name
at `0x10012F73C`). So the stock path leaves upstream selection to the system entirely: it passes no external interface
name. For that request, `interfaceParam` carries `interfaceName="ap1"`, `deviceType=3` and a default `natType=500`.

The queued AP start reaches `wifid 0x100047B48`, which calls `Apple80211Set(handle, 0x19, 1, config, 8)`; IO80211
dispatches to `_startAPMode` at `0x1F39624C0`. MobileWiFi's `WiFiDeviceClientStartNetwork` at `0x1BC43DA0C` sends Mach
request `0x11073`.

Authentication values seen in this startup path: WPA2-only uses `0x8`; mixed WPA2/WPA3 uses `0x1008`, subject to a
capability check and the preferred-band setting. A 64-character key falls back to WPA2-only. These are
Apple80211/MIS-layer values and must not be confused with `hostapd`'s own key-management bits.

## What this does not establish

**NEEDS DEVICE TEST.** Nothing here shows the live capability value on this phone, which of the two paths fired during
the owner's hotspot test, or that simultaneous association is achievable at all. A global hook returning true from
`0x1000F90DC`, or a global no-op on the disconnect helper, would change behaviour for every other Wi-Fi feature and is
not justified by this analysis. The conservative first step is to observe the existing checks while using a
device-supported channel combination.
