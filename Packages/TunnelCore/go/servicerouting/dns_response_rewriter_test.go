package servicerouting

import (
	"net/netip"
	"testing"

	"golang.org/x/net/dns/dnsmessage"
)

const (
	httpsRecordTypeForTests dnsmessage.Type = 65
	svcbRecordTypeForTests  dnsmessage.Type = 64
)

func newRewriterPool(networks fakeNetworks, capacity int) *fakeAddressPool {
	pool, _ := newPoolFixture(capacity, networks)
	return pool
}

func TestRewriterAnswersWithTheFakeAddressOfTheQueriedName(t *testing.T) {
	pool := newRewriterPool(dualStackNetworks(), maximumFakeAddresses)
	response := dnsResponse(t, "api.example.com.", dnsmessage.TypeA, []answerSpec{
		{name: "api.example.com.", kind: dnsmessage.TypeA, ttl: 300, address: realIPv4},
	})

	rewritten, err := rewriteDNSResponse(response, pool)

	mustBuild(t, err)
	parsed := parseResponse(t, rewritten)
	fake, _ := pool.fakeFor("api.example.com.", realIPv4)
	if len(parsed.answers) != 1 || addressOf(parsed.answers[0]) != fake || parsed.answers[0].Header.TTL != maximumAnswerTimeToLive {
		t.Fatalf("expected one answer %v with TTL %d, got %+v", fake, maximumAnswerTimeToLive, parsed.answers)
	}
	if parsed.header.ID != testQueryIdentifier || !parsed.header.Response {
		t.Fatalf("expected the response header to stay, got %+v", parsed.header)
	}
}

func TestRewriterFlattensACNAMEChainIntoTheQueriedName(t *testing.T) {
	pool := newRewriterPool(dualStackNetworks(), maximumFakeAddresses)
	response := dnsResponse(t, "www.example.com.", dnsmessage.TypeA, []answerSpec{
		{name: "www.example.com.", kind: dnsmessage.TypeCNAME, ttl: 3600, target: "edge.cdn.example.net."},
		{name: "edge.cdn.example.net.", kind: dnsmessage.TypeA, ttl: 20, address: realIPv4},
		{name: "edge.cdn.example.net.", kind: dnsmessage.TypeA, ttl: 20, address: otherRealIPv4},
	})

	rewritten, err := rewriteDNSResponse(response, pool)

	mustBuild(t, err)
	parsed := parseResponse(t, rewritten)
	fake, _ := pool.fakeFor("www.example.com.", realIPv4)
	if len(parsed.answers) != 1 || addressOf(parsed.answers[0]) != fake ||
		parsed.answers[0].Header.Name.String() != "www.example.com." || parsed.answers[0].Header.TTL != 20 {
		t.Fatalf("expected only the fake address of the queried name, got %+v", parsed.answers)
	}
}

func TestRewriterAnswersAAAAWithNothingWithoutIPv6(t *testing.T) {
	pool := newRewriterPool(fakeNetworks{ipv4: fakeIPv4s}, maximumFakeAddresses)
	response := dnsResponse(t, "www.example.com.", dnsmessage.TypeAAAA, []answerSpec{
		{name: "www.example.com.", kind: dnsmessage.TypeCNAME, ttl: 30, target: "edge.cdn.example.net."},
		{name: "edge.cdn.example.net.", kind: dnsmessage.TypeAAAA, ttl: 30, address: realIPv6},
	})

	rewritten, err := rewriteDNSResponse(response, pool)

	mustBuild(t, err)
	parsed := parseResponse(t, rewritten)
	if parsed.header.RCode != dnsmessage.RCodeSuccess || len(parsed.answers) != 0 {
		t.Fatalf("expected an empty answer without the CNAME and no error, got %v %+v", parsed.header.RCode, parsed.answers)
	}
}

func TestRewriterAnswersOtherRecordsOfAChainForTheQueriedName(t *testing.T) {
	pool := newRewriterPool(dualStackNetworks(), maximumFakeAddresses)
	response := dnsResponse(t, "www.example.com.", dnsmessage.TypeTXT, []answerSpec{
		{name: "www.example.com.", kind: dnsmessage.TypeCNAME, ttl: 30, target: "edge.cdn.example.net."},
		{name: "edge.cdn.example.net.", kind: dnsmessage.TypeTXT, ttl: 30, text: "edge"},
	})

	rewritten, err := rewriteDNSResponse(response, pool)

	mustBuild(t, err)
	parsed := parseResponse(t, rewritten)
	if len(parsed.answers) != 1 || parsed.answers[0].Header.Type != dnsmessage.TypeTXT ||
		parsed.answers[0].Header.Name.String() != "www.example.com." {
		t.Fatalf("expected the TXT record for the queried name without the CNAME, got %+v", parsed.answers)
	}
}

