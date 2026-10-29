package main

import (
	"sync"

	"splitway/tunnelcore/fdtunnel"
)

const firstHandle int32 = 1

type tunnelRegistry struct {
	mutex      sync.Mutex
	tunnels    map[int32]*fdtunnel.Tunnel
	lastHandle int32
}

func newTunnelRegistry() *tunnelRegistry {
	return &tunnelRegistry{tunnels: make(map[int32]*fdtunnel.Tunnel)}
}

func (registry *tunnelRegistry) add(tunnel *fdtunnel.Tunnel) int32 {
	registry.mutex.Lock()
	defer registry.mutex.Unlock()
	handle := registry.nextFreeHandle()
	registry.tunnels[handle] = tunnel
	return handle
}

func (registry *tunnelRegistry) tunnel(handle int32) (*fdtunnel.Tunnel, bool) {
	registry.mutex.Lock()
	defer registry.mutex.Unlock()
	tunnel, found := registry.tunnels[handle]
	return tunnel, found
}

func (registry *tunnelRegistry) remove(handle int32) (*fdtunnel.Tunnel, bool) {
	registry.mutex.Lock()
	defer registry.mutex.Unlock()
	tunnel, found := registry.tunnels[handle]
	delete(registry.tunnels, handle)
	return tunnel, found
}

func (registry *tunnelRegistry) nextFreeHandle() int32 {
	for {
		registry.lastHandle++
		if registry.lastHandle < firstHandle {
			registry.lastHandle = firstHandle
		}
		if _, taken := registry.tunnels[registry.lastHandle]; !taken {
			return registry.lastHandle
		}
	}
}
