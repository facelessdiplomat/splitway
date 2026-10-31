package usernet

import (
	"encoding/binary"
	"net/netip"
)

const (
	testIPv4HeaderByteCount = 20
	testIPv6HeaderByteCount = 40
	testTCPHeaderByteCount  = 20
	tcpProtocolNumber       = 6
	udpProtocolNumber       = 17
	flagFin                 = 0x01
	flagSyn                 = 0x02
	flagReset               = 0x04
	flagPush                = 0x08
	flagAcknowledgement     = 0x10
	flagECNEcho             = 0x40
)

var (
	clientAddress4 = netip.MustParseAddr("10.0.0.1")
	serverAddress4 = netip.MustParseAddr("192.0.2.80")
	otherAddress4  = netip.MustParseAddr("192.0.2.81")
	clientAddress6 = netip.MustParseAddr("fd00::1")
	serverAddress6 = netip.MustParseAddr("2001:db8::80")
)

type testSegment struct {
	source          netip.Addr
	destination     netip.Addr
	sourcePort      uint16
	destinationPort uint16
	flags           byte
	acknowledgement uint32
	payloadLength   int
}

func pureAcknowledgement(acknowledgement uint32) testSegment {
	return testSegment{
		source: clientAddress4, destination: serverAddress4, sourcePort: 50000, destinationPort: 443,
		flags: flagAcknowledgement, acknowledgement: acknowledgement,
	}
}

func (segment testSegment) packet() []byte {
	tcp := make([]byte, testTCPHeaderByteCount+segment.payloadLength)
	binary.BigEndian.PutUint16(tcp[0:2], segment.sourcePort)
	binary.BigEndian.PutUint16(tcp[2:4], segment.destinationPort)
	binary.BigEndian.PutUint32(tcp[8:12], segment.acknowledgement)
	tcp[12] = (testTCPHeaderByteCount / 4) << 4
	tcp[13] = segment.flags
	binary.BigEndian.PutUint16(tcp[14:16], 4096)
	return ipPacket(segment.source, segment.destination, tcpProtocolNumber, tcp)
}

func ipPacket(source, destination netip.Addr, protocol byte, payload []byte) []byte {
	if source.Is6() {
		packet := make([]byte, testIPv6HeaderByteCount, testIPv6HeaderByteCount+len(payload))
		packet[0] = 6 << 4
		binary.BigEndian.PutUint16(packet[4:6], uint16(len(payload)))
		packet[6] = protocol
		packet[7] = 64
		sourceBytes, destinationBytes := source.As16(), destination.As16()
		copy(packet[8:24], sourceBytes[:])
		copy(packet[24:40], destinationBytes[:])
		return append(packet, payload...)
	}
	packet := make([]byte, testIPv4HeaderByteCount, testIPv4HeaderByteCount+len(payload))
	packet[0] = 4<<4 | testIPv4HeaderByteCount/4
	binary.BigEndian.PutUint16(packet[2:4], uint16(testIPv4HeaderByteCount+len(payload)))
	packet[8] = 64
	packet[9] = protocol
	sourceBytes, destinationBytes := source.As4(), destination.As4()
	copy(packet[12:16], sourceBytes[:])
	copy(packet[16:20], destinationBytes[:])
	return append(packet, payload...)
}
