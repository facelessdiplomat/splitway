package usernet

import (
	"encoding/binary"
	"net/netip"
)

const (
	ipv4Version                 = 4
	ipv6Version                 = 6
	ipv4MinimumHeaderByteCount  = 20
	ipv6HeaderByteCount         = 40
	tcpMinimumHeaderByteCount   = 20
	transportProtocolTCP        = 6
	ipv4FragmentMask            = 0x3FFF
	headerLengthUnitByteCount   = 4
	acknowledgementFlagOnly     = 0x10
	tcpDataOffsetShift          = 4
	ipv4HeaderLengthMask        = 0x0F
	ipVersionShift              = 4
	ipv4AddressByteCount        = 4
	ipv4SourceAddressOffset     = 12
	ipv4DestinationOffset       = 16
	ipv4TotalLengthOffset       = 2
	ipv4FragmentOffset          = 6
	ipv4ProtocolOffset          = 9
	ipv6PayloadLengthOffset     = 4
	ipv6NextHeaderOffset        = 6
	ipv6SourceAddressOffset     = 8
	ipv6DestinationOffset       = 24
	ipv6AddressByteCount        = 16
	tcpDestinationPortOffset    = 2
	tcpAcknowledgementOffset    = 8
	tcpDataOffsetOffset         = 12
	tcpFlagsOffset              = 13
	tcpPortByteCount            = 2
	tcpAcknowledgementByteCount = 4
)

type tcpFlow struct {
	source          netip.Addr
	destination     netip.Addr
	sourcePort      uint16
	destinationPort uint16
}

type tcpSegment struct {
	flow                  tcpFlow
	acknowledgement       uint32
	isPureAcknowledgement bool
}

func parseTCPSegment(packet []byte) (tcpSegment, bool) {
	if len(packet) == 0 {
		return tcpSegment{}, false
	}
	switch packet[0] >> ipVersionShift {
	case ipv4Version:
		return parseIPv4TCPSegment(packet)
	case ipv6Version:
		return parseIPv6TCPSegment(packet)
	}
	return tcpSegment{}, false
}

func parseIPv4TCPSegment(packet []byte) (tcpSegment, bool) {
	if len(packet) < ipv4MinimumHeaderByteCount {
		return tcpSegment{}, false
	}
	headerByteCount := int(packet[0]&ipv4HeaderLengthMask) * headerLengthUnitByteCount
	totalByteCount := int(binary.BigEndian.Uint16(packet[ipv4TotalLengthOffset:]))
	isFragment := binary.BigEndian.Uint16(packet[ipv4FragmentOffset:])&ipv4FragmentMask != 0
	if headerByteCount < ipv4MinimumHeaderByteCount || totalByteCount < headerByteCount ||
		totalByteCount > len(packet) || isFragment || packet[ipv4ProtocolOffset] != transportProtocolTCP {
		return tcpSegment{}, false
	}
	source := netip.AddrFrom4([ipv4AddressByteCount]byte(packet[ipv4SourceAddressOffset:]))
	destination := netip.AddrFrom4([ipv4AddressByteCount]byte(packet[ipv4DestinationOffset:]))
	return parseTCPHeader(packet[headerByteCount:totalByteCount], source, destination)
}

func parseIPv6TCPSegment(packet []byte) (tcpSegment, bool) {
	if len(packet) < ipv6HeaderByteCount || packet[ipv6NextHeaderOffset] != transportProtocolTCP {
		return tcpSegment{}, false
	}
	payloadByteCount := int(binary.BigEndian.Uint16(packet[ipv6PayloadLengthOffset:]))
	if ipv6HeaderByteCount+payloadByteCount > len(packet) {
		return tcpSegment{}, false
	}
	source := netip.AddrFrom16([ipv6AddressByteCount]byte(packet[ipv6SourceAddressOffset:]))
	destination := netip.AddrFrom16([ipv6AddressByteCount]byte(packet[ipv6DestinationOffset:]))
	return parseTCPHeader(packet[ipv6HeaderByteCount:ipv6HeaderByteCount+payloadByteCount], source, destination)
}

func parseTCPHeader(segment []byte, source, destination netip.Addr) (tcpSegment, bool) {
	if len(segment) < tcpMinimumHeaderByteCount {
		return tcpSegment{}, false
	}
	headerByteCount := int(segment[tcpDataOffsetOffset]>>tcpDataOffsetShift) * headerLengthUnitByteCount
	if headerByteCount < tcpMinimumHeaderByteCount || headerByteCount > len(segment) {
		return tcpSegment{}, false
	}
	return tcpSegment{
		flow: tcpFlow{
			source:          source,
			destination:     destination,
			sourcePort:      binary.BigEndian.Uint16(segment),
			destinationPort: binary.BigEndian.Uint16(segment[tcpDestinationPortOffset:]),
		},
		acknowledgement:       binary.BigEndian.Uint32(segment[tcpAcknowledgementOffset:]),
		isPureAcknowledgement: segment[tcpFlagsOffset] == acknowledgementFlagOnly && len(segment) == headerByteCount,
	}, true
}
