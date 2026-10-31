package servicerouting

import (
	"errors"
	"net/netip"

	"golang.org/x/net/dns/dnsmessage"
)

const (
	maximumAnswerTimeToLive                  = 60
	rewrittenMessageCapacity                 = 512
	serviceBindingRecordType dnsmessage.Type = 64
	httpsRecordType          dnsmessage.Type = 65
)

var errNotAResponse = errors.New("the message is not a DNS response")

type answerAddresses interface {
	fakeFor(name string, real netip.Addr) (netip.Addr, bool)
	supportsFamilyOf(address netip.Addr) bool
}

type responseRewrite struct {
	addresses answerAddresses
	name      string
	hasIPv4   bool
	hasIPv6   bool
}

func rewriteDNSResponse(message []byte, addresses answerAddresses) ([]byte, error) {
	var parser dnsmessage.Parser
	header, err := parser.Start(message)
	if err != nil {
		return nil, err
	}
	if !header.Response {
		return nil, errNotAResponse
	}
	questions, err := parser.AllQuestions()
	if err != nil {
		return nil, err
	}
	answers, err := parser.AllAnswers()
	if err != nil {
		return nil, err
	}
	authorities, err := parser.AllAuthorities()
	if err != nil {
		return nil, err
	}
	rewrite := responseRewrite{addresses: addresses}
	if len(questions) > 0 {
		rewrite.name = questions[0].Name.String()
	}
	kept, isAnswerable := rewrite.answers(answers)
	if !isAnswerable {
		header.RCode = dnsmessage.RCodeServerFailure
		return buildResponse(header, questions, nil, nil)
	}
	return buildResponse(header, questions, kept, recordsWithoutAddresses(authorities))
}

func (rewrite *responseRewrite) answers(answers []dnsmessage.Resource) ([]dnsmessage.Resource, bool) {
	kept := make([]dnsmessage.Resource, 0, len(answers))
	for _, answer := range answers {
		answer.Header.TTL = min(answer.Header.TTL, maximumAnswerTimeToLive)
		isKept, isAnswerable := rewrite.answer(&answer)
		if !isAnswerable {
			return nil, false
		}
		if isKept {
			kept = append(kept, answer)
		}
	}
	return kept, true
}

func (rewrite *responseRewrite) answer(answer *dnsmessage.Resource) (isKept bool, isAnswerable bool) {
	switch body := answer.Body.(type) {
	case *dnsmessage.AResource:
		if rewrite.hasIPv4 {
			return false, true
		}
		fake, isGiven := rewrite.addresses.fakeFor(rewrite.name, netip.AddrFrom4(body.A))
		if !isGiven {
			return false, false
		}
		answer.Body = &dnsmessage.AResource{A: fake.As4()}
		rewrite.hasIPv4 = true
		return true, true
	case *dnsmessage.AAAAResource:
		real := netip.AddrFrom16(body.AAAA)
		if rewrite.hasIPv6 || !rewrite.addresses.supportsFamilyOf(real) {
			return false, true
		}
		fake, isGiven := rewrite.addresses.fakeFor(rewrite.name, real)
		if !isGiven {
			return false, false
		}
		answer.Body = &dnsmessage.AAAAResource{AAAA: fake.As16()}
		rewrite.hasIPv6 = true
		return true, true
	}
	isServiceBinding := answer.Header.Type == httpsRecordType || answer.Header.Type == serviceBindingRecordType
	return !isServiceBinding, true
}

func recordsWithoutAddresses(records []dnsmessage.Resource) []dnsmessage.Resource {
	kept := records[:0]
	for _, record := range records {
		switch record.Body.(type) {
		case *dnsmessage.SOAResource, *dnsmessage.NSResource:
			kept = append(kept, record)
		}
	}
	return kept
}

func buildResponse(header dnsmessage.Header, questions []dnsmessage.Question, answers, authorities []dnsmessage.Resource) ([]byte, error) {
	builder := dnsmessage.NewBuilder(make([]byte, 0, rewrittenMessageCapacity), header)
	builder.EnableCompression()
	if err := builder.StartQuestions(); err != nil {
		return nil, err
	}
	for _, question := range questions {
		if err := builder.Question(question); err != nil {
			return nil, err
		}
	}
	if err := builder.StartAnswers(); err != nil {
		return nil, err
	}
	for _, answer := range answers {
		if err := appendRecord(&builder, answer); err != nil {
			return nil, err
		}
	}
	if err := builder.StartAuthorities(); err != nil {
		return nil, err
	}
	for _, authority := range authorities {
		if err := appendRecord(&builder, authority); err != nil {
			return nil, err
		}
	}
	return builder.Finish()
}

func appendRecord(builder *dnsmessage.Builder, record dnsmessage.Resource) error {
	switch body := record.Body.(type) {
	case *dnsmessage.AResource:
		return builder.AResource(record.Header, *body)
	case *dnsmessage.AAAAResource:
		return builder.AAAAResource(record.Header, *body)
	case *dnsmessage.CNAMEResource:
		return builder.CNAMEResource(record.Header, *body)
	case *dnsmessage.MXResource:
		return builder.MXResource(record.Header, *body)
	case *dnsmessage.NSResource:
		return builder.NSResource(record.Header, *body)
	case *dnsmessage.PTRResource:
		return builder.PTRResource(record.Header, *body)
	case *dnsmessage.SOAResource:
		return builder.SOAResource(record.Header, *body)
	case *dnsmessage.SRVResource:
		return builder.SRVResource(record.Header, *body)
	case *dnsmessage.TXTResource:
		return builder.TXTResource(record.Header, *body)
	case *dnsmessage.UnknownResource:
		return builder.UnknownResource(record.Header, *body)
	}
	return nil
}
