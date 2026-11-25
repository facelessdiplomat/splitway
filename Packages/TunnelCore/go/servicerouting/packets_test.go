package servicerouting

import (
	"encoding/binary"
	"net/netip"
	"testing"
)

const (
	testHopLimit           = 64
	testIPv4Identification = 0x1234
	testIPv4DontFragment   = 0x4000
	testTCPWindow          = 0xFFFF
	testTCPDataOffset      = 5 << 4
	testIPv4VersionAndIHL  = 0x45
	testIPv6VersionWord    = 0x6000_0000
	testExtensionByteCount = 8
	testIPv4OptionWords    = 1
)

var (
	deviceIPv4 = netip.MustParseAddr("10.14.0.2")
	fakeIPv4   = netip.MustParseAddr("198.18.1.0")
	otherFake  = netip.MustParseAddr("198.18.1.1")
	realIPv4   = netip.MustParseAddr("104.26.12.205")
	deviceIPv6 = netip.MustParseAddr("fd00:14::2")
	fakeIPv6   = netip.MustParseAddr("fdc6:8b52::100")
	realIPv6   = netip.MustParseAddr("2606:4700::6810:ccd")
	fakeIPv4s  = netip.MustParsePrefix("198.18.0.0/15")
	fakeIPv6s  = netip.MustParsePrefix("fdc6:8b52::/64")
)

type segmentSpec struct {
	protocol    uint8
	source      netip.AddrPort
	destination netip.AddrPort
	tcpFlags    uint8
	payload     []byte
}

type extensionHeader struct {
	kind uint8
	body []byte
}

func tcpSpec(source, destination netip.AddrPort, flags uint8, payload []byte) segmentSpec {
	return segmentSpec{protocol: protocolTCP, source: source, destination: destination, tcpFlags: flags, payload: payload}
}

func udpSpec(source, destination netip.AddrPort, payload []byte) segmentSpec {
	return segmentSpec{protocol: protocolUDP, source: source, destination: destination, payload: payload}
}

func packetFor(spec segmentSpec) []byte {
	return packetWithExtensions(spec, nil)
}

func packetWithExtensions(spec segmentSpec, extensions []extensionHeader) []byte {
	segment := transportSegment(spec)
	var packet []byte
	if spec.source.Addr().Is4() {
		packet = ipv4Header(spec.source.Addr(), spec.destination.Addr(), spec.protocol, len(segment))
	} else {
		packet = ipv6Header(spec.source.Addr(), spec.destination.Addr(), spec.protocol, extensions, len(segment))
	}
	transportOffset := len(packet)
	packet = append(packet, segment...)
	fillReferenceChecksums(packet, transportOffset, spec.protocol)
	return packet
}

func transportSegment(spec segmentSpec) []byte {
	var header []byte
	switch spec.protocol {
	case protocolTCP:
		header = make([]byte, tcpMinimumHeaderByteCount)
		binary.BigEndian.PutUint32(header[4:], 1)
		header[12] = testTCPDataOffset
		header[13] = spec.tcpFlags
		binary.BigEndian.PutUint16(header[14:], testTCPWindow)
	case protocolUDP:
		header = make([]byte, udpHeaderByteCount)
		binary.BigEndian.PutUint16(header[4:], uint16(udpHeaderByteCount+len(spec.payload)))
	}
	binary.BigEndian.PutUint16(header[0:], spec.source.Port())
	binary.BigEndian.PutUint16(header[2:], spec.destination.Port())
	return append(header, spec.payload...)
}

func ipv4Header(source, destination netip.Addr, protocol uint8, segmentByteCount int) []byte {
	header := make([]byte, ipv4MinimumHeaderByteCount)
	header[0] = testIPv4VersionAndIHL
	binary.BigEndian.PutUint16(header[2:], uint16(ipv4MinimumHeaderByteCount+segmentByteCount))
	binary.BigEndian.PutUint16(header[4:], testIPv4Identification)
	binary.BigEndian.PutUint16(header[6:], testIPv4DontFragment)
	header[8] = testHopLimit
	header[9] = protocol
	sourceBytes, destinationBytes := source.As4(), destination.As4()
	copy(header[12:], sourceBytes[:])
	copy(header[16:], destinationBytes[:])
	return header
}

func ipv6Header(source, destination netip.Addr, protocol uint8, extensions []extensionHeader, segmentByteCount int) []byte {
	header := make([]byte, ipv6HeaderByteCount)
	binary.BigEndian.PutUint32(header[0:], testIPv6VersionWord)
	header[7] = testHopLimit
	sourceBytes, destinationBytes := source.As16(), destination.As16()
	copy(header[8:], sourceBytes[:])
	copy(header[24:], destinationBytes[:])
	header[6] = protocol
	if len(extensions) > 0 {
		header[6] = extensions[0].kind
	}
	for index, extension := range extensions {
		next := protocol
		if index+1 < len(extensions) {
			next = extensions[index+1].kind
		}
		body := append([]byte{next}, extension.body...)
		header = append(header, body...)
	}
	binary.BigEndian.PutUint16(header[4:], uint16(len(header)-ipv6HeaderByteCount+segmentByteCount))
	return header
}

