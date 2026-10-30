import re
import sys
from collections import Counter

IDLE = {
    "__psynch_cvwait", "__workq_kernreturn", "__sigsuspend_nocancel", "kevent", "kevent_id",
    "__semwait_signal", "mach_msg2_trap", "__ulock_wait", "__ulock_wait2", "__select", "poll",
}
LINE = re.compile(r"^([ +!:|]*?)(\d+) (.*)$")
FUNCTION = re.compile(r"^(.*?)\s+\(in (.+?)\)")


def category(function, binary, extension):
    if function in IDLE:
        return "idle"
    if function == "__psynch_mutexwait":
        return "lock waits"
    if "chacha20" in function or "poly1305" in function or "blake2s" in function or "curve25519" in function:
        return "WireGuard crypto"
    if "gvisor.dev/gvisor" in function:
        return "gVisor netstack"
    if "golang.zx2c4.com/wireguard" in function:
        return "wireguard-go"
    if "splitway/tunnelcore" in function:
        return "Splitway Go"
    if function.startswith(("_cgo_", "crosscall2", "runtime.cgocall", "runtime.asmcgocall", "runtime.cgocallback", "x_cgo")):
        return "cgo boundary"
    if binary == extension and (function.startswith(("runtime.", "internal/", "sync.", "sync/", "time.", "syscall.", "golang.org/x/sys", "os.", "io.", "net.", "errors.", "fmt.", "context.", "aeshash", "indexbyte", "memeqbody", "cmpbody"))):
        return "Go runtime"
    if binary == "libsystem_kernel.dylib":
        return "syscalls"
    if binary == "NetworkExtension":
        return "NetworkExtension"
    if binary == extension:
        return "Splitway Swift"
    if binary.startswith(("libswift", "Foundation", "CoreFoundation", "libobjc")):
        return "Swift and Foundation"
    if binary.startswith(("libdispatch", "libsystem_", "libxpc", "libc++")):
        return "system libraries"
    return f"other ({binary})"


def self_samples(path):
    lines = open(path, encoding="utf-8", errors="replace").read().splitlines()
    start = next(i for i, line in enumerate(lines) if line.startswith("Call graph:"))
    end = next(i for i, line in enumerate(lines) if line.startswith("Total number in stack"))
    extension = None
    for line in lines[:20]:
        if line.startswith("Process:"):
            extension = line.split()[1]
    totals = Counter()
    functions = Counter()
    stack = []

    def finish(node):
        depth, count, function, binary, children = node
        own = count - children
        if own > 0 and function is not None:
            name = category(function, binary, extension)
            totals[name] += own
            functions[(name, function)] += own

    for line in lines[start + 1:end]:
        match = LINE.match(line)
        if not match:
            continue
        depth = len(match.group(1))
        count = int(match.group(2))
        rest = match.group(3)
        described = FUNCTION.match(rest)
        if rest.startswith("Thread_"):
            function, binary = None, None
        elif described:
            function, binary = described.group(1).strip(), described.group(2)
        else:
            function, binary = rest.strip(), "unknown"
        while stack and stack[-1][0] >= depth:
            finish(stack.pop())
        if stack:
            stack[-1][4] += count
        stack.append([depth, count, function, binary, 0])
    while stack:
        finish(stack.pop())
    return totals, functions


for path in sys.argv[1:]:
    totals, functions = self_samples(path)
    busy = sum(count for name, count in totals.items() if name != "idle")
    print(f"== {path.rsplit('/', 1)[-1]}: busy samples {busy}")
    for name, count in totals.most_common():
        if name != "idle":
            print(f"  {name:28} {count:6} {count * 100 / busy:5.1f}%")
    print("  top functions:")
    for (name, function), count in functions.most_common(40):
        if name != "idle" and count * 100 / busy >= 1:
            print(f"    {count:6} {count * 100 / busy:5.1f}%  [{name}] {function[:110]}")