func TestRewriterAnswersAAAAWithAFakeIPv6Address(t *testing.T) {
	pool := newRewriterPool(dualStackNetworks(), maximumFakeAddresses)
	response := dnsResponse(t, "api.example.com.", dnsmessage.TypeAAAA, []answerSpec{
		{name: "api.example.com.", kind: dnsmessage.TypeAAAA, ttl: 30, address: realIPv6},
	})

	rewritten, err := rewriteDNSResponse(response, pool)

	mustBuild(t, err)
	parsed := parseResponse(t, rewritten)
	fake, _ := pool.fakeFor("api.example.com.", realIPv6)
	if len(parsed.answers) != 1 || addressOf(parsed.answers[0]) != fake || !fakeIPv6s.Contains(fake) {
		t.Fatalf("expected the fake IPv6 address %v, got %+v", fake, parsed.answers)
	}
}

func TestRewriterRemovesServiceBindingRecords(t *testing.T) {
	pool := newRewriterPool(dualStackNetworks(), maximumFakeAddresses)
	for _, kind := range []dnsmessage.Type{httpsRecordTypeForTests, svcbRecordTypeForTests} {
		response := dnsResponse(t, "api.example.com.", kind, []answerSpec{
			{name: "api.example.com.", kind: kind, ttl: 300, rawBytes: []byte{0, 1, 0, 0, 4, 0, 4, 104, 26, 12, 205}},
		})

		rewritten, err := rewriteDNSResponse(response, pool)

		mustBuild(t, err)
		if parsed := parseResponse(t, rewritten); len(parsed.answers) != 0 {
			t.Fatalf("expected no answers for type %d, got %+v", kind, parsed.answers)
		}
	}
}

func TestRewriterKeepsRecordsWithoutAddresses(t *testing.T) {
	pool := newRewriterPool(dualStackNetworks(), maximumFakeAddresses)
	response := dnsResponse(t, "api.example.com.", dnsmessage.TypeTXT, []answerSpec{
		{name: "api.example.com.", kind: dnsmessage.TypeTXT, ttl: 300, text: "v=spf1 -all"},
	})

	rewritten, err := rewriteDNSResponse(response, pool)

	mustBuild(t, err)
	parsed := parseResponse(t, rewritten)
	if len(parsed.answers) != 1 || parsed.answers[0].Body.(*dnsmessage.TXTResource).TXT[0] != "v=spf1 -all" {
		t.Fatalf("expected the TXT record to stay, got %+v", parsed.answers)
	}
}

func TestRewriterDropsTheAdditionalSection(t *testing.T) {
	pool := newRewriterPool(dualStackNetworks(), maximumFakeAddresses)
	response := dnsResponse(t, "api.example.com.", dnsmessage.TypeA,
		[]answerSpec{{name: "api.example.com.", kind: dnsmessage.TypeA, ttl: 30, address: realIPv4}},
		answerSpec{name: "glue.example.com.", kind: dnsmessage.TypeA, ttl: 30, address: otherRealIPv4})

	rewritten, err := rewriteDNSResponse(response, pool)

	mustBuild(t, err)
	if parsed := parseResponse(t, rewritten); len(parsed.additionals) != 0 {
		t.Fatalf("expected no additional records, got %+v", parsed.additionals)
	}
}

func TestRewriterFailsTheQueryWhenThePoolHasNoAddress(t *testing.T) {
	pool := newRewriterPool(dualStackNetworks(), 1)
	pool.fakeFor("first.example.com.", otherRealIPv4)
	response := dnsResponse(t, "api.example.com.", dnsmessage.TypeA, []answerSpec{
		{name: "api.example.com.", kind: dnsmessage.TypeA, ttl: 30, address: realIPv4},
	})

	rewritten, err := rewriteDNSResponse(response, pool)

	mustBuild(t, err)
	parsed := parseResponse(t, rewritten)
	if parsed.header.RCode != dnsmessage.RCodeServerFailure || len(parsed.answers) != 0 {
		t.Fatalf("expected a server failure without answers, got %v %+v", parsed.header.RCode, parsed.answers)
	}
}

func TestRewriterRejectsWhatIsNotAResponse(t *testing.T) {
	pool := newRewriterPool(dualStackNetworks(), maximumFakeAddresses)
	cases := map[string][]byte{
		"query":     dnsQuery(t, "api.example.com.", dnsmessage.TypeA),
		"truncated": dnsResponse(t, "api.example.com.", dnsmessage.TypeA, nil)[:5],
	}
	for name, message := range cases {
		t.Run(name, func(t *testing.T) {
			if _, err := rewriteDNSResponse(message, pool); err == nil {
				t.Fatal("expected an error")
			}
		})
	}
}

func addressOf(record dnsmessage.Resource) netip.Addr {
	switch body := record.Body.(type) {
	case *dnsmessage.AResource:
		return netip.AddrFrom4(body.A)
	case *dnsmessage.AAAAResource:
		return netip.AddrFrom16(body.AAAA)
	}
	return netip.Addr{}
}
