package servicerouting

import (
	"testing"

	"golang.org/x/net/dns/dnsmessage"
)

const segmentPayloadByteCount = 1360

func BenchmarkTranslatorRewritesAnOutboundSegment(b *testing.B) {
	translator := newTranslator(testPlan)
	template := tcpPacket(deviceAddress, translator.pool.fakeFor(realAddress), 50000, 443, make([]byte, segmentPayloadByteCount))
	packet := make([]byte, len(template))
	b.SetBytes(int64(len(template)))
	for b.Loop() {
		copy(packet, template)
		translator.outbound(packet)
	}
}

func BenchmarkTranslatorRewritesAnInboundSegment(b *testing.B) {
	translator := newTranslator(testPlan)
	translator.pool.fakeFor(realAddress)
	template := tcpPacket(realAddress, deviceAddress, 443, 50000, make([]byte, segmentPayloadByteCount))
	packet := make([]byte, len(template))
	b.SetBytes(int64(len(template)))
	for b.Loop() {
		copy(packet, template)
		translator.inbound(packet)
	}
}

func BenchmarkCopyingASegmentOnly(b *testing.B) {
	template := tcpPacket(deviceAddress, realAddress, 50000, 443, make([]byte, segmentPayloadByteCount))
	packet := make([]byte, len(template))
	b.SetBytes(int64(len(template)))
	for b.Loop() {
		copy(packet, template)
	}
}

func BenchmarkTranslatorRewritesADNSAnswer(b *testing.B) {
	translator := newTranslator(testPlan)
	response := dnsResponse(b, "api.ipify.org.", dnsmessage.TypeA, func(builder *dnsmessage.Builder) {
		builder.AResource(answerHeader("api.ipify.org.", dnsmessage.TypeA, 300), dnsmessage.AResource{A: realAddress.As4()})
	})
	template := udpPacket(testPlan.UpstreamDNS, deviceAddress, 53, 53000, response)
	packet := make([]byte, len(template))
	for b.Loop() {
		copy(packet, template)
		translator.inbound(packet)
	}
}
