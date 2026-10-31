package servicerouting

import (
	"net/netip"
	"testing"

	"golang.org/x/net/dns/dnsmessage"
)

func FuzzTranslatorAcceptsAnyPacket(f *testing.F) {
	response := dnsResponse(f, "api.ipify.org.", dnsmessage.TypeA, func(builder *dnsmessage.Builder) {
		builder.AResource(answerHeader("api.ipify.org.", dnsmessage.TypeA, 300), dnsmessage.AResource{A: realAddress.As4()})
	})
	f.Add(udpPacket(testPlan.UpstreamDNS, deviceAddress, 53, 53000, response))
	f.Add(udpPacket(deviceAddress, testPlan.VirtualDNS, 53000, 53, dnsQuery(f, "api.ipify.org.", dnsmessage.TypeA)))
	f.Add(tcpPacket(deviceAddress, netip.MustParseAddr("198.18.1.0"), 50000, 443, []byte("hello")))
	f.Add(tcpPacket(realAddress, deviceAddress, 443, 50000, []byte("hello")))
	f.Fuzz(func(t *testing.T, packet []byte) {
		translator := newTranslator(testPlan)
		translator.pool.fakeFor(realAddress)

		translator.outbound(append([]byte(nil), packet...))
		translator.inbound(append([]byte(nil), packet...))
	})
}