func optionsExtension(kind uint8) extensionHeader {
	return extensionHeader{kind: kind, body: []byte{0, 1, 4, 0, 0, 0, 0}}
}

func fragmentExtension(offsetInUnits uint16, hasMoreFragments bool) extensionHeader {
	body := make([]byte, testExtensionByteCount-1)
	flags := offsetInUnits << 3
	if hasMoreFragments {
		flags |= 1
	}
	binary.BigEndian.PutUint16(body[1:], flags)
	binary.BigEndian.PutUint32(body[3:], testIPv4Identification)
	return extensionHeader{kind: fragmentHeader, body: body}
}

func withIPv4Fragment(packet []byte, offsetInUnits uint16, hasMoreFragments bool) []byte {
	flags := offsetInUnits
	if hasMoreFragments {
		flags |= 0x2000
	}
	binary.BigEndian.PutUint16(packet[6:], flags)
	binary.BigEndian.PutUint16(packet[10:], 0)
	binary.BigEndian.PutUint16(packet[10:], ^referenceFold(referenceSum(packet[:ipv4MinimumHeaderByteCount], 0)))
	return packet
}

func fillReferenceChecksums(packet []byte, transportOffset int, protocol uint8) {
	if packet[0]>>4 == 4 {
		binary.BigEndian.PutUint16(packet[10:], 0)
		binary.BigEndian.PutUint16(packet[10:], ^referenceFold(referenceSum(packet[:transportOffset], 0)))
	}
	offset := transportChecksumOffsetFor(protocol)
	binary.BigEndian.PutUint16(packet[transportOffset+offset:], 0)
	checksum := ^referenceFold(referenceSum(packet[transportOffset:], referencePseudoHeaderSum(packet, transportOffset, protocol)))
	if protocol == protocolUDP && checksum == 0 {
		checksum = 0xFFFF
	}
	binary.BigEndian.PutUint16(packet[transportOffset+offset:], checksum)
}

func transportChecksumOffsetFor(protocol uint8) int {
	if protocol == protocolTCP {
		return 16
	}
	return 6
}

func referenceSum(data []byte, initial uint32) uint32 {
	sum := initial
	for index := 0; index+1 < len(data); index += 2 {
		sum += uint32(binary.BigEndian.Uint16(data[index:]))
	}
	if len(data)%2 == 1 {
		sum += uint32(data[len(data)-1]) << 8
	}
	return sum
}

func referenceFold(sum uint32) uint16 {
	for sum > 0xFFFF {
		sum = sum&0xFFFF + sum>>16
	}
	return uint16(sum)
}

func referencePseudoHeaderSum(packet []byte, transportOffset int, protocol uint8) uint32 {
	segmentByteCount := uint32(len(packet) - transportOffset)
	if packet[0]>>4 == 4 {
		return referenceSum(packet[12:20], 0) + uint32(protocol) + segmentByteCount
	}
	return referenceSum(packet[8:40], 0) + uint32(protocol) + segmentByteCount
}

func expectValidChecksums(t *testing.T, packet []byte, transportOffset int, protocol uint8) {
	t.Helper()
	if packet[0]>>4 == 4 && referenceFold(referenceSum(packet[:transportOffset], 0)) != 0xFFFF {
		t.Fatalf("the IPv4 header checksum is wrong")
	}
	checksum := binary.BigEndian.Uint16(packet[transportOffset+transportChecksumOffsetFor(protocol):])
	if protocol == protocolUDP && packet[0]>>4 == 4 && checksum == 0 {
		return
	}
	if referenceFold(referenceSum(packet[transportOffset:], referencePseudoHeaderSum(packet, transportOffset, protocol))) != 0xFFFF {
		t.Fatalf("the transport checksum is wrong")
	}
}

func ipv4PacketWithOptions(spec segmentSpec) []byte {
	plain := packetFor(spec)
	optionByteCount := testIPv4OptionWords * headerLengthUnitByteCount
	packet := append([]byte(nil), plain[:ipv4MinimumHeaderByteCount]...)
	packet = append(packet, make([]byte, optionByteCount)...)
	packet = append(packet, plain[ipv4MinimumHeaderByteCount:]...)
	packet[0] = testIPv4VersionAndIHL + testIPv4OptionWords
	binary.BigEndian.PutUint16(packet[2:], uint16(len(packet)))
	fillReferenceChecksums(packet, ipv4MinimumHeaderByteCount+optionByteCount, spec.protocol)
	return packet
}
