package servicerouting

import (
	"encoding/binary"
	"net/netip"
)

const (
	ipv4Version                       = 4
	ipv6Version                       = 6
	ipVersionShift                    = 4
	ipv4MinimumHeaderByteCount        = 20
	ipv4HeaderLengthMask              = 0x0F
	headerLengthUnitByteCount         = 4
	ipv4TotalLengthOffset             = 2
	ipv4FragmentOffset                = 6
	ipv4FragmentOffsetMask            = 0x1FFF
	ipv4ProtocolOffset                = 9
	ipv4SourceOffset                  = 12
	ipv4DestinationOffset             = 16
	ipv4AddressByteCount              = 4
	ipv6HeaderByteCount               = 40
	ipv6PayloadLengthOffset           = 4
	ipv6NextHeaderOffset              = 6
	ipv6SourceOffset                  = 8
	ipv6DestinationOffset             = 24
	ipv6AddressByteCount              = 16
	extensionHeaderMinimumByteCount   = 8
	extensionLengthOffset             = 1
	extensionLengthUnitByteCount      = 8
	authenticationLengthUnitByteCount = 4
	authenticationLengthBias          = 2
	fragmentOffsetField               = 2
	fragmentOffsetShift               = 3
	maximumExtensionHeaderCount       = 8
	tcpMinimumHeaderByteCount         = 20
	tcpDataOffsetOffset               = 12
	tcpDataOffsetShift                = 4
	tcpFlagsOffset                    = 13
	udpHeaderByteCount                = 8
	sourcePortOffset                  = 0
	destinationPortOffset             = 2
	protocolTCP                       = 6
	protocolUDP                       = 17
	hopByHopOptionsHeader             = 0
	routingHeader                     = 43
	fragmentHeader                    = 44
	authenticationHeader              = 51
	noNextHeader                      = 59
	destinationOptionsHeader          = 60
	tcpFlagFIN                        = 0x01
	tcpFlagSYN                        = 0x02
	tcpFlagRST                        = 0x04
	tcpFlagACK                        = 0x10
)

type packetLayout struct {
	isIPv4            bool
	addressByteCount  int
	sourceOffset      int
	destinationOffset int
	transportOffset   int
	packetEnd         int
	protocol          uint8
	isLaterFragment   bool
	hasPorts          bool
}

func layoutOf(packet []byte) (packetLayout, bool) {
	if len(packet) == 0 {
		return packetLayout{}, false
	}
	switch packet[0] >> ipVersionShift {
	case ipv4Version:
		return ipv4LayoutOf(packet)
	case ipv6Version:
		return ipv6LayoutOf(packet)
	}
	return packetLayout{}, false
}

func ipv4LayoutOf(packet []byte) (packetLayout, bool) {
	if len(packet) < ipv4MinimumHeaderByteCount {
		return packetLayout{}, false
	}
	headerByteCount := int(packet[0]&ipv4HeaderLengthMask) * headerLengthUnitByteCount
	packetEnd := int(binary.BigEndian.Uint16(packet[ipv4TotalLengthOffset:]))
	if headerByteCount < ipv4MinimumHeaderByteCount || packetEnd < headerByteCount || packetEnd > len(packet) {
		return packetLayout{}, false
	}
	layout := packetLayout{
		isIPv4:            true,
		addressByteCount:  ipv4AddressByteCount,
		sourceOffset:      ipv4SourceOffset,
		destinationOffset: ipv4DestinationOffset,
		transportOffset:   headerByteCount,
		packetEnd:         packetEnd,
		protocol:          packet[ipv4ProtocolOffset],
		isLaterFragment:   binary.BigEndian.Uint16(packet[ipv4FragmentOffset:])&ipv4FragmentOffsetMask != 0,
	}
	layout.hasPorts = !layout.isLaterFragment && layout.hasTransportHeader(packet)
	return layout, true
}

