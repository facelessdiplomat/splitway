package servicerouting

import (
	"net/netip"
	"testing"

	"golang.org/x/net/dns/dnsmessage"
)

const testQueryIdentifier = 0x4242

type answerSpec struct {
	name     string
	kind     dnsmessage.Type
	ttl      uint32
	address  netip.Addr
	target   string
	text     string
	rawBytes []byte
}

func dnsQuery(t testing.TB, name string, kind dnsmessage.Type) []byte {
	t.Helper()
	builder := dnsmessage.NewBuilder(nil, dnsmessage.Header{ID: testQueryIdentifier, RecursionDesired: true})
	mustBuild(t, builder.StartQuestions())
	mustBuild(t, builder.Question(dnsmessage.Question{Name: dnsmessage.MustNewName(name), Type: kind, Class: dnsmessage.ClassINET}))
	message, err := builder.Finish()
	mustBuild(t, err)
	return message
}

func dnsResponse(t testing.TB, name string, kind dnsmessage.Type, answers []answerSpec, extras ...answerSpec) []byte {
	t.Helper()
	header := dnsmessage.Header{ID: testQueryIdentifier, Response: true, RecursionDesired: true, RecursionAvailable: true}
	builder := dnsmessage.NewBuilder(nil, header)
	builder.EnableCompression()
	mustBuild(t, builder.StartQuestions())
	mustBuild(t, builder.Question(dnsmessage.Question{Name: dnsmessage.MustNewName(name), Type: kind, Class: dnsmessage.ClassINET}))
	mustBuild(t, builder.StartAnswers())
	for _, answer := range answers {
		appendTestRecord(t, &builder, answer)
	}
	mustBuild(t, builder.StartAuthorities())
	mustBuild(t, builder.StartAdditionals())
	for _, extra := range extras {
		appendTestRecord(t, &builder, extra)
	}
	message, err := builder.Finish()
	mustBuild(t, err)
	return message
}

func appendTestRecord(t testing.TB, builder *dnsmessage.Builder, record answerSpec) {
	t.Helper()
	header := dnsmessage.ResourceHeader{Name: dnsmessage.MustNewName(record.name), Type: record.kind, Class: dnsmessage.ClassINET, TTL: record.ttl}
	switch record.kind {
	case dnsmessage.TypeA:
		mustBuild(t, builder.AResource(header, dnsmessage.AResource{A: record.address.As4()}))
	case dnsmessage.TypeAAAA:
		mustBuild(t, builder.AAAAResource(header, dnsmessage.AAAAResource{AAAA: record.address.As16()}))
	case dnsmessage.TypeCNAME:
		mustBuild(t, builder.CNAMEResource(header, dnsmessage.CNAMEResource{CNAME: dnsmessage.MustNewName(record.target)}))
	case dnsmessage.TypeTXT:
		mustBuild(t, builder.TXTResource(header, dnsmessage.TXTResource{TXT: []string{record.text}}))
	default:
		mustBuild(t, builder.UnknownResource(header, dnsmessage.UnknownResource{Type: record.kind, Data: record.rawBytes}))
	}
}

func mustBuild(t testing.TB, err error) {
	t.Helper()
	if err != nil {
		t.Fatal(err)
	}
}

type parsedResponse struct {
	header      dnsmessage.Header
	answers     []dnsmessage.Resource
	authorities []dnsmessage.Resource
	additionals []dnsmessage.Resource
}

func parseResponse(t *testing.T, message []byte) parsedResponse {
	t.Helper()
	var parser dnsmessage.Parser
	header, err := parser.Start(message)
	mustBuild(t, err)
	mustBuild(t, parser.SkipAllQuestions())
	answers, err := parser.AllAnswers()
	mustBuild(t, err)
	authorities, err := parser.AllAuthorities()
	mustBuild(t, err)
	additionals, err := parser.AllAdditionals()
	mustBuild(t, err)
	return parsedResponse{header: header, answers: answers, authorities: authorities, additionals: additionals}
}
