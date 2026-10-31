package servicerouting

import (
	"encoding/binary"
	"net/netip"
	"testing"

	"golang.org/x/net/dns/dnsmessage"
)

var (
	testPlan = Plan{
		VirtualDNS:  netip.MustParseAddr("198.18.0.2"),
		FakeNetwork: netip.MustParsePrefix("198.18.0.0/15"),
		UpstreamDNS: netip.MustParseAddr("1.1.1.1"),
	}
	deviceAddress = netip.MustParseAddr("10.14.0.2")
	realAddress   = netip.MustParseAddr("104.26.12.205")
)

func udpPacket(source, destination netip.Addr, sourcePort, destinationPort uint16, payload []byte) []byte {
	udp := make([]byte, udpHeaderByteCount+len(payload))
	binary.BigEndian.PutUint16(udp[0:2], sourcePort)
	binary.BigEndian.PutUint16(udp[2:4], destinationPort)
	binary.BigEndian.PutUint16(udp[4:6], uint16(len(udp)))
	copy(udp[udpHeaderByteCount:], payload)
	packet := ipv4Packet(source, destination, protocolUDP, udp)
	refreshTransportChecksum(packet)
	return packet
}

func tcpPacket(source, destination netip.Addr, sourcePort, destinationPort uint16, payload []byte) []byte {
	tcp := make([]byte, tcpMinimumHeaderByteCount+len(payload))
	binary.BigEndian.PutUint16(tcp[0:2], sourcePort)
	binary.BigEndian.PutUint16(tcp[2:4], destinationPort)
	tcp[12] = (tcpMinimumHeaderByteCount / 4) << 4
	tcp[13] = 0x18
	copy(tcp[tcpMinimumHeaderByteCount:], payload)
	packet := ipv4Packet(source, destination, protocolTCP, tcp)
	refreshTransportChecksum(packet)
	return packet
}

func ipv4Packet(source, destination netip.Addr, protocol byte, payload []byte) []byte {
	packet := make([]byte, ipv4MinimumHeaderByteCount, ipv4MinimumHeaderByteCount+len(payload))
	packet[0] = 0x45
	binary.BigEndian.PutUint16(packet[2:4], uint16(ipv4MinimumHeaderByteCount+len(payload)))
	packet[8] = 64
	packet[9] = protocol
	sourceBytes, destinationBytes := source.As4(), destination.As4()
	copy(packet[12:16], sourceBytes[:])
	copy(packet[16:20], destinationBytes[:])
	packet = append(packet, payload...)
	refreshHeaderChecksum(packet)
	return packet
}

func dnsQuery(t testing.TB, name string, questionType dnsmessage.Type) []byte {
	t.Helper()
	builder := dnsmessage.NewBuilder(nil, dnsmessage.Header{ID: 0x4242, RecursionDesired: true})
	builder.StartQuestions()
	builder.Question(dnsmessage.Question{Name: dnsmessage.MustNewName(name), Type: questionType, Class: dnsmessage.ClassINET})
	message, err := builder.Finish()
	if err != nil {
		t.Fatal(err)
	}
	return message
}

func dnsResponse(t testing.TB, name string, questionType dnsmessage.Type, build func(*dnsmessage.Builder)) []byte {
	t.Helper()
	builder := dnsmessage.NewBuilder(nil, dnsmessage.Header{ID: 0x4242, Response: true, RecursionDesired: true, RecursionAvailable: true})
	builder.EnableCompression()
	builder.StartQuestions()
	builder.Question(dnsmessage.Question{Name: dnsmessage.MustNewName(name), Type: questionType, Class: dnsmessage.ClassINET})
	builder.StartAnswers()
	build(&builder)
	message, err := builder.Finish()
	if err != nil {
		t.Fatal(err)
	}
	return message
}

func answerHeader(name string, answerType dnsmessage.Type, timeToLive uint32) dnsmessage.ResourceHeader {
	return dnsmessage.ResourceHeader{Name: dnsmessage.MustNewName(name), Type: answerType, Class: dnsmessage.ClassINET, TTL: timeToLive}
}

func expectValidChecksums(t *testing.T, packet []byte) {
	t.Helper()
	if checksum(packet[:ipv4MinimumHeaderByteCount], 0) != 0 {
		t.Fatal("the IPv4 header checksum is wrong")
	}
	headerByteCount := int(packet[0]&0x0F) * 4
	segment := packet[headerByteCount:]
	if packet[9] == protocolUDP && binary.BigEndian.Uint16(segment[6:8]) == 0 {
		return
	}
	if checksum(segment, pseudoHeaderSum(packet, len(segment))) != 0 {
		t.Fatal("the transport checksum is wrong")
	}
}

func sourceOf(packet []byte) netip.Addr {
	return netip.AddrFrom4([4]byte(packet[12:16]))
}

func destinationOf(packet []byte) netip.Addr {
	return netip.AddrFrom4([4]byte(packet[16:20]))
}

func udpPayloadOf(packet []byte) []byte {
	headerByteCount := int(packet[0]&0x0F) * 4
	return packet[headerByteCount+udpHeaderByteCount:]
}
