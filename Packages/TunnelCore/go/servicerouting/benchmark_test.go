package servicerouting

import "testing"

const segmentPayloadByteCount = 1360

func BenchmarkTranslatorRewritesAnOutboundSegment(b *testing.B) {
	fixture := newTranslatorFixture(maximumTrackedConnections)
	template := packetFor(tcpSpec(port(deviceIPv4, 50000), port(fakeIPv4, 443), tcpFlagACK, make([]byte, segmentPayloadByteCount)))
	benchmarkTranslation(b, template, func(packet []byte) { fixture.translator.outbound(packet) })
}

func BenchmarkTranslatorRewritesAnInboundSegment(b *testing.B) {
	fixture := newTranslatorFixture(maximumTrackedConnections)
	fixture.translator.outbound(packetFor(tcpSpec(port(deviceIPv4, 50000), port(fakeIPv4, 443), tcpFlagSYN, nil)))
	template := packetFor(tcpSpec(port(realIPv4, 443), port(deviceIPv4, 50000), tcpFlagACK, make([]byte, segmentPayloadByteCount)))
	benchmarkTranslation(b, template, fixture.translator.inbound)
}

func BenchmarkTranslatorRewritesAnOutboundIPv6Segment(b *testing.B) {
	fixture := newTranslatorFixture(maximumTrackedConnections)
	template := packetFor(tcpSpec(port(deviceIPv6, 50000), port(fakeIPv6, 443), tcpFlagACK, make([]byte, segmentPayloadByteCount)))
	benchmarkTranslation(b, template, func(packet []byte) { fixture.translator.outbound(packet) })
}

func BenchmarkTranslatorOpensConnectionsInAFullTable(b *testing.B) {
	fixture := newTranslatorFixture(maximumTrackedConnections)
	templates := make([][]byte, 2*maximumTrackedConnections)
	for index := range templates {
		templates[index] = packetFor(udpSpec(port(deviceIPv4, uint16(10000+index)), port(fakeIPv4, 443), nil))
	}
	packet := make([]byte, len(templates[0]))
	b.ReportAllocs()
	index := 0
	for b.Loop() {
		copy(packet, templates[index%len(templates)])
		fixture.translator.outbound(packet)
		index++
	}
}

func BenchmarkCopyingASegment(b *testing.B) {
	template := packetFor(tcpSpec(port(deviceIPv4, 50000), port(realIPv4, 443), tcpFlagACK, make([]byte, segmentPayloadByteCount)))
	benchmarkTranslation(b, template, func([]byte) {})
}

func benchmarkTranslation(b *testing.B, template []byte, translate func([]byte)) {
	packet := make([]byte, len(template))
	b.SetBytes(int64(len(template)))
	b.ReportAllocs()
	for b.Loop() {
		copy(packet, template)
		translate(packet)
	}
}
