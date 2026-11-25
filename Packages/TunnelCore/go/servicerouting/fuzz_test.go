package servicerouting

import (
	"encoding/binary"
	"testing"
)

func FuzzPacketLayoutStaysInsideThePacket(f *testing.F) {
	addFuzzSeeds(f)
	f.Fuzz(func(t *testing.T, packet []byte) {
		layout, isParsed := layoutOf(packet)
		if !isParsed {
			return
		}

		if layout.packetEnd > len(packet) || layout.transportOffset > layout.packetEnd ||
			layout.destinationOffset+layout.addressByteCount > layout.packetEnd {
			t.Fatalf("layout %+v leaves a packet of %d bytes", layout, len(packet))
		}
		layout.source(packet)
		layout.destination(packet)
		if layout.hasPorts {
			layout.sourcePort(packet)
			layout.destinationPort(packet)
			connectionFlags(layout, packet)
		}
	})
}

func FuzzTranslatorKeepsValidChecksumsValid(f *testing.F) {
	addFuzzSeeds(f)
	f.Fuzz(func(t *testing.T, packet []byte) {
		fixture := newTranslatorFixture(4)
		outbound := append([]byte(nil), packet...)
		inbound := append([]byte(nil), packet...)
		wasValid := hasValidChecksums(packet)

		fixture.translator.outbound(outbound)
		fixture.translator.inbound(inbound)

		if wasValid && (!hasValidChecksums(outbound) || !hasValidChecksums(inbound)) {
			t.Fatal("translation broke the checksums of a valid packet")
		}
	})
}

func addFuzzSeeds(f *testing.F) {
	f.Add(packetFor(tcpSpec(port(deviceIPv4, 50000), port(fakeIPv4, 443), tcpFlagSYN, []byte("hello"))))
	f.Add(packetFor(udpSpec(port(deviceIPv4, 50000), port(fakeIPv4, 443), []byte("initial"))))
	f.Add(packetFor(tcpSpec(port(realIPv4, 443), port(deviceIPv4, 50000), tcpFlagSYN|tcpFlagACK, nil)))
	f.Add(packetFor(udpSpec(port(deviceIPv6, 50000), port(fakeIPv6, 443), []byte("initial"))))
	f.Add(packetWithExtensions(tcpSpec(port(deviceIPv6, 50000), port(fakeIPv6, 443), tcpFlagSYN, nil),
		[]extensionHeader{optionsExtension(hopByHopOptionsHeader), fragmentExtension(0, true)}))
	f.Add(ipv4PacketWithOptions(tcpSpec(port(deviceIPv4, 50000), port(fakeIPv4, 443), tcpFlagSYN, nil)))
}

func hasValidChecksums(packet []byte) bool {
	layout, isParsed := layoutOf(packet)
	if !isParsed || !layout.hasPorts {
		return false
	}
	ipPacket := packet[:layout.packetEnd]
	if layout.isIPv4 && referenceFold(referenceSum(ipPacket[:layout.transportOffset], 0)) != 0xFFFF {
		return false
	}
	checksum := binary.BigEndian.Uint16(ipPacket[layout.transportOffset+transportChecksumOffsetFor(layout.protocol):])
	if layout.protocol == protocolUDP && checksum == 0 {
		return false
	}
	segment := ipPacket[layout.transportOffset:]
	return referenceFold(referenceSum(segment, pseudoHeaderSumFor(ipPacket, layout))) == 0xFFFF
}

func pseudoHeaderSumFor(packet []byte, layout packetLayout) uint32 {
	addresses := packet[layout.sourceOffset : layout.destinationOffset+layout.addressByteCount]
	return referenceSum(addresses, 0) + uint32(layout.protocol) + uint32(layout.packetEnd-layout.transportOffset)
}
