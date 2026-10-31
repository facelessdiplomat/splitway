package servicerouting

import (
	"encoding/binary"
	"net/netip"
	"testing"
)

func TestPacketLayoutFindsTheTransportHeader(t *testing.T) {
	deviceSide, fakeSide := netip.AddrPortFrom(deviceIPv4, 50000), netip.AddrPortFrom(fakeIPv4, 443)
	deviceSide6, fakeSide6 := netip.AddrPortFrom(deviceIPv6, 50000), netip.AddrPortFrom(fakeIPv6, 443)
	cases := []struct {
		name            string
		packet          []byte
		transportOffset int
		protocol        uint8
	}{
		{"IPv4 TCP", packetFor(tcpSpec(deviceSide, fakeSide, tcpFlagSYN, nil)), 20, protocolTCP},
		{"IPv4 UDP", packetFor(udpSpec(deviceSide, fakeSide, []byte("query"))), 20, protocolUDP},
		{"IPv4 TCP after options", ipv4PacketWithOptions(tcpSpec(deviceSide, fakeSide, tcpFlagSYN, nil)), 24, protocolTCP},
		{"IPv6 TCP", packetFor(tcpSpec(deviceSide6, fakeSide6, tcpFlagSYN, nil)), 40, protocolTCP},
		{"IPv6 UDP after options headers", packetWithExtensions(udpSpec(deviceSide6, fakeSide6, []byte("query")),
			[]extensionHeader{optionsExtension(hopByHopOptionsHeader), optionsExtension(destinationOptionsHeader)}), 56, protocolUDP},
		{"IPv6 TCP in a first fragment", packetWithExtensions(tcpSpec(deviceSide6, fakeSide6, tcpFlagSYN, nil),
			[]extensionHeader{fragmentExtension(0, true)}), 48, protocolTCP},
	}
	for _, testCase := range cases {
		t.Run(testCase.name, func(t *testing.T) {
			layout, isParsed := layoutOf(testCase.packet)

			if !isParsed || !layout.hasPorts || layout.transportOffset != testCase.transportOffset ||
				layout.protocol != testCase.protocol || layout.isLaterFragment {
				t.Fatalf("unexpected layout %+v, parsed %v", layout, isParsed)
			}
		})
	}
}

func TestPacketLayoutReadsAddressesAndPorts(t *testing.T) {
	cases := []struct {
		name        string
		source      netip.AddrPort
		destination netip.AddrPort
	}{
		{"IPv4", netip.AddrPortFrom(deviceIPv4, 50000), netip.AddrPortFrom(fakeIPv4, 443)},
		{"IPv6", netip.AddrPortFrom(deviceIPv6, 50001), netip.AddrPortFrom(fakeIPv6, 8443)},
	}
	for _, testCase := range cases {
		t.Run(testCase.name, func(t *testing.T) {
			packet := packetFor(udpSpec(testCase.source, testCase.destination, []byte("payload")))

			layout, _ := layoutOf(packet)

			source := netip.AddrPortFrom(layout.source(packet), layout.sourcePort(packet))
			destination := netip.AddrPortFrom(layout.destination(packet), layout.destinationPort(packet))
			if source != testCase.source || destination != testCase.destination {
				t.Fatalf("expected %v → %v, got %v → %v", testCase.source, testCase.destination, source, destination)
			}
		})
	}
}

func TestPacketLayoutReadsTCPFlags(t *testing.T) {
	packet := packetFor(tcpSpec(netip.AddrPortFrom(deviceIPv4, 50000), netip.AddrPortFrom(fakeIPv4, 443), tcpFlagFIN|tcpFlagACK, nil))

	layout, _ := layoutOf(packet)

	if layout.tcpFlags(packet) != tcpFlagFIN|tcpFlagACK {
		t.Fatalf("expected FIN and ACK, got %#x", layout.tcpFlags(packet))
	}
}

func TestPacketLayoutHasNoPortsInALaterFragment(t *testing.T) {
	ipv4 := withIPv4Fragment(packetFor(udpSpec(netip.AddrPortFrom(deviceIPv4, 50000), netip.AddrPortFrom(fakeIPv4, 443), make([]byte, 64))), 8, false)
	ipv6 := packetWithExtensions(udpSpec(netip.AddrPortFrom(deviceIPv6, 50000), netip.AddrPortFrom(fakeIPv6, 443), make([]byte, 64)),
		[]extensionHeader{fragmentExtension(8, false)})
	for name, packet := range map[string][]byte{"IPv4": ipv4, "IPv6": ipv6} {
		t.Run(name, func(t *testing.T) {
			layout, isParsed := layoutOf(packet)

			if !isParsed || layout.hasPorts || !layout.isLaterFragment {
				t.Fatalf("expected a later fragment without ports, got %+v parsed %v", layout, isParsed)
			}
		})
	}
}

