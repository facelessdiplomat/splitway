package servicerouting

import (
	"net/netip"
	"testing"
)

func TestFakeAddressPoolGivesEachRealAddressItsOwnFakeAddress(t *testing.T) {
	pool := newFakeAddressPool(testPlan)
	first, second := netip.MustParseAddr("104.26.12.205"), netip.MustParseAddr("172.67.74.152")

	firstFake, secondFake, again := pool.fakeFor(first), pool.fakeFor(second), pool.fakeFor(first)

	if firstFake == secondFake || firstFake != again {
		t.Fatalf("expected distinct and stable fake addresses, got %v, %v, %v", firstFake, secondFake, again)
	}
	if !testPlan.FakeNetwork.Contains(firstFake) || firstFake == testPlan.VirtualDNS {
		t.Fatalf("expected a fake address inside %v and apart from the virtual DNS, got %v", testPlan.FakeNetwork, firstFake)
	}
	if real, ok := pool.realFor(firstFake); !ok || real != first {
		t.Fatalf("expected %v behind %v, got %v ok=%v", first, firstFake, real, ok)
	}
}

func TestFakeAddressPoolKnowsNothingAboutAnUnusedFakeAddress(t *testing.T) {
	pool := newFakeAddressPool(testPlan)

	if real, ok := pool.realFor(netip.MustParseAddr("198.19.200.1")); ok {
		t.Fatalf("expected no real address, got %v", real)
	}
}
