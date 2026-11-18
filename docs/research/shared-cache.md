# What the shared caches added

The seven standalone binaries left questions that needed images living inside the dyld shared cache. The device's own
caches were copied and unpacked with `ipsw` 3.1.743; identities are in [the inventory](binary-inventory.md).

**Coverage • VERIFIED STATIC.** All 54 main-cache files unpacked with their original names and matched the SHA-256
manifest, including the symbols file; both DriverKit members unpacked. Ghidra 12.1.4 processed each image
independently. The per-image indexes cover 56,535 entries, and all 52,651 eligible functions produced decompiler output
after a targeted retry of IO80211's large `Apple80211GetWithIOCTL`. Those are Ghidra's recognized function boundaries,
not a ground-truth count. The extracted symbol tables retained all 55,345 address and name pairs found for these images
in the two local-symbols tables; CoreWiFi and `libDHCPServer.A` had zero qualifying local pairs, so the two CoreWiFi
band method addresses came from Objective-C method records in the original cache. The optional global
stub-reconstruction pass did not finish, so cross-image calls quoted anywhere in these docs were resolved
independently.

## Images extracted

| Cache | Images |
|---|---|
| Main, by install name | MobileWiFi, CoreWiFi, IO80211, `libmrc.dylib`, PacketFilter, `libDHCPServer.A.dylib` |
| Main, found by string search | Netrb, WiFiKit, SymptomEvaluator, WirelessModemSettings, Preferences, CoreFoundation |
| DriverKit | `IO80211DriverKit.framework/IO80211DriverKit` |

## Who owns the sharing client • VERIFIED STATIC

| Image | `com.apple.MobileInternetSharing` | `clientCommunication` | Role |
|---|---|---|---|
| Netrb | `0x1F72E7BAB` | `0x1F72E7BE6` | Creates the service connection and sends create and start requests |
| WiFiKit | `0x20669E376` | `0x2066A0DF8` | Its own full client implementation; its `WFIPMonitor` also reads hotspot state from the dynamic store at `0x206665CA4` |

Netrb is the main client implementation. The message it builds confirms the schema recovered from `misd` from the other
side:

```text
Netrb 0x1F72E2FC8   set_uint64(msg, "xpcKey", 1000)
Netrb 0x1F72E28AC   set_connection(msg, "clientCommunication", anonymous_listener)
misd  0x10000B224   create_from_endpoint(value), install handler, resume
Netrb 0x1F72E3E78   build {xpcKey=1001, clientid, opMode, bridgeType, interfaceParam}
                     add extName only for a nonempty caller-supplied name
```

Netrb accepts existing explicit interface names and the literal `anyExternal`. The stock `wifid` path uses its own
linked copy of this client rather than Netrb.

## What this settled

1. **The Wi-Fi decision happens before NAT.** Confirmed from both ends: `wifid` checks concurrency in the hosted-role
   path and again in the stock MIS coordinator, before any NAT rule exists. See [`wifid`](wifid.md).
2. **The stock start passes no external name.** `opMode` 201, `bridgeType` 302, `interfaceName="ap1"`. Upstream
   selection is left to the system.
3. **NAT and DNS take separate interface settings**, in different code, with different failure modes. See
   [`misd`](misd.md).
4. **One dependency is still missing from both caches:** `BroadcomWLANDriverKit`. It was later copied from the phone
   directly and turned out to be [a version-only stub](binary-inventory.md).
