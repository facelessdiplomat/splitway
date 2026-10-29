//go:build ios

package fdtunnel

import "runtime/debug"

const networkExtensionMemoryLimitBytes = 30 << 20

func init() {
	debug.SetMemoryLimit(networkExtensionMemoryLimitBytes)
}
