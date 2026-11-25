package servicerouting

import (
	"encoding/binary"
	"net/netip"
	"sync"
	"time"
)

const (
	dnsPort               = 53
	dnsHeaderByteCount    = 12
	maximumPendingQueries = 512
	pendingQueryTimeout   = 10 * time.Second
)

type pendingQuery struct {
	client     netip.AddrPort
	identifier uint16
}

type dnsInterceptor struct {
	virtualDNS  netip.Addr
	upstreamDNS netip.Addr
	addresses   answerAddresses
	clock       func() time.Time
	start       time.Time
	mutex       sync.Mutex
	pending     map[pendingQuery]time.Duration
}

func newDNSInterceptor(virtualDNS, upstreamDNS netip.Addr, addresses answerAddresses, clock func() time.Time) *dnsInterceptor {
	return &dnsInterceptor{
		virtualDNS:  virtualDNS,
		upstreamDNS: upstreamDNS,
		addresses:   addresses,
		clock:       clock,
		start:       clock(),
		pending:     make(map[pendingQuery]time.Duration, maximumPendingQueries),
	}
}

func (interceptor *dnsInterceptor) outbound(packet []byte, layout packetLayout) (isHandled bool, isForwarded bool) {
	if layout.destination(packet) != interceptor.virtualDNS {
		return false, false
	}
	if layout.protocol != protocolUDP || !layout.hasPorts || layout.destinationPort(packet) != dnsPort {
		return true, false
	}
	message := packet[layout.transportOffset+udpHeaderByteCount : layout.packetEnd]
	if len(message) < dnsHeaderByteCount {
		return true, false
	}
	interceptor.remember(pendingQuery{
		client:     netip.AddrPortFrom(layout.source(packet), layout.sourcePort(packet)),
		identifier: binary.BigEndian.Uint16(message),
	})
	replaceAddress(packet, layout, layout.destinationOffset, interceptor.upstreamDNS)
	return true, true
}

func (interceptor *dnsInterceptor) inbound(packet []byte, layout packetLayout) (answer []byte, isHandled bool) {
	if layout.source(packet) != interceptor.upstreamDNS || layout.protocol != protocolUDP {
		return nil, false
	}
	if !layout.hasPorts {
		return nil, true
	}
	if layout.sourcePort(packet) != dnsPort {
		return nil, false
	}
	message := packet[layout.transportOffset+udpHeaderByteCount : layout.packetEnd]
	if len(message) < dnsHeaderByteCount {
		return nil, true
	}
	query := pendingQuery{
		client:     netip.AddrPortFrom(layout.destination(packet), layout.destinationPort(packet)),
		identifier: binary.BigEndian.Uint16(message),
	}
	if !interceptor.forget(query) {
		return nil, false
	}
	rewritten, err := rewriteDNSResponse(message, interceptor.addresses)
	if err != nil {
		return nil, true
	}
	return answerPacket(packet, layout, interceptor.virtualDNS, rewritten), true
}

func (interceptor *dnsInterceptor) remember(query pendingQuery) {
	interceptor.mutex.Lock()
	defer interceptor.mutex.Unlock()
	now := interceptor.elapsed()
	if len(interceptor.pending) >= maximumPendingQueries {
		interceptor.forgetOldest(now)
	}
	interceptor.pending[query] = now
}

func (interceptor *dnsInterceptor) forget(query pendingQuery) bool {
	interceptor.mutex.Lock()
	defer interceptor.mutex.Unlock()
	sent, isPending := interceptor.pending[query]
	if !isPending {
		return false
	}
	delete(interceptor.pending, query)
	return interceptor.elapsed()-sent <= pendingQueryTimeout
}

func (interceptor *dnsInterceptor) forgetOldest(now time.Duration) {
	oldest, oldestSent, isFound := pendingQuery{}, now, false
	for query, sent := range interceptor.pending {
		if now-sent > pendingQueryTimeout {
			delete(interceptor.pending, query)
			continue
		}
		if !isFound || sent < oldestSent {
			oldest, oldestSent, isFound = query, sent, true
		}
	}
	if isFound && len(interceptor.pending) >= maximumPendingQueries {
		delete(interceptor.pending, oldest)
	}
}

func (interceptor *dnsInterceptor) elapsed() time.Duration {
	return interceptor.clock().Sub(interceptor.start)
}

func answerPacket(response []byte, layout packetLayout, source netip.Addr, message []byte) []byte {
	headerEnd := layout.transportOffset + udpHeaderByteCount
	packet := make([]byte, headerEnd+len(message))
	copy(packet, response[:headerEnd])
	copy(packet[headerEnd:], message)
	binary.BigEndian.PutUint16(packet[layout.transportOffset+udpLengthOffset:], uint16(udpHeaderByteCount+len(message)))
	if layout.isIPv4 {
		binary.BigEndian.PutUint16(packet[ipv4TotalLengthOffset:], uint16(len(packet)))
	} else {
		binary.BigEndian.PutUint16(packet[ipv6PayloadLengthOffset:], uint16(len(packet)-ipv6HeaderByteCount))
	}
	answerLayout := layout
	answerLayout.packetEnd = len(packet)
	writeAddress(packet, answerLayout, answerLayout.sourceOffset, source)
	refreshChecksums(packet, answerLayout)
	return packet
}
