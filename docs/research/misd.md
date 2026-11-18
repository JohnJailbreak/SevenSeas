# `misd`: the sharing service, NAT, routes and DNS

`misd` SHA-256 `4a25c9b9…`, UUID `C3DD0E90-C963-38EA-9A55-33B8B6D2ED5D`. Unslid VAs, base `0x100000000`.

`misd` is the daemon behind Personal Hotspot: it owns NAT, routes, the DHCP server configuration and the DNS proxy.
It is reached over the Mach service `com.apple.MobileInternetSharing`.

## Three earlier offsets were wrong • VERIFIED STATIC

An earlier plan cited offsets that are **string addresses, not code**:

| Previously cited | What is actually there | The real location |
|---|---|---|
| `0x2944F` | String VA `0x10002944F`: `mis_pf_configure_nat_outbound` | `0x10001A7AC` builds the outbound NAT rule |
| `0x26AF1` | String VA `0x100026AF1`: `mis_pdp_setup_external_interface` | `0x10001093C` performs the PDP external setup |
| `0x275AA` | String VA `0x1000275AA`: `mis_bcast_setup_routes` | Used by assertion helper `0x100020230`; the route work is inside its caller, the larger IPv4 setup `0x1000118C0` |

The third is a trap worth remembering: a cross-reference from `__assert_rtn` names a diagnostic, not a function
boundary.

## The client protocol • VERIFIED STATIC

Dispatcher `0x100003A58` reads a uint64 `xpcKey`. Registration checks the boolean entitlement
`com.apple.MobileInternetSharing.allow`; a state-exception entitlement is handled separately.

| `xpcKey` | Request name from this binary's table | Handler |
|---:|---|---|
| 1000 | create client | `0x1000052D8` |
| 1001 | start service | `0x10000549C` |
| 1002 | stop service | `0x100005E24` |
| 1003 | get state | `0x100005F1C` |
| 1004 | set state | `0x100006028` |
| 1005 | get forwarded ports | `0x100006260` |
| 1006 | set forwarded ports | `0x100006378` |
| 1007 | allowed more host | `0x1000064F0` |
| 1008 | add host | `0x1000065B4` |
| 1009 | remove host | `0x10000670C` |
| 1010 | get host count | `0x100006864` |
| 1011 | set host count | `0x100006974` |
| 1012 | destroy client | `0x100005410` |
| 1013 | get ext name | `0x100006130` |
| 1018 | not named by the 1000–1013 table | `0x100006AB8` |
| 1019 | not named by that table | `0x100006DD4` |

1014–1017 take an unsupported path. Registration `0x1000052D8` creates a client; connection setup `0x10000B224`
expects **`clientCommunication` to be an XPC endpoint**, creates a connection from it, installs an event handler and
resumes it. Success replies carry `response=2001` and a `clientid`; failure uses 2000.

**A plain JSON dictionary cannot reproduce this.** Registration needs the entitlement, a real XPC callback endpoint and
a connection-bound `clientid`.

### Start-service schema (recovered, never invoked)

| Field | Location and type | Observed constraint |
|---|---|---|
| `xpcKey` | outer uint64 | 1001 |
| `clientid` | outer string | must resolve to this registered connection |
| `opMode` | outer uint64 | 200–204, mapped internally |
| `bridgeType` | outer uint64 | 300–304 |
| `extName` | optional outer string | explicit names validated with `if_nametoindex`; `anyExternal` has separate semantics |
| `interfaceParam` | outer dictionary | required |
| `deviceType` | inside, uint64 | required; 1 denotes a special authentication device path |
| `interfaceName` | inside, string | required for device types other than 1 |
| `interfaceMTU`, `interfaceInstance` | inside, optional uint64 | type checked |
| `natType` | inside, optional uint64 | effective 500–502; zero defaults to 500 only for `opMode` 201 |
| `startAddress`, `endAddress`, `networkMask` | inside, optional strings | checked by `0x100005C7C` |
| `nat64Param`, `nat66Param` | inside, optional dictionaries | NAT64 requires `dns64Prefix` and `raPrefix` |

