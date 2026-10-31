package servicerouting

import (
	"testing"
	"time"

	"golang.org/x/net/dns/dnsmessage"
)

func FuzzRewriterHandlesAnyMessage(f *testing.F) {
	addDNSFuzzSeeds(f)
	f.Fuzz(func(t *testing.T, message []byte) {
		pool := newRewriterPool(dualStackNetworks(), 4)

		rewritten, err := rewriteDNSResponse(message, pool)

		if err != nil {
			return
		}
		var parser dnsmessage.Parser
		if _, err := parser.Start(rewritten); err != nil {
			t.Fatalf("the rewritten message does not parse: %v", err)
		}
	})
}

func FuzzInterceptorHandlesAnyAnswer(f *testing.F) {
	addDNSFuzzSeeds(f)
	f.Fuzz(func(t *testing.T, message []byte) {
		clock := &manualClock{current: time.Unix(1_800_000_000, 0)}
		router := newServiceRouter(testPlan(), clock.now)
		client := port(deviceIPv4, testClientPort)
		identifier := byte(0)
		if len(message) > 1 {
			identifier = message[1]
		}
		query := dnsQuery(t, "api.example.com.", dnsmessage.TypeA)
		query[0], query[1] = firstByte(message), identifier
		router.outbound(packetFor(udpSpec(client, port(virtualDNS, dnsPort), query)))

		replacement, isDelivered := router.inbound(packetFor(udpSpec(port(upstreamDNS, dnsPort), client, message)))

		if isDelivered && replacement != nil {
			layout, isParsed := layoutOf(replacement)
			if !isParsed || !layout.hasPorts || layout.source(replacement) != virtualDNS {
				t.Fatalf("expected an answer from the virtual resolver, got %+v", layout)
			}
			expectValidChecksums(t, replacement, layout.transportOffset, protocolUDP)
		}
	})
}

func addDNSFuzzSeeds(f *testing.F) {
	f.Add(dnsResponse(f, "api.example.com.", dnsmessage.TypeA, []answerSpec{
		{name: "api.example.com.", kind: dnsmessage.TypeA, ttl: 300, address: realIPv4},
	}))
	f.Add(dnsResponse(f, "www.example.com.", dnsmessage.TypeAAAA, []answerSpec{
		{name: "www.example.com.", kind: dnsmessage.TypeCNAME, ttl: 300, target: "edge.cdn.example.net."},
		{name: "edge.cdn.example.net.", kind: dnsmessage.TypeAAAA, ttl: 30, address: realIPv6},
	}))
	f.Add(dnsResponse(f, "api.example.com.", httpsRecordTypeForTests, []answerSpec{
		{name: "api.example.com.", kind: httpsRecordTypeForTests, ttl: 300, rawBytes: []byte{0, 1, 0, 0, 4, 0, 4, 104, 26, 12, 205}},
	}))
	f.Add([]byte{0x42, 0x42, 0x81, 0x80})
}

func firstByte(message []byte) byte {
	if len(message) == 0 {
		return 0
	}
	return message[0]
}
