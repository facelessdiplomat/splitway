package servicerouting

import (
	"bytes"
	"encoding/binary"
	"fmt"
	"net/netip"
	"testing"
)

func TestReplacingAnAddressGivesTheChecksumsOfAFullRecompute(t *testing.T) {
	families := []struct {
		name        string
		source      netip.AddrPort
		destination netip.AddrPort
		replacement netip.Addr
	}{
		{"IPv4", netip.AddrPortFrom(deviceIPv4, 50000), netip.AddrPortFrom(fakeIPv4, 443), realIPv4},
		{"IPv6", netip.AddrPortFrom(deviceIPv6, 50000), netip.AddrPortFrom(fakeIPv6, 443), realIPv6},
	}
	for _, family := range families {
		for _, protocol := range []uint8{protocolTCP, protocolUDP} {
			for _, payloadByteCount := range []int{0, 1, 2, 3, 511, 1400} {
				for _, isDestination := range []bool{true, false} {
					name := fmt.Sprintf("%s protocol %d payload %d destination %v", family.name, protocol, payloadByteCount, isDestination)
					t.Run(name, func(t *testing.T) {
						spec := segmentSpec{protocol: protocol, source: family.source, destination: family.destination,
							tcpFlags: tcpFlagACK, payload: deterministicPayload(payloadByteCount)}
						packet := packetFor(spec)
						layout, _ := layoutOf(packet)
						offset := layout.sourceOffset
						if isDestination {
							offset = layout.destinationOffset
						}

						replaceAddress(packet, layout, offset, family.replacement)

						if layout.addressAt(packet, offset) != family.replacement {
							t.Fatalf("expected %v at offset %d, got %v", family.replacement, offset, layout.addressAt(packet, offset))
						}
						expectChecksumsOfAFullRecompute(t, packet, layout)
					})
				}
			}
		}
	}
}

func TestReplacingAnAddressKeepsTheIPv4HeaderChecksumWithOptions(t *testing.T) {
	packet := ipv4PacketWithOptions(tcpSpec(netip.AddrPortFrom(deviceIPv4, 50000), netip.AddrPortFrom(fakeIPv4, 443), tcpFlagSYN, nil))
	layout, _ := layoutOf(packet)

	replaceAddress(packet, layout, layout.destinationOffset, realIPv4)

	expectChecksumsOfAFullRecompute(t, packet, layout)
}

func TestReplacingAnAddressKeepsAMissingUDPChecksumMissing(t *testing.T) {
	packet := packetFor(udpSpec(netip.AddrPortFrom(deviceIPv4, 50000), netip.AddrPortFrom(fakeIPv4, 443), []byte("query")))
	binary.BigEndian.PutUint16(packet[ipv4MinimumHeaderByteCount+udpChecksumOffset:], 0)
	layout, _ := layoutOf(packet)

	replaceAddress(packet, layout, layout.destinationOffset, realIPv4)

	if checksum := binary.BigEndian.Uint16(packet[ipv4MinimumHeaderByteCount+udpChecksumOffset:]); checksum != 0 {
		t.Fatalf("expected the UDP checksum to stay absent, got %#x", checksum)
	}
}

func TestReplacingAnAddressSendsAZeroUDPChecksumAsAllOnes(t *testing.T) {
	source, destination := netip.AddrPortFrom(deviceIPv4, 50000), netip.AddrPortFrom(fakeIPv4, 443)
	for word := range 1 << 16 {
		payload := binary.BigEndian.AppendUint16(nil, uint16(word))
		packet := packetFor(udpSpec(source, destination, payload))
		layout, _ := layoutOf(packet)
		expected := append([]byte(nil), packet...)
		replaceAddressByRecompute(expected, layout, layout.destinationOffset, realIPv4)
		if binary.BigEndian.Uint16(expected[layout.transportOffset+udpChecksumOffset:]) != transmittedZeroChecksum {
			continue
		}

		replaceAddress(packet, layout, layout.destinationOffset, realIPv4)

		if checksum := binary.BigEndian.Uint16(packet[layout.transportOffset+udpChecksumOffset:]); checksum != transmittedZeroChecksum {
			t.Fatalf("expected a computed zero to go out as %#x, got %#x", transmittedZeroChecksum, checksum)
		}
		return
	}
	t.Fatal("no payload gives a zero UDP checksum")
}

func TestReplacingAnAddressInALaterFragmentChangesOnlyTheIPHeader(t *testing.T) {
	packet := withIPv4Fragment(packetFor(udpSpec(netip.AddrPortFrom(realIPv4, 443), netip.AddrPortFrom(deviceIPv4, 50000), deterministicPayload(64))), 8, false)
	layout, _ := layoutOf(packet)
	payloadBefore := append([]byte(nil), packet[layout.transportOffset:]...)

	replaceAddress(packet, layout, layout.sourceOffset, fakeIPv4)

	if referenceFold(referenceSum(packet[:layout.transportOffset], 0)) != 0xFFFF {
		t.Fatal("the IPv4 header checksum is wrong")
	}
	if !bytes.Equal(packet[layout.transportOffset:], payloadBefore) {
		t.Fatal("the fragment payload changed")
	}
}

func expectChecksumsOfAFullRecompute(t *testing.T, packet []byte, layout packetLayout) {
	t.Helper()
	expected := append([]byte(nil), packet...)
	fillReferenceChecksums(expected, layout.transportOffset, layout.protocol)
	if layout.isIPv4 && !isSameChecksum(packet[ipv4HeaderChecksumOffset:], expected[ipv4HeaderChecksumOffset:]) {
		t.Fatalf("IPv4 header checksum %#x, recompute gives %#x",
			binary.BigEndian.Uint16(packet[ipv4HeaderChecksumOffset:]), binary.BigEndian.Uint16(expected[ipv4HeaderChecksumOffset:]))
	}
	offset := layout.transportOffset + transportChecksumOffsetFor(layout.protocol)
	if !isSameChecksum(packet[offset:], expected[offset:]) {
		t.Fatalf("transport checksum %#x, recompute gives %#x", binary.BigEndian.Uint16(packet[offset:]), binary.BigEndian.Uint16(expected[offset:]))
	}
}

func isSameChecksum(actual, expected []byte) bool {
	first, second := binary.BigEndian.Uint16(actual), binary.BigEndian.Uint16(expected)
	return first == second || (first == 0 && second == 0xFFFF) || (first == 0xFFFF && second == 0)
}

func replaceAddressByRecompute(packet []byte, layout packetLayout, offset int, replacement netip.Addr) {
	copy(packet[offset:], replacement.AsSlice())
	fillReferenceChecksums(packet, layout.transportOffset, layout.protocol)
}

func deterministicPayload(byteCount int) []byte {
	payload := make([]byte, byteCount)
	for index := range payload {
		payload[index] = byte(index*31 + 7)
	}
	return payload
}
