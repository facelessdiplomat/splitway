import re
import sys
from collections import Counter

LINE = re.compile(r"^([ +!:|]*?)(\d+) (.*)$")
FUNCTION = re.compile(r"^(.*?)\s+\(in (.+?)\)")
SYSTEM = ("libsystem_", "libdispatch", "libxpc", "libc++", "libswift", "Foundation", "CoreFoundation")


def callers(path, leaf):
    lines = open(path, encoding="utf-8", errors="replace").read().splitlines()
    start = next(i for i, line in enumerate(lines) if line.startswith("Call graph:"))
    end = next(i for i, line in enumerate(lines) if line.startswith("Total number in stack"))
    stack = []
    found = Counter()
    for line in lines[start + 1:end]:
        match = LINE.match(line)
        if not match:
            continue
        depth = len(match.group(1))
        count = int(match.group(2))
        rest = match.group(3)
        described = FUNCTION.match(rest)
        function, binary = (described.group(1).strip(), described.group(2)) if described else (rest.strip(), "")
        while stack and stack[-1][0] >= depth:
            stack.pop()
        stack.append((depth, function, binary))
        if function == leaf:
            path_names = [f for _, f, b in stack[:-1] if not b.startswith(SYSTEM) and not f.startswith("Thread_")]
            meaningful = [f for f in path_names if not f.startswith(("runtime.", "syscall.", "internal/", "golang.org/x/sys"))]
            found[" <- ".join(name[:70] for name in reversed(meaningful[-3:]))] += count
    return found


path, leaf = sys.argv[1], sys.argv[2]
for chain, count in callers(path, leaf).most_common(8):
    print(f"{count:6} {chain}")
