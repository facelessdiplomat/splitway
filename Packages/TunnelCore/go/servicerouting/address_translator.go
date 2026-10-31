package servicerouting

import (
	"net/netip"
	"sync"
	"time"
)

type fakeAddressSource interface {
	realAddress(fake netip.Addr) (netip.Addr, bool)
}

type addressTranslator struct {
	fakeNetworks []netip.Prefix
	addresses    fakeAddressSource
	clock        func() time.Time
	start        time.Time
	mutex        sync.Mutex
	connections  *connectionTable
}

func newAddressTranslator(fakeNetworks []netip.Prefix, addresses fakeAddressSource, clock func() time.Time, capacity int) *addressTranslator {
	return &addressTranslator{
		fakeNetworks: fakeNetworks,
		addresses:    addresses,
		clock:        clock,
		start:        clock(),
		connections:  newConnectionTable(capacity),
	}
}

func (translator *addressTranslator) outbound(packet []byte) bool {
	layout, isParsed := layoutOf(packet)
	if !isParsed {
		return true
	}
	fake := layout.destination(packet)
	if !translator.isFake(fake) {
		return true
	}
	if !layout.hasPorts {
		return false
	}
	key := connectionKey{
		protocol: layout.protocol,
		local:    netip.AddrPortFrom(layout.source(packet), layout.sourcePort(packet)),
		remote:   netip.AddrPortFrom(fake, layout.destinationPort(packet)),
	}
	real, isTracked := translator.trackOutbound(key, connectionFlags(layout, packet))
	if !isTracked {
		return false
	}
	replaceAddress(packet, layout, layout.destinationOffset, real)
	return true
}

func (translator *addressTranslator) inbound(packet []byte) {
	layout, isParsed := layoutOf(packet)
	if !isParsed || !layout.hasPorts {
		return
	}
	key := connectionKey{
		protocol: layout.protocol,
		local:    netip.AddrPortFrom(layout.destination(packet), layout.destinationPort(packet)),
		remote:   netip.AddrPortFrom(layout.source(packet), layout.sourcePort(packet)),
	}
	if fake, isTracked := translator.trackInbound(key, connectionFlags(layout, packet)); isTracked {
		replaceAddress(packet, layout, layout.sourceOffset, fake)
	}
}

func (translator *addressTranslator) trackOutbound(key connectionKey, tcpFlags uint8) (netip.Addr, bool) {
	translator.mutex.Lock()
	defer translator.mutex.Unlock()
	now := translator.elapsed()
	position, isOpen := translator.connections.outbound(key, now)
	if !isOpen {
		real, isKnown := translator.addresses.realAddress(key.remote.Addr())
		if !isKnown || real.Is4() != key.remote.Addr().Is4() {
			return netip.Addr{}, false
		}
		if position, isOpen = translator.connections.open(key, real, now); !isOpen {
			return netip.Addr{}, false
		}
	}
	return translator.connections.observeOutbound(position, tcpFlags, now), true
}

func (translator *addressTranslator) trackInbound(key connectionKey, tcpFlags uint8) (netip.Addr, bool) {
	translator.mutex.Lock()
	defer translator.mutex.Unlock()
	now := translator.elapsed()
	position, isOpen := translator.connections.inbound(key, now)
	if !isOpen {
		return netip.Addr{}, false
	}
	return translator.connections.observeInbound(position, tcpFlags, now), true
}

func (translator *addressTranslator) elapsed() time.Duration {
	return translator.clock().Sub(translator.start)
}

func (translator *addressTranslator) isFake(address netip.Addr) bool {
	for _, network := range translator.fakeNetworks {
		if network.Contains(address) {
			return true
		}
	}
	return false
}

func connectionFlags(layout packetLayout, packet []byte) uint8 {
	if layout.protocol != protocolTCP {
		return 0
	}
	return layout.tcpFlags(packet)
}
