package servicerouting

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"net/netip"
)

const planDocumentVersion = 1

var (
	ErrUnsupportedPlanVersion = errors.New("unsupported service routing plan version")
	ErrMalformedPlan          = errors.New("malformed service routing plan")
)

type planDocumentHeader struct {
	Version int `json:"version"`
}

type planDocument struct {
	Version          int          `json:"version"`
	VirtualResolver  netip.Addr   `json:"virtualResolver"`
	UpstreamResolver netip.Addr   `json:"upstreamResolver"`
	FakeIPv4Network  netip.Prefix `json:"fakeIPv4Network"`
	FakeIPv6Network  netip.Prefix `json:"fakeIPv6Network"`
}

func DecodePlan(document []byte) (Plan, error) {
	var header planDocumentHeader
	if err := json.Unmarshal(document, &header); err != nil {
		return Plan{}, fmt.Errorf("%w: %w", ErrMalformedPlan, err)
	}
	if header.Version != planDocumentVersion {
		return Plan{}, fmt.Errorf("%w: %d", ErrUnsupportedPlanVersion, header.Version)
	}
	decoder := json.NewDecoder(bytes.NewReader(document))
	decoder.DisallowUnknownFields()
	var decoded planDocument
	if err := decoder.Decode(&decoded); err != nil {
		return Plan{}, fmt.Errorf("%w: %w", ErrMalformedPlan, err)
	}
	return Plan{
		VirtualDNS:      decoded.VirtualResolver,
		UpstreamDNS:     decoded.UpstreamResolver,
		FakeIPv4Network: decoded.FakeIPv4Network,
		FakeIPv6Network: decoded.FakeIPv6Network,
	}, nil
}