Mapping tables read from Ghidra's relocated memory: `opMode` 200→201, 201→201, 202→202, 203→203, 204→204, with
ordinary internal device class 102 for 200/201 and 103 for 202–204 (the special authentication device uses 101).
`bridgeType` 300–304 maps to 302, 301, 302, 303, 304; input 301 is described as no bridge. External-interface
selection is allowed for internal modes 201 and 204. Input modes 200/201 reject NAT type 501, described as no NAT.

### The promising part • INFERRED

At `0x100007B48`, a nonempty explicit upstream name follows a different selection path from an unspecified upstream:
the explicit path chooses internal device class 102, while the default path can choose class 100, which is associated
with PDP handling. `0x1000072E8` passes the selected external name into the downstream and bridge service objects, and
`0x1000072E8`'s validator is at that same path's entry.

So a service request naming a validated Wi-Fi external interface may use the existing broadcast-interface path and
avoid the cellular-specific setup entirely. **This is a reading, not a test.** An accepted interface name does not
prove working sharing, and `anyExternal` should be avoided for a Wi-Fi-only product.

In the PDP path, `misd` obtains the tethering interface name through its telephony client:
`0x10001093C → 0x10001CB80 → 0x10001C610`.

## Outbound NAT • VERIFIED STATIC

`0x10001A7AC(ext, family, source, prefix, PFUser, transactionID)`, argument roles checked in assembly including the
Darwin variadic stores Ghidra omits from some `snprintf` displays:

| Register | Role |
|---|---|
| `x0` | external interface name; used for `kPFInterface` and the formatted `%s:0` dynamic interface |
| `w1` | address family; callers use 2 (IPv4) and 30 (IPv6) |
| `x2` | source network or address text |
| low 32 of `x3` | prefix length for `%s/%d` |
| `x4`, `x5` | opaque PF context and rule arguments passed to `PFUserAddRule` |
| return `w0` | 0 on success; observed failures 12 and 22 |

The rule dictionary carries `kPFAction=4`, `kPFInterface`, `kPFFamily`, `kPFExtFilter=3`, `kPFExtMap=3`, source under
`kPFFrom` and the translated dynamic address under `kPFNATRDRAddress`, with ports `0x8000..0xBFFF`. Wrapper
`0x10001B644` calls `PFUserAddRule`; PacketFilter `0x203614BD4` validates the rule and appends it to the transaction.
IPv4 callers at `0x100017834` and `0x100017888`; IPv6 at `0x100018264` and `0x10001828C`.

This is an argument-role reconstruction, not a validated PacketFilter header. And NAT by itself does not select a
route, keep Wi-Fi alive, bind DNS or create a kill switch.

## Routes and DNS • VERIFIED STATIC

Broadcast IPv4 setup `0x1000118C0` inspects existing interface subnets, configures an address and builds routes
through a `PF_ROUTE` socket, with retry and conflict handling; route helper `0x100012324` participates in subnet and
scoped-default construction. Not every default-route addition in that function is a replacement of the phone's global
default route.

DNS setup `0x10001E64C` creates `mrc_dns_proxy_parameters`, adds input interface indices from an array of names,
selects an output interface from the external name and activates the proxy; `anyExternal` yields output index zero,
explicit names go through `if_nametoindex` and reject zero. `0x10001E8C4` invalidates the proxy. libmrc `0x21989CAAC`
sends `dns_proxy.start` to `com.apple.mDNSResponder.control`. The DNS64 path contains a macOS-only assertion in this
build.

**INFERRED design consequence:** upstream selection, routes, NAT, DHCP and DNS have to be one owned transaction with
explicit rollback. A successful API response is not evidence that no traffic can leave over cellular; only a capture
is, and this phone has no `tcpdump`.

## Launch behaviour • VERIFIED STATIC

`com.apple.MobileInternetSharing` runs `/usr/libexec/misd` with `RunAtLoad`, adaptive process and pressured-exit
settings: a client- and transaction-aware service, not a one-shot command. `misd` also advertises CLI options including
`-e EXTIF`, `-B`, `-v`, port-range and timeout options; that is evidence of configurable behaviour, not a reason to
start a competing instance alongside the stock one.
