package servicerouting

import (
	"encoding/binary"
	"net/netip"
)

const (
	ipv4Version                = 4
	ipv4MinimumHeaderByteCount = 20
	udpHeaderByteCount         = 8
	tcpMinimumHeaderByteCount  = 20
	protocolTCP                = 6
	protocolUDP                = 17
	ipVersionShift             = 4
	ipv4HeaderLengthMask       = 0x0F
	headerLengthUnitByteCount  = 4
	ipv4TotalLengthOffset      = 2
	ipv4FragmentOffset         = 6
	ipv4FragmentOffsetMask     = 0x1FFF
	ipv4ProtocolOffset         = 9
	ipv4SourceOffset           = 12
	ipv4DestinationOffset      = 16
	sourcePortOffset           = 0
	destinationPortOffset      = 2
	udpLengthOffset            = 4
	portByteCount              = 2
)

func ipv4HeaderByteCount(packet []byte) (int, bool) {
	if len(packet) < ipv4MinimumHeaderByteCount || packet[0]>>ipVersionShift != ipv4Version {
		return 0, false
	}
	headerByteCount := int(packet[0]&ipv4HeaderLengthMask) * headerLengthUnitByteCount
	totalByteCount := int(binary.BigEndian.Uint16(packet[ipv4TotalLengthOffset:]))
	if headerByteCount < ipv4MinimumHeaderByteCount || totalByteCount < headerByteCount || totalByteCount > len(packet) {
		return 0, false
	}
	return headerByteCount, true
}

func sourceAddress(packet []byte) netip.Addr {
	return netip.AddrFrom4([ipv4AddressByteCount]byte(packet[ipv4SourceOffset:]))
}

func destinationAddress(packet []byte) netip.Addr {
	return netip.AddrFrom4([ipv4AddressByteCount]byte(packet[ipv4DestinationOffset:]))
}

func isFirstFragment(packet []byte) bool {
	return binary.BigEndian.Uint16(packet[ipv4FragmentOffset:])&ipv4FragmentOffsetMask == 0
}

func hasPort(packet []byte, headerByteCount int, offset int, port uint16) bool {
	return isFirstFragment(packet) && len(packet) >= headerByteCount+offset+portByteCount &&
		binary.BigEndian.Uint16(packet[headerByteCount+offset:]) == port
}

func replaceAddress(packet []byte, headerByteCount int, addressOffset int, replacement netip.Addr) {
	previous := [ipv4AddressByteCount]byte(packet[addressOffset:])
	next := replacement.As4()
	copy(packet[addressOffset:], next[:])
	refreshHeaderChecksum(packet)
	if isFirstFragment(packet) {
		adjustTransportChecksum(packet, headerByteCount, previous, next)
	}
}
