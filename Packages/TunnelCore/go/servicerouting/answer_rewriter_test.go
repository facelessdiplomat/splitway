package servicerouting

import (
	"net/netip"
	"testing"

	"golang.org/x/net/dns/dnsmessage"
)

func TestAnswerRewriterReplacesAddressesWithFakeOnesAndShortensTheirLifetime(t *testing.T) {
	pool := newFakeAddressPool(testPlan)
	response := dnsResponse(t, "api.ipify.org.", dnsmessage.TypeA, func(builder *dnsmessage.Builder) {
		builder.CNAMEResource(answerHeader("api.ipify.org.", dnsmessage.TypeCNAME, 300), dnsmessage.CNAMEResource{CNAME: dnsmessage.MustNewName("api.ipify.org.cdn.cloudflare.net.")})
		builder.AResource(answerHeader("api.ipify.org.cdn.cloudflare.net.", dnsmessage.TypeA, 300), dnsmessage.AResource{A: realAddress.As4()})
	})

	rewritten, err := rewriteAnswers(response, pool)

	if err != nil {
		t.Fatal(err)
	}
	var parser dnsmessage.Parser
	header, _ := parser.Start(rewritten)
	parser.SkipAllQuestions()
	answers, err := parser.AllAnswers()
	if err != nil || header.ID != 0x4242 || len(answers) != 2 {
		t.Fatalf("expected the alias and one address under the same identifier, got %v %v", answers, err)
	}
	address := answers[1].Body.(*dnsmessage.AResource)
	if netip.AddrFrom4(address.A) != pool.fakeFor(realAddress) || answers[1].Header.TTL != maximumAnswerTimeToLive {
		t.Fatalf("expected the fake address with a lifetime of %d s, got %v", maximumAnswerTimeToLive, answers[1])
	}
	if answers[0].Header.TTL != maximumAnswerTimeToLive {
		t.Fatalf("expected the alias to live %d s, got %d", maximumAnswerTimeToLive, answers[0].Header.TTL)
	}
}

func TestAnswerRewriterDropsIPv6AndServiceBindingAnswers(t *testing.T) {
	pool := newFakeAddressPool(testPlan)
	response := dnsResponse(t, "api.ipify.org.", dnsmessage.TypeAAAA, func(builder *dnsmessage.Builder) {
		builder.AAAAResource(answerHeader("api.ipify.org.", dnsmessage.TypeAAAA, 300), dnsmessage.AAAAResource{AAAA: netip.MustParseAddr("2606:4700::6810:a8b").As16()})
		builder.UnknownResource(answerHeader("api.ipify.org.", dnsmessage.Type(65), 300), dnsmessage.UnknownResource{Type: dnsmessage.Type(65), Data: []byte{0, 1, 0}})
	})

	rewritten, err := rewriteAnswers(response, pool)

	if err != nil {
		t.Fatal(err)
	}
	var parser dnsmessage.Parser
	header, _ := parser.Start(rewritten)
	parser.SkipAllQuestions()
	answers, _ := parser.AllAnswers()
	if len(answers) != 0 || header.RCode != dnsmessage.RCodeSuccess {
		t.Fatalf("expected an empty successful answer, got %v", answers)
	}
}
