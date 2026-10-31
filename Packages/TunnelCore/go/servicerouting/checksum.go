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
	byteShift                = 8
)

func replaceAddress(packet []byte, layout packetLayout, offset int, replacement netip.Addr) {
	var previous [ipv6AddressByteCount]byte
	address := packet[offset : offset+layout.addressByteCount]
	copy(previous[:], address)
	writeAddress(packet, layout, offset, replacement)
	delta := checksumDelta(previous[:layout.addressByteCount], address)
	if layout.isIPv4 {
		adjustChecksum(packet[ipv4HeaderChecksumOffset:], delta)
	}
	if layout.hasPorts {
		adjustTransportChecksum(packet, layout, delta)
	}
}

func writeAddress(packet []byte, layout packetLayout, offset int, address netip.Addr) {
	if layout.isIPv4 {
		bytes := address.As4()
		copy(packet[offset:], bytes[:])
		return
	}
	bytes := address.As16()
	copy(packet[offset:], bytes[:])
}

func refreshChecksums(packet []byte, layout packetLayout) {
	if layout.isIPv4 {
		binary.BigEndian.PutUint16(packet[ipv4HeaderChecksumOffset:], 0)
		binary.BigEndian.PutUint16(packet[ipv4HeaderChecksumOffset:], ^fold(onesComplementSum(packet[:layout.transportOffset], 0)))
	}
	offset := tcpChecksumOffset
	if layout.protocol == protocolUDP {
		offset = udpChecksumOffset
	}
	segment := packet[layout.transportOffset:layout.packetEnd]
	binary.BigEndian.PutUint16(segment[offset:], 0)
	addresses := packet[layout.sourceOffset : layout.destinationOffset+layout.addressByteCount]
	pseudoHeader := onesComplementSum(addresses, 0) + uint32(layout.protocol) + uint32(len(segment))
	checksum := ^fold(onesComplementSum(segment, pseudoHeader))
	if layout.protocol == protocolUDP && checksum == 0 {
		checksum = transmittedZeroChecksum
	}
	binary.BigEndian.PutUint16(segment[offset:], checksum)
}

func onesComplementSum(data []byte, initial uint32) uint32 {
	sum := initial
	for index := 0; index+1 < len(data); index += checksumWordByteCount {
		sum += uint32(binary.BigEndian.Uint16(data[index:]))
	}
	if len(data)%checksumWordByteCount == 1 {
		sum += uint32(data[len(data)-1]) << byteShift
	}
	return sum
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
