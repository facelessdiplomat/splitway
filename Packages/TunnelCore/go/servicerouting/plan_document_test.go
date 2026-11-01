package servicerouting

import (
	"errors"
	"net/netip"
	"os"
	"testing"
)

func TestDecodesThePlansThatSplitwayEncodes(t *testing.T) {
	cases := map[string]Plan{
		"plan.json": {
			VirtualDNS:      netip.MustParseAddr("198.18.0.2"),
			UpstreamDNS:     netip.MustParseAddr("10.64.0.1"),
			FakeIPv4Network: netip.MustParsePrefix("198.18.0.0/15"),
			FakeIPv6Network: netip.MustParsePrefix("2001:2::/48"),
		},
		"plan-without-ipv6.json": {
			VirtualDNS:      netip.MustParseAddr("198.19.0.2"),
			UpstreamDNS:     netip.MustParseAddr("1.1.1.1"),
			FakeIPv4Network: netip.MustParsePrefix("198.19.0.0/16"),
		},
	}
	for fixture, expected := range cases {
		t.Run(fixture, func(t *testing.T) {
			document, err := os.ReadFile("testdata/" + fixture)
			if err != nil {
				t.Fatal(err)
			}

			plan, err := DecodePlan(document)

			if err != nil {
				t.Fatal(err)
			}
			if plan != expected {
				t.Fatalf("expected %+v, got %+v", expected, plan)
			}
			if err := plan.validate(); err != nil {
				t.Fatalf("expected the fixture to be a valid plan: %v", err)
			}
		})
	}
}

func TestRejectsAPlanOfAnotherVersion(t *testing.T) {
	cases := map[string]string{
		"newer version":         `{"version":2,"virtualResolver":"198.18.0.2","upstreamResolver":"1.1.1.1","fakeIPv4Network":"198.18.0.0/15"}`,
		"newer version, fields": `{"version":2,"virtualResolver":"198.18.0.2","resolverPort":5353}`,
		"no version":            `{"virtualResolver":"198.18.0.2","upstreamResolver":"1.1.1.1","fakeIPv4Network":"198.18.0.0/15"}`,
	}
	for name, document := range cases {
		t.Run(name, func(t *testing.T) {
			_, err := DecodePlan([]byte(document))

			if !errors.Is(err, ErrUnsupportedPlanVersion) {
				t.Fatalf("expected an unsupported version, got %v", err)
			}
		})
	}
}

func TestRejectsAMalformedPlan(t *testing.T) {
	cases := map[string]string{
		"not JSON":          `version=1`,
		"version as text":   `{"version":"1"}`,
		"unknown field":     `{"version":1,"virtualDNS":"198.18.0.2"}`,
		"malformed address": `{"version":1,"virtualResolver":"198.18.0.300"}`,
		"malformed network": `{"version":1,"fakeIPv4Network":"198.18.0.0/33"}`,
	}
	for name, document := range cases {
		t.Run(name, func(t *testing.T) {
			_, err := DecodePlan([]byte(document))

			if !errors.Is(err, ErrMalformedPlan) {
				t.Fatalf("expected a malformed plan, got %v", err)
			}
		})
	}
}
