package servicerouting

import "encoding/binary"

const dnsPort = 53

type translator struct {
	plan Plan
	pool *fakeAddressPool
}

func newTranslator(plan Plan) *translator {
	return &translator{plan: plan, pool: newFakeAddressPool(plan)}
}

func (translator *translator) outbound(packet []byte) bool {
	headerByteCount, isIPv4 := ipv4HeaderByteCount(packet)
	if !isIPv4 {
		return true
	}
	destination := destinationAddress(packet)
	switch {
	case destination == translator.plan.VirtualDNS:
		if packet[ipv4ProtocolOffset] != protocolUDP || !hasPort(packet, headerByteCount, destinationPortOffset, dnsPort) {
			return false
		}
		replaceAddress(packet, headerByteCount, ipv4DestinationOffset, translator.plan.UpstreamDNS)
	case translator.plan.FakeNetwork.Contains(destination):
		real, isKnown := translator.pool.realFor(destination)
		if !isKnown {
			return false
		}
		replaceAddress(packet, headerByteCount, ipv4DestinationOffset, real)
	}
	return true
}

func (translator *translator) inbound(packet []byte) ([]byte, bool) {
	headerByteCount, isIPv4 := ipv4HeaderByteCount(packet)
	if !isIPv4 {
		return packet, false
	}
	source := sourceAddress(packet)
	if source == translator.plan.UpstreamDNS && packet[ipv4ProtocolOffset] == protocolUDP &&
		hasPort(packet, headerByteCount, sourcePortOffset, dnsPort) {
		if answer, err := translator.answerFromVirtualResolver(packet, headerByteCount); err == nil {
			return answer, true
		}
		return packet, false
	}
	if fake, isKnown := translator.pool.fakeOf(source); isKnown {
		replaceAddress(packet, headerByteCount, ipv4SourceOffset, fake)
	}
	return packet, false
}

func (translator *translator) answerFromVirtualResolver(packet []byte, headerByteCount int) ([]byte, error) {
	totalByteCount := int(binary.BigEndian.Uint16(packet[ipv4TotalLengthOffset:]))
	rewritten, err := rewriteAnswers(packet[headerByteCount+udpHeaderByteCount:totalByteCount], translator.pool)
	if err != nil {
		return nil, err
	}
	prefixByteCount := headerByteCount + udpHeaderByteCount
	answer := make([]byte, prefixByteCount+len(rewritten))
	copy(answer, packet[:prefixByteCount])
	copy(answer[prefixByteCount:], rewritten)
	binary.BigEndian.PutUint16(answer[ipv4TotalLengthOffset:], uint16(len(answer)))
	binary.BigEndian.PutUint16(answer[headerByteCount+udpLengthOffset:], uint16(udpHeaderByteCount+len(rewritten)))
	virtualDNS := translator.plan.VirtualDNS.As4()
	copy(answer[ipv4SourceOffset:], virtualDNS[:])
	refreshHeaderChecksum(answer)
	refreshTransportChecksum(answer)
	return answer, nil
}
