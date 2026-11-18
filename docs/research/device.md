# The device and its environment

**VERIFIED RUNTIME** (owner-supplied, read from the phone).

| Fact | Value |
|---|---|
| Model | iPhone 13, `iPhone14,5`, configuration model `D17AP` |
| OS | iOS 17.0, build 21A329, arm64e |
| Wi-Fi chip | Broadcom BCM4387, firmware tag `lilac` |
| Jailbreak | Dopamine, rootless, prefix `/var/jb` |
| Wi-Fi interface | `en0`, labeled Wi-Fi in `NetworkInterfaces.plist` |
| Hotspot interface | `ap1`, created on demand |
| Cellular interfaces | `pdp_ip0`, `pdp_ip1` |

Apple publishes 2.4 and 5 GHz support and an 80 MHz maximum channel width for this model
([Apple Wi-Fi specifications](https://support.apple.com/en-mk/guide/deployment/dep268652e6c/1/web/1.0)). That ceiling
matters: one of the two disconnect paths triggers above 80 MHz.

## Tools available on the phone

What is present decides which experiments are possible without installing anything further.

| Present | Path |
|---|---|
| `ifconfig`, `netstat`, `arp`, `ndp`, `route`, `sysctl` | `/var/jb/usr/sbin` |
| `sha256sum`, `sw_vers`, `uname`, `plutil`, `launchctl`, `curl`, `killall`, `ldid` | `/var/jb/usr/bin` |
| `ioreg`, `nvram` | `/usr/sbin` |
| `ps` | `/bin` |
| `frida-server` | `/var/jb/usr/sbin`, LaunchDaemon `re.frida.server.plist` |

| Absent | Consequence |
|---|---|
| `pfctl` | PF rules and states cannot be listed from the shell. Any NAT or kill-switch claim stays unverified. |
| `tcpdump` | No packet capture on the phone. Egress claims, which are the whole point of a cellular lockout, cannot be proven locally. |
| `scutil` | The dynamic store cannot be inspected directly. |
| `log` | No unified-log streaming, so `wifid`'s own diagnostic lines cannot be read that way. |

`frida-server` being present is what makes the [read-only probe](tools/README.md) possible, and is currently the only
route to `wifid`'s internal state. Missing `tcpdump` and `pfctl` is the reason the third milestone (proving Wi-Fi-only
egress) cannot be validated on-device as things stand.

## Other jailbreak software installed

Choicy, PreferenceLoader and other tweaks, plus the owner's own daemons (`com.parv.speaka.audio`,
`com.parv.caz.logtrim`, and `ch.xxtou.*`). Relevant only because a tweak that injects into `wifid` or competes for the
hotspot would confound any measurement. **NEEDS DEVICE TEST:** no check has been made for other injections into
`wifid`.
