package servicerouting

import "encoding/binary"

const (
	ipv4HeaderChecksumOffset = 10
	udpChecksumOffset        = 6
	tcpChecksumOffset        = 16
	ipv4AddressByteCount     = 4
	checksumWordByteCount    = 2
	foldedSumMask            = 0xFFFF
	foldShift                = 16
	byteShift                = 8
	transmittedZeroChecksum  = 0xFFFF
)

func checksum(data []byte, initial uint32) uint16 {
	sum := initial
	for index := 0; index+1 < len(data); index += checksumWordByteCount {
		sum += uint32(binary.BigEndian.Uint16(data[index:]))
	}
	if len(data)%checksumWordByteCount == 1 {
		sum += uint32(data[len(data)-1]) << byteShift
	}
	return ^fold(sum)
}

func pseudoHeaderSum(packet []byte, segmentByteCount int) uint32 {
	var sum uint32
	for index := ipv4SourceOffset; index < ipv4DestinationOffset+ipv4AddressByteCount; index += checksumWordByteCount {
		sum += uint32(binary.BigEndian.Uint16(packet[index:]))
	}
	return sum + uint32(packet[ipv4ProtocolOffset]) + uint32(segmentByteCount)
}

func refreshHeaderChecksum(packet []byte) {
	headerByteCount := int(packet[0]&ipv4HeaderLengthMask) * headerLengthUnitByteCount
	binary.BigEndian.PutUint16(packet[ipv4HeaderChecksumOffset:], 0)
	binary.BigEndian.PutUint16(packet[ipv4HeaderChecksumOffset:], checksum(packet[:headerByteCount], 0))
}

func refreshTransportChecksum(packet []byte) {
	headerByteCount := int(packet[0]&ipv4HeaderLengthMask) * headerLengthUnitByteCount
	segment := packet[headerByteCount:]
	offset, ok := transportChecksumOffset(packet[ipv4ProtocolOffset])
	if !ok || len(segment) < offset+checksumWordByteCount {
		return
	}
	binary.BigEndian.PutUint16(segment[offset:], 0)
	value := checksum(segment, pseudoHeaderSum(packet, len(segment)))
	if packet[ipv4ProtocolOffset] == protocolUDP && value == 0 {
		value = transmittedZeroChecksum
	}
	binary.BigEndian.PutUint16(segment[offset:], value)
}

func adjustTransportChecksum(packet []byte, headerByteCount int, previous, replacement [ipv4AddressByteCount]byte) {
	offset, ok := transportChecksumOffset(packet[ipv4ProtocolOffset])
	segment := packet[headerByteCount:]
	if !ok || len(segment) < offset+checksumWordByteCount {
		return
	}
	current := binary.BigEndian.Uint16(segment[offset:])
	if packet[ipv4ProtocolOffset] == protocolUDP && current == 0 {
		return
	}
	sum := uint32(^current)
	for index := 0; index < ipv4AddressByteCount; index += checksumWordByteCount {
		sum += uint32(^binary.BigEndian.Uint16(previous[index:]))
		sum += uint32(binary.BigEndian.Uint16(replacement[index:]))
	}
	value := ^fold(sum)
	if packet[ipv4ProtocolOffset] == protocolUDP && value == 0 {
		value = transmittedZeroChecksum
	}
	binary.BigEndian.PutUint16(segment[offset:], value)
}

func transportChecksumOffset(protocol byte) (int, bool) {
	switch protocol {
	case protocolTCP:
		return tcpChecksumOffset, true
	case protocolUDP:
		return udpChecksumOffset, true
	}
	return 0, false
}

func fold(sum uint32) uint16 {
	for sum > foldedSumMask {
		sum = sum>>foldShift + sum&foldedSumMask
	}
	return uint16(sum)
}