func ipv6LayoutOf(packet []byte) (packetLayout, bool) {
	if len(packet) < ipv6HeaderByteCount {
		return packetLayout{}, false
	}
	packetEnd := ipv6HeaderByteCount + int(binary.BigEndian.Uint16(packet[ipv6PayloadLengthOffset:]))
	if packetEnd > len(packet) {
		return packetLayout{}, false
	}
	layout := packetLayout{
		addressByteCount:  ipv6AddressByteCount,
		sourceOffset:      ipv6SourceOffset,
		destinationOffset: ipv6DestinationOffset,
		transportOffset:   ipv6HeaderByteCount,
		packetEnd:         packetEnd,
		protocol:          packet[ipv6NextHeaderOffset],
	}
	isChainComplete := layout.skipExtensionHeaders(packet)
	layout.hasPorts = isChainComplete && !layout.isLaterFragment && layout.hasTransportHeader(packet)
	return layout, true
}

func (layout *packetLayout) skipExtensionHeaders(packet []byte) bool {
	for range maximumExtensionHeaderCount {
		var headerByteCount int
		switch layout.protocol {
		case hopByHopOptionsHeader, routingHeader, destinationOptionsHeader:
			if !layout.fits(extensionHeaderMinimumByteCount) {
				return false
			}
			headerByteCount = (int(packet[layout.transportOffset+extensionLengthOffset]) + 1) * extensionLengthUnitByteCount
		case fragmentHeader:
			if !layout.fits(extensionHeaderMinimumByteCount) {
				return false
			}
			layout.isLaterFragment = binary.BigEndian.Uint16(packet[layout.transportOffset+fragmentOffsetField:])>>fragmentOffsetShift != 0
			headerByteCount = extensionHeaderMinimumByteCount
		case authenticationHeader:
			if !layout.fits(extensionHeaderMinimumByteCount) {
				return false
			}
			headerByteCount = (int(packet[layout.transportOffset+extensionLengthOffset]) + authenticationLengthBias) * authenticationLengthUnitByteCount
		default:
			return true
		}
		if !layout.fits(headerByteCount) {
			return false
		}
		layout.protocol = packet[layout.transportOffset]
		layout.transportOffset += headerByteCount
		if layout.isLaterFragment {
			return true
		}
	}
	return false
}

func (layout packetLayout) fits(byteCount int) bool {
	return layout.transportOffset+byteCount <= layout.packetEnd
}

func (layout packetLayout) hasTransportHeader(packet []byte) bool {
	switch layout.protocol {
	case protocolTCP:
		if !layout.fits(tcpMinimumHeaderByteCount) {
			return false
		}
		dataOffset := int(packet[layout.transportOffset+tcpDataOffsetOffset]>>tcpDataOffsetShift) * headerLengthUnitByteCount
		return dataOffset >= tcpMinimumHeaderByteCount && layout.fits(dataOffset)
	case protocolUDP:
		return layout.fits(udpHeaderByteCount)
	}
	return false
}

func (layout packetLayout) source(packet []byte) netip.Addr {
	return layout.addressAt(packet, layout.sourceOffset)
}

func (layout packetLayout) destination(packet []byte) netip.Addr {
	return layout.addressAt(packet, layout.destinationOffset)
}

func (layout packetLayout) addressAt(packet []byte, offset int) netip.Addr {
	if layout.isIPv4 {
		return netip.AddrFrom4([ipv4AddressByteCount]byte(packet[offset:]))
	}
	return netip.AddrFrom16([ipv6AddressByteCount]byte(packet[offset:]))
}

func (layout packetLayout) sourcePort(packet []byte) uint16 {
	return binary.BigEndian.Uint16(packet[layout.transportOffset+sourcePortOffset:])
}

func (layout packetLayout) destinationPort(packet []byte) uint16 {
	return binary.BigEndian.Uint16(packet[layout.transportOffset+destinationPortOffset:])
}

func (layout packetLayout) tcpFlags(packet []byte) uint8 {
	return packet[layout.transportOffset+tcpFlagsOffset]
}
