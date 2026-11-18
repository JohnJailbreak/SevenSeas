# Open questions and the next experiments

In priority order. The first question decides whether the project is possible.

## 1. Which path drops the Wi-Fi? • NEEDS DEVICE TEST

Two independent mechanisms produce the same visible outcome:

- the **role gate**, where [`wifid 0x1000F90DC`](wifid.md) refuses the SoftAP role and `0x1000D085C` disconnects with
  reason `0x3EF`; or
- the **channel rules** in the stock MIS coordinator `0x10012D548`: 6 GHz, width above 80 MHz, a DFS or
  coexistence-denied channel.

They have different consequences. If the capability byte is zero, the chip is declaring it cannot do AP and STA at once
and the project stops there, short of firmware work that nothing so far justifies. If a channel rule fired, a
conservative channel may simply work.

**The experiment:** run the [read-only Frida probe](tools/README.md) and start the stock hotspot. The probe prints the
capability byte, the role mask, the band preference and the disconnect reason with its caller, so one run distinguishes
the two. Status: **not yet run.**

## 2. What was the upstream band and channel? • NEEDS DEVICE TEST

Never recorded for the capture in [device observations](device-observations.md). Repeat the test on a known-clean
upstream: 2.4 GHz channel 1, 6 or 11, or 5 GHz channels 36–48 at 80 MHz or less, both well inside what Apple documents
for this model. If the drop still happens on a conservative channel, the channel rules are ruled out and the role gate
is the answer.

## 3. How does the driver's capability reach `wifid`? • NEEDS DEVICE TEST

The dext derives feature bit `0x46` from the firmware's `rsdb` capability, and `isApStaSDBMode` reads a separate bit
`0x3F` for which no setter was found. `wifid` reads bit 6 of byte `+0x25` in its device object. **Whether these are the
same fact is unverified.** Tracing it statically means following `wifid`'s capability byte back through its
Apple80211/IO80211 request to the driver's feature bits; the Ghidra projects for `wifid`, the dext and `IO80211DriverKit`
all still exist.

## 4. Can `misd` be asked for a Wi-Fi upstream at all? • NEEDS DEVICE TEST

The schema is recovered and Netrb's side confirms it, but it has never been invoked. It needs the
`com.apple.MobileInternetSharing.allow` entitlement, a real XPC callback endpoint under `clientCommunication` and a
connection-bound `clientid`. Worth attempting only after question 1 is answered: a validated external name is useless
while the association is being torn down.

## 5. Can egress be proven? • Blocked

A hard cellular lockout is a claim about packets, and this phone has neither `tcpdump` nor `pfctl`
([see the environment](device.md)). Until capture exists on the phone or at the upstream router, any lockout claim
stays unverified. Plan for an upstream-side capture, or treat this as a reason to install capture tooling early.

## What would also help

| Input | Why |
|---|---|
| An IORegistry and capability dump from the running phone | Shows which interface classes are actually instantiated and what capabilities are live, rather than what the configuration permits |
| Unified-log output from `wifid` during a hotspot start | Its own diagnostics name the reason directly; no `log` binary is present on the phone today |
| A packet capture at the upstream router | The only currently plausible way to test the lockout |

## Standing rules for anything built on this

1. Addresses here belong to these exact binaries. Match the SHA-256 before using any of them. ARM64e pointer
   authentication and calling conventions need a compatible hook framework and a validated ABI.
2. Do not hook `0x1000F90DC` to return true globally, or no-op the disconnect helper. Both affect every other Wi-Fi
   feature on the phone. Any override must be tied to an owned session and must preserve genuine hardware and
   coexistence failures.
3. Observe before intervening. The first milestone is a diagnostic that reports association, interface indices,
   driver capability, role state and the requested upstream, with no changes at all.
4. Treat upstream selection, routes, NAT, DHCP and DNS as one transaction with explicit rollback, and keep teardown
   limited to SevenSeas-owned resources.
5. Report every guarantee as unverified until a capture establishes it.
