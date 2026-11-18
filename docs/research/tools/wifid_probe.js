// sevenseas_wifid_probe.js
// READ-ONLY probe for wifid on iPhone14,5, iOS 17.0 (21A329).
// It logs the arguments and results of two wifid functions. It never changes an
// argument, a return value or any memory.
//
// Addresses come from the static analysis of wifid with SHA-256
//   df6ea02144ae2046df77b989a96b5e8d572e9278d5b3655ce1ad5416975eb8d8
// Before hooking, the script compares the first 16 bytes of each function with the
// bytes recorded in that analysis and refuses to hook if they differ.
//
// What the lines mean:
//   roleCheck  request=4 ... -> REFUSED   wifid said the hotspot role cannot run next
//                                         to the active Wi-Fi client (cap=0 is the cause)
//   infraDisconnect reason=0x3ef          the role-gate path in 0x1000D059C dropped Wi-Fi
//   infraDisconnect ... stock MIS         the stock hotspot coordinator dropped Wi-Fi
//                                         (channel rules: DFS, coex deny list, width, 6 GHz)

'use strict';

const PREFERRED_BASE = 0x100000000;

const TARGETS = {
  roleCheck:  { va: 0x1000f90dc, head: '7f2303d5ff4302d1fa6704a9f85f05a9' },
  disconnect: { va: 0x1000e9c08, head: '7f2303d5ff0304d1fa670ba9f85f0ca9' },
};

// Return addresses (call site + 4) that the report names.
const KNOWN_CALLERS = new Map([
  [0x1000d0860, 'role gate in 0x1000D059C (call at 0x1000D085C)'],
  [0x10012dff4, 'stock MIS coordinator (call at 0x10012DFF0)'],
  [0x10012eef4, 'stock MIS coordinator (call at 0x10012EEF0)'],
]);

function ts() {
  return new Date().toISOString().substring(11, 23);
}

function hex(n) {
  return '0x' + n.toString(16);
}

function bytesHex(addr, n) {
  const a = new Uint8Array(addr.readByteArray(n));
  return Array.from(a).map(b => ('0' + b.toString(16)).slice(-2)).join('');
}

const mod = Process.getModuleByName('wifid');
console.log('[probe] wifid loaded at ' + mod.base + ', size ' + hex(mod.size));

function resolve(name, t) {
  const addr = mod.base.add(t.va - PREFERRED_BASE);
  const got = bytesHex(addr, 16);
  if (got !== t.head) {
    console.log('[probe] ABORT: ' + name + ' bytes differ at ' + hex(t.va) +
                '\n         got      ' + got + '\n         expected ' + t.head);
    return null;
  }
  console.log('[probe] ' + name + ' verified at ' + addr + ' (unslid ' + hex(t.va) + ')');
  return addr;
}

// Manager fields named in the report. Reads only.
function mgrContext(mgr) {
  try {
    return 'cap=' + mgr.add(0x1750).readU8() +
           ' roleMask=0x' + mgr.add(0x1751).readU8().toString(16) +
           ' bandPref=' + mgr.add(0x1748).readU8() +
           ' nanBand=' + mgr.add(0x174c).readU32() +
           ' forceFlag=' + mgr.add(0x10e1).readU8();
  } catch (e) {
    return 'ctx-unreadable(' + e.message + ')';
  }
}

function inWifid(p) {
  return p.compare(mod.base) >= 0 && p.compare(mod.base.add(mod.size)) < 0;
}

function unslid(p) {
  return (p.sub(mod.base).toInt32() >>> 0) + PREFERRED_BASE;
}

function stripped(p) {
  try { return p.strip(); } catch (e) { return p; }
}

const roleAddr = resolve('roleCheck', TARGETS.roleCheck);
const disAddr = resolve('disconnect', TARGETS.disconnect);

if (roleAddr === null || disAddr === null) {
  console.log('[probe] not hooking anything. Wrong build or wrong process?');
} else {
  Interceptor.attach(roleAddr, {
    onEnter(args) {
      this.req = args[1].toInt32();
      this.ctx = mgrContext(args[0]);
    },
    onLeave(retval) {
      const ok = (retval.toInt32() & 0xff) !== 0;
      console.log('[' + ts() + '] roleCheck request=' + this.req + ' ' + this.ctx +
                  ' -> ' + (ok ? 'ALLOWED' : 'REFUSED'));
    },
  });

  Interceptor.attach(disAddr, {
    onEnter(args) {
      const ra = stripped(this.returnAddress);
      const caller = inWifid(ra) ? unslid(ra) : null;
      const label = caller !== null && KNOWN_CALLERS.has(caller)
        ? KNOWN_CALLERS.get(caller)
        : 'other caller';
      console.log('[' + ts() + '] infraDisconnect reason=0x' + (args[2].toInt32() >>> 0).toString(16) +
                  ' caller=' + (caller !== null ? hex(caller) : ra) + ' (' + label + ') ' +
                  mgrContext(args[0]));
      if (label === 'other caller') {
        try {
          const frames = Thread.backtrace(this.context, Backtracer.FUZZY)
            .map(stripped)
            .filter(inWifid)
            .slice(0, 6)
            .map(p => hex(unslid(p)));
          console.log('           wifid frames: ' + frames.join(' <- '));
        } catch (e) {
          console.log('           backtrace failed: ' + e.message);
        }
      }
    },
  });

  console.log('[probe] ready. Nothing is modified. Start the Personal Hotspot now.');
}
