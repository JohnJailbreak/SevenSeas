# What the phone actually did

**VERIFIED RUNTIME, one run.** The owner started the stock Personal Hotspot while the phone was joined to Wi-Fi, and
captured `ifconfig` and `netstat` before and after. Everything below is from those two snapshots. The raw captures are
not committed: they contain the MAC addresses of the owner's own hardware.

| | Hotspot off | Hotspot on |
|---|---|---|
| `en0` (Wi-Fi) | `status: active`, `inet 10.5.20.172 netmask 0xffff8000` | `status: inactive`, **no address** |
| `ap1` | `status: inactive`, no address | `status: active`, `UP,RUNNING,PROMISC,ALLMULTI`, no address of its own |
| `bridge100` | absent | `status: active`, `inet 172.20.10.1 netmask 0xfffffff0`, **member: `ap1`**, description `com.apple.MobileInternetSharing` |
| `nan0` | absent | present, `status: inactive` |
| Default IPv4 route | `10.5.0.1` via `en0` | **`192.0.0.1` via `pdp_ip0`** (cellular), plus a `bridge100` link route |
| IPv6 | — | global addresses from the carrier's `/64` |
| `awdl0`, `llw0` | unchanged | unchanged |

## What this shows

**VERIFIED RUNTIME:** the Wi-Fi interface lost its address and its routes, the hotspot came up on `ap1` inside
`bridge100` with Apple's usual `172.20.10.1/28`, and the phone's default route moved to cellular. The hotspot worked;
it just shared cellular, which is exactly what SevenSeas needs to change.

**INFERRED:** this matches an intentional disconnect by `wifid`, not a side effect of bridging. Repointing a NAT rule
cannot preserve an association that has already been torn down. That reading is consistent with the static analysis,
and it is the reason the project's first question is the role gate rather than NAT.

## What this does not show • NEEDS DEVICE TEST

- **Which path fired.** The role gate (`reason 0x3EF`) and the MIS channel rules produce the same visible result. The
  snapshots cannot distinguish them.
- **The upstream band and channel at the time.** Not recorded. A 5 GHz upstream above 80 MHz, or on a DFS or
  coexistence-denied channel, would make the channel path sufficient on its own.
- **The live capability value.** Whether `wifid`'s `+0x1750` byte is zero on this phone is unknown, and that is the
  difference between "unsupported" and "refused for this channel".
- **Anything about leaks.** With no `tcpdump` or `pfctl` on the phone, no egress claim can be made either way.

One run is one run. See [the next experiments](open-questions.md).
