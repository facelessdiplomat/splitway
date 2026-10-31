package servicerouting

import (
	"encoding/binary"
	"net/netip"
)

const (
	ipv4HeaderChecksumOffset = 10
	tcpChecksumOffset        = 16
	udpChecksumOffset        = 6
	checksumWordByteCount    = 2
	transmittedZeroChecksum  = 0xFFFF
	foldedSumMask            = 0xFFFF
	foldShift                = 16
)

func replaceAddress(packet []byte, layout packetLayout, offset int, replacement netip.Addr) {
	var previous [ipv6AddressByteCount]byte
	address := packet[offset : offset+layout.addressByteCount]
	copy(previous[:], address)
	if layout.isIPv4 {
		next := replacement.As4()
		copy(address, next[:])
	} else {
		next := replacement.As16()
		copy(address, next[:])
	}
	delta := checksumDelta(previous[:layout.addressByteCount], address)
	if layout.isIPv4 {
		adjustChecksum(packet[ipv4HeaderChecksumOffset:], delta)
	}
	if layout.hasPorts {
		adjustTransportChecksum(packet, layout, delta)
	}
}

func checksumDelta(previous, replacement []byte) uint32 {
	var delta uint32
	for index := 0; index < len(previous); index += checksumWordByteCount {
		delta += uint32(^binary.BigEndian.Uint16(previous[index:])) + uint32(binary.BigEndian.Uint16(replacement[index:]))
	}
	return delta
}

func adjustTransportChecksum(packet []byte, layout packetLayout, delta uint32) {
	switch layout.protocol {
	case protocolTCP:
		adjustChecksum(packet[layout.transportOffset+tcpChecksumOffset:], delta)
	case protocolUDP:
		field := packet[layout.transportOffset+udpChecksumOffset:]
		if binary.BigEndian.Uint16(field) == 0 {
			return
		}
		if adjustChecksum(field, delta) == 0 {
			binary.BigEndian.PutUint16(field, transmittedZeroChecksum)
		}
	}
}

func adjustChecksum(field []byte, delta uint32) uint16 {
	adjusted := ^fold(uint32(^binary.BigEndian.Uint16(field)) + delta)
	binary.BigEndian.PutUint16(field, adjusted)
	return adjusted
}

func fold(sum uint32) uint16 {
	for sum > foldedSumMask {
		sum = sum&foldedSumMask + sum>>foldShift
	}
	return uint16(sum)
}
