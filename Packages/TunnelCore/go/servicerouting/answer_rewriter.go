package servicerouting

import (
	"net/netip"

	"golang.org/x/net/dns/dnsmessage"
)

const maximumAnswerTimeToLive = 60

func rewriteAnswers(message []byte, pool *fakeAddressPool) ([]byte, error) {
	var parser dnsmessage.Parser
	header, err := parser.Start(message)
	if err != nil {
		return nil, err
	}
	questions, err := parser.AllQuestions()
	if err != nil {
		return nil, err
	}
	answers, err := parser.AllAnswers()
	if err != nil {
		return nil, err
	}
	builder := dnsmessage.NewBuilder(make([]byte, 0, len(message)), header)
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
		if err := appendAnswer(&builder, answer, pool); err != nil {
			return nil, err
		}
	}
	return builder.Finish()
}

func appendAnswer(builder *dnsmessage.Builder, answer dnsmessage.Resource, pool *fakeAddressPool) error {
	answer.Header.TTL = min(answer.Header.TTL, maximumAnswerTimeToLive)
	switch body := answer.Body.(type) {
	case *dnsmessage.AResource:
		fake := pool.fakeFor(netip.AddrFrom4(body.A))
		return builder.AResource(answer.Header, dnsmessage.AResource{A: fake.As4()})
	case *dnsmessage.CNAMEResource:
		return builder.CNAMEResource(answer.Header, *body)
	}
	return nil
}
