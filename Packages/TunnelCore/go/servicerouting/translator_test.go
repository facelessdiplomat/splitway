package servicerouting

import (
	"bytes"
	"net/netip"
	"testing"

	"golang.org/x/net/dns/dnsmessage"
)

var unrelatedAddress = netip.MustParseAddr("93.184.216.34")

func TestTranslatorSendsAQueryForTheVirtualResolverToTheUpstreamResolver(t *testing.T) {
	translator := newTranslator(testPlan)
	packet := udpPacket(deviceAddress, testPlan.VirtualDNS, 53000, 53, dnsQuery(t, "api.ipify.org.", dnsmessage.TypeA))

	isKept := translator.outbound(packet)

	if !isKept || destinationOf(packet) != testPlan.UpstreamDNS {
		t.Fatalf("expected the query to go to %v, got %v kept=%v", testPlan.UpstreamDNS, destinationOf(packet), isKept)
	}
	expectValidChecksums(t, packet)
}

func TestTranslatorAnswersFromTheVirtualResolverWithFakeAddresses(t *testing.T) {
	translator := newTranslator(testPlan)
	response := dnsResponse(t, "api.ipify.org.", dnsmessage.TypeA, func(builder *dnsmessage.Builder) {
		builder.AResource(answerHeader("api.ipify.org.", dnsmessage.TypeA, 300), dnsmessage.AResource{A: realAddress.As4()})
	})

	translated, isReplaced := translator.inbound(udpPacket(testPlan.UpstreamDNS, deviceAddress, 53, 53000, response))

	if !isReplaced || sourceOf(translated) != testPlan.VirtualDNS {
		t.Fatalf("expected the answer from %v, got %v", testPlan.VirtualDNS, sourceOf(translated))
	}
	expectValidChecksums(t, translated)
	var parser dnsmessage.Parser
	parser.Start(udpPayloadOf(translated))
	parser.SkipAllQuestions()
	answers, err := parser.AllAnswers()
	if err != nil || len(answers) != 1 {
		t.Fatalf("expected one answer, got %v %v", answers, err)
	}
	if address := answers[0].Body.(*dnsmessage.AResource); netip.AddrFrom4(address.A) != translator.pool.fakeFor(realAddress) {
		t.Fatalf("expected the fake address of %v, got %v", realAddress, address)
	}
}

func TestTranslatorSendsTrafficForAFakeAddressToTheRealOne(t *testing.T) {
	translator := newTranslator(testPlan)
	fake := translator.pool.fakeFor(realAddress)
	packet := tcpPacket(deviceAddress, fake, 50000, 443, []byte("hello"))

	isKept := translator.outbound(packet)

	if !isKept || destinationOf(packet) != realAddress {
		t.Fatalf("expected the segment to go to %v, got %v", realAddress, destinationOf(packet))
	}
	expectValidChecksums(t, packet)
}

func TestTranslatorReturnsRepliesFromTheFakeAddress(t *testing.T) {
	translator := newTranslator(testPlan)
	fake := translator.pool.fakeFor(realAddress)

	translated, _ := translator.inbound(tcpPacket(realAddress, deviceAddress, 443, 50000, []byte("world")))

	if sourceOf(translated) != fake {
		t.Fatalf("expected the reply from %v, got %v", fake, sourceOf(translated))
	}
	expectValidChecksums(t, translated)
}

func TestTranslatorDropsTrafficForAFakeAddressItNeverGaveOut(t *testing.T) {
	packet := tcpPacket(deviceAddress, netip.MustParseAddr("198.19.200.1"), 50000, 443, nil)

	if newTranslator(testPlan).outbound(packet) {
		t.Fatal("expected the segment to an unknown fake address to be dropped")
	}
}

func TestTranslatorLeavesOtherTrafficAlone(t *testing.T) {
	translator := newTranslator(testPlan)
	outgoing := tcpPacket(deviceAddress, unrelatedAddress, 50000, 443, []byte("x"))
	original := bytes.Clone(outgoing)

	isKept := translator.outbound(outgoing)
	reply, isReplaced := translator.inbound(tcpPacket(unrelatedAddress, deviceAddress, 443, 50000, []byte("y")))

	if !isKept || !bytes.Equal(outgoing, original) {
		t.Fatal("expected unrelated outgoing traffic to stay unchanged")
	}
	if isReplaced || sourceOf(reply) != unrelatedAddress {
		t.Fatal("expected unrelated incoming traffic to stay unchanged")
	}
}
