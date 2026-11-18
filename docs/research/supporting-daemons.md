# `hostapd`, `bootpd`, `mDNSResponder`, `wifip2pd`

Unslid VAs per image, base `0x100000000`. Digests in [the inventory](binary-inventory.md).

## `hostapd` • VERIFIED STATIC

Entry `0x100024EB4` references `/var/run/hostapd.conf`; the launch service runs `/usr/libexec/hostapd -l`. The XPC
accept path `0x1000091CC` takes an audit token and checks a true boolean `com.apple.wifi.hostapd` entitlement. Handler
`0x100009348` distinguishes a dictionary containing `Terminate` from activation; replies and lifetime are
asynchronous. **This is an Apple-specific lifecycle, not the standard Linux hostapd control protocol.**

Configuration parser `0x10001A4D4` contains MAC ACL mode checks and accept/deny file handling, and a `max_num_sta`
parser range of 0–2007. **That range is a parser limit, not the phone's station capacity.**

Key-management parser `0x10001C5B4` accepts:

| Token | Internal bit |
|---|---:|
| `WPA-EAP` | `0x1` |
| `WPA-PSK` | `0x2` |
| `WPA-EAP-SHA256` | `0x80` |
| `WPA-PSK-SHA256` | `0x100` |
| `WPA3-SAE` | `0x400` |

These are `hostapd`'s own bits and must not be substituted for the Apple80211/MIS authentication values in
[`wifid`](wifid.md). The binary's old version banner is misleading if read as an upstream feature list.

Nothing here shows that editing a generated configuration file survives a stock service restart, or that userspace ACL
handling covers firmware-offloaded admission.

## `bootpd` • VERIFIED STATIC

Startup `0x100005674` reads `dhcp_enabled`, `detect_other_dhcp_server`, `Subnets` and
`use_server_config_for_dhcp_options`. Subnet construction `0x100010CB8` validates ranges and rejects overlapping
configured ranges, which is **not** the same as comparing against every VPN or changing upstream route; a controller
needs its own runtime overlap check.

Option construction `0x100007A28` checks configured subnet options first. When an option is absent **and** the
server-configuration fallback is enabled, it may synthesize subnet mask, router, DNS servers, domain and search
options; the router fallback additionally tests subnet compatibility. It is conditional, not unconditional leakage.

**Design consequence for local-only mode:** control that fallback deliberately and verify real OFFER/ACK options on the
wire. Omitting `dhcp_router` is not by itself evidence that no router will be advertised, and a client with a stale
lease or a manual route ignores a new omission.

Lease writes `0x1000093A4` and `0x1000098BC` update `/var/db/dhcpd_leases` and post
`com.apple.bootpd.DHCPLeaseList`. Useful for a device list, but leases go stale, clients can be static, names are
client-supplied, and randomized MACs are not durable identities. The device list should merge leases with the actual
association table.

## `mDNSResponder` • VERIFIED STATIC

`_mrcs_dns_proxy_set_output_interface` `0x1000C01B8` records an output interface index and resolves its name.
`_DNSProxyStart` `0x1000EA8C4` manages proxy conflicts and creates IPv4/IPv6 UDP and TCP listeners;
`_ProxyUDPCallback` `0x1000EC3F8` enters common proxy processing. This is a real DNS proxy, not just mDNS discovery.

The older accept path `0x1000A74A4` requires euid 0 **and** `com.apple.mDNSResponder.dnsproxy`; that is not
necessarily the whole authorization contract of the newer `libmrc` control path. Conflict comparison `0x1000C02D0`
considers overlapping input interfaces, the output interface and other settings, so a second proxy may conflict with
existing services.

A static output-interface assignment is not a demonstration that no query can leave over cellular. UDP and TCP, cached
results, interface disappearance, VPN changes and IPv6 all need testing.

## `wifip2pd` • VERIFIED STATIC

A large Swift-heavy CoreP2P component: `updateSoftAPBand` `0x10004854C`, an ObjC forwarding call `0x10005F190`, the
`AWDLSoftAPChannelChangedEvent` constructor `0x100136AD4`, and a callback `0x1003C7FD0` sending
`softAPChannelChangedEvent:channelNumber:`. A coexistence and event role. No Wi-Fi-upstream NAT orchestration path was
established here; its large function count mostly reflects Swift-generated helpers, so it is not the first place to
look.

## Configuration and launch • VERIFIED STATIC

| File or service | Observation | Reading |
|---|---|---|
| `InternetSharing.plist` | Only `vmnetLimitedAccess` and `DevelopmentPhase=FeatureComplete` | No Wi-Fi repeater switch exists in this file |
| `NetworkInterfaces.plist` | `en0` Wi-Fi; `en1`/`en2` Ethernet adapters; `en3`/`en4` Bluetooth; model `D17AP` | Persistent configuration, not a snapshot of what is up or associated |
| `preferences.plist` | Network services, Wi-Fi entries, cellular services, VPN configurations | Check current routing and VPN conflicts; stored entries are not active connections |
| DHCP leases | Three records | Historical client hints, not three associated stations |
| `com.apple.wifi.hostapd` | `/usr/libexec/hostapd -l`, Mach service, on-demand | Ownership must be coordinated with `wifid` |
| `bootps` | `bootpd`, disabled by default, IPv4 `bootps` socket | Launch defaults do not show whether something enabled DHCP at capture time |
| `wifid` | `RunAtLoad`/`KeepAlive`, several Wi-Fi services | A daemon restart reapplies stock policy |
| `mDNSResponder.reloaded` | `_mdnsresponder` user and group, control and dnsproxy services, Unix socket | Native DNS lifecycle differs from a standalone DNS server |
