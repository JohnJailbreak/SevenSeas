# Features mapped to evidence

Scope is Wi-Fi upstream to Wi-Fi downstream, with a hard cellular lockout, local-only and full-sharing modes, and a
privileged background lifecycle. USB sharing, Bluetooth sharing, carrier bypass and automatic low-battery shutdown were
removed from scope.

The left column is what the app's screens promise. The right column is what is actually left to do. Nothing in this
table is implemented.

| Feature | What the files support | Status and work remaining |
|---|---|---|
| Wi-Fi to Wi-Fi sharing | APSTA setup, concurrency policy, named MIS upstream | Strong static leads; simultaneous association and real traffic untested |
| Hard cellular lockout | PF interface and family rules, explicit DNS output selection | Must implement and prove fail-closed egress; no end-to-end guarantee from these files |
| Pause on upstream loss | Runtime interface and status mechanisms, disconnect events | Controller state machine, races and stale-state cleanup still required |
| DHCP | Complete `bootpd` path, ranges, leases, option construction | Verify MIS ownership and reload, and downstream-only binding |
| DNS | Native proxy controls and implementation | Verify real egress and conflict handling |
| Local-only mode | DHCP option control and PF mechanisms | Must prevent forwarding, default-route and RA leakage independently |
| Automatic subnet choice | MIS conflict code plus `bootpd` range validation | Runtime checks must include upstream, VPN and every active local route |
| SSID and password | Driver SSID and security paths, `hostapd`/MIS configuration | Recover the preferred caller contract and restart semantics |
| WPA2 / WPA3 | Parser and security choices observed | Validate SAE, PMF and mixed-mode clients on hardware |
| Preferred band | `wifid` preference and restart path, driver channel control | Capability and channel restrictions remain authoritative |
| Maximum clients | Driver `maxassoc`, `hostapd` parser | Effective limit must be measured; the parser's 0–2007 range is not capacity |
| Hidden SSID | Driver hidden mode and `closednet` | End-to-end behaviour and UI semantics need testing |
| Device list | Association list, statistics, lease notifications | Merge sources; stale leases and private MACs need explicit handling |
| Kick a device | Per-interface deauth ioctl | Verify own-interface targeting and reconnection behaviour |
| Block list | `hostapd` ACL parsing | Establish an active enforcement path; a kick is not a block |
| MAC randomization | `cur_etheraddr` during interface creation | Safe scope, allowed addresses and restart behaviour not established |
| Auto-disable timer, notifications | System events and idle paths | App and controller work, not recovered code |
| Background daemon and watchdog | Launch and transaction-aware stock services | A separate rootless service with bounded recovery and owned cleanup |
| Resume after rejailbreak | Nothing | Reconcile saved intent with current capabilities; stay off until privileges exist |
| iOS 15–26 compatibility | One iOS 17-era dataset | Separate binary and device profiles, and tests, for each family |

## Where the screens currently stand

Every screen in this repository is driven by `AppModel`. The start sequence's log lines name the real steps this
research implies (capability check, channel choice, AP start, DHCP, routes, DNS pinning, cellular lockout, egress
verification), but they are a scripted sequence on a timer. The Devices list, signal ring and data counter are sample
values. Nothing calls the radio, `misd`, PF, `bootpd` or `mDNSResponder`.