func TestPacketLayoutRejectsMalformedPackets(t *testing.T) {
	valid := packetFor(tcpSpec(netip.AddrPortFrom(deviceIPv4, 50000), netip.AddrPortFrom(fakeIPv4, 443), tcpFlagSYN, nil))
	valid6 := packetFor(tcpSpec(netip.AddrPortFrom(deviceIPv6, 50000), netip.AddrPortFrom(fakeIPv6, 443), tcpFlagSYN, nil))
	cases := map[string][]byte{
		"empty":                          {},
		"shorter than an IPv4 header":    valid[:ipv4MinimumHeaderByteCount-1],
		"unknown version":                withByte(valid, 0, 0x55),
		"IPv4 header length below five":  withByte(valid, 0, 0x44),
		"IPv4 total length past the end": withUint16(valid, ipv4TotalLengthOffset, uint16(len(valid)+1)),
		"IPv4 total length in header":    withUint16(valid, ipv4TotalLengthOffset, ipv4MinimumHeaderByteCount-1),
		"shorter than an IPv6 header":    valid6[:ipv6HeaderByteCount-1],
		"IPv6 payload past the end":      withUint16(valid6, ipv6PayloadLengthOffset, uint16(len(valid6))),
	}
	for name, packet := range cases {
		t.Run(name, func(t *testing.T) {
			if layout, isParsed := layoutOf(packet); isParsed {
				t.Fatalf("expected a rejection, got %+v", layout)
			}
		})
	}
}

func TestPacketLayoutHasNoPortsWithoutACompleteTransportHeader(t *testing.T) {
	tcp := packetFor(tcpSpec(netip.AddrPortFrom(deviceIPv4, 50000), netip.AddrPortFrom(fakeIPv4, 443), tcpFlagSYN, nil))
	udp := packetFor(udpSpec(netip.AddrPortFrom(deviceIPv4, 50000), netip.AddrPortFrom(fakeIPv4, 443), nil))
	tcp6 := packetFor(tcpSpec(netip.AddrPortFrom(deviceIPv6, 50000), netip.AddrPortFrom(fakeIPv6, 443), tcpFlagSYN, nil))
	cases := map[string][]byte{
		"TCP header cut by the total length":  withUint16(tcp, ipv4TotalLengthOffset, ipv4MinimumHeaderByteCount+tcpMinimumHeaderByteCount-1),
		"TCP data offset below five":          withByte(tcp, ipv4MinimumHeaderByteCount+tcpDataOffsetOffset, 4<<tcpDataOffsetShift),
		"TCP data offset past the segment":    withByte(tcp, ipv4MinimumHeaderByteCount+tcpDataOffsetOffset, 6<<tcpDataOffsetShift),
		"UDP header cut by the total length":  withUint16(udp, ipv4TotalLengthOffset, ipv4MinimumHeaderByteCount+udpHeaderByteCount-1),
		"IPv6 extension header cut":           withByte(withUint16(tcp6, ipv6PayloadLengthOffset, 4), ipv6NextHeaderOffset, hopByHopOptionsHeader)[:ipv6HeaderByteCount+4],
		"IPv6 without a next header":          withByte(tcp6, ipv6NextHeaderOffset, noNextHeader),
		"IPv4 protocol other than TCP or UDP": withByte(tcp, ipv4ProtocolOffset, 1),
	}
	for name, packet := range cases {
		t.Run(name, func(t *testing.T) {
			layout, isParsed := layoutOf(packet)

			if !isParsed || layout.hasPorts {
				t.Fatalf("expected a parsed packet without ports, got %+v parsed %v", layout, isParsed)
			}
		})
	}
}

func TestPacketLayoutStopsAtTheIPPacketEnd(t *testing.T) {
	packet := packetFor(udpSpec(netip.AddrPortFrom(deviceIPv4, 50000), netip.AddrPortFrom(fakeIPv4, 443), []byte("query")))
	padded := append(append([]byte(nil), packet...), make([]byte, 32)...)

	layout, _ := layoutOf(padded)

	if layout.packetEnd != len(packet) {
		t.Fatalf("expected the packet to end at %d, got %d", len(packet), layout.packetEnd)
	}
}

func TestPacketLayoutGivesUpOnALongExtensionChain(t *testing.T) {
	extensions := make([]extensionHeader, maximumExtensionHeaderCount+1)
	for index := range extensions {
		extensions[index] = optionsExtension(destinationOptionsHeader)
	}
	packet := packetWithExtensions(udpSpec(netip.AddrPortFrom(deviceIPv6, 50000), netip.AddrPortFrom(fakeIPv6, 443), nil), extensions)

	layout, isParsed := layoutOf(packet)

	if !isParsed || layout.hasPorts {
		t.Fatalf("expected no ports after %d extension headers, got %+v", len(extensions), layout)
	}
}

func withByte(packet []byte, offset int, value byte) []byte {
	copied := append([]byte(nil), packet...)
	copied[offset] = value
	return copied
}

func withUint16(packet []byte, offset int, value uint16) []byte {
	copied := append([]byte(nil), packet...)
	binary.BigEndian.PutUint16(copied[offset:], value)
	return copied
}
