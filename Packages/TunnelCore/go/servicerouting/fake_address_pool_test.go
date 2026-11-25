package servicerouting

import (
	"fmt"
	"net/netip"
	"testing"
	"time"
)

var (
	otherRealIPv4 = netip.MustParseAddr("203.0.113.20")
	thirdRealIPv4 = netip.MustParseAddr("203.0.113.30")
)

func newPoolFixture(capacity int, networks fakeNetworks) (*fakeAddressPool, *manualClock) {
	clock := &manualClock{current: time.Unix(1_800_000_000, 0)}
	return newFakeAddressPool(networks, clock.now, capacity), clock
}

func dualStackNetworks() fakeNetworks {
	return fakeNetworks{ipv4: fakeIPv4s, ipv6: fakeIPv6s}
}

func mustFake(t *testing.T, pool *fakeAddressPool, name string, real netip.Addr) netip.Addr {
	t.Helper()
	fake, isGiven := pool.fakeFor(name, real)
	if !isGiven {
		t.Fatalf("expected a fake address for %s", name)
	}
	return fake
}

func TestPoolGivesOneFakeAddressPerName(t *testing.T) {
	pool, _ := newPoolFixture(maximumFakeAddresses, dualStackNetworks())

	first := mustFake(t, pool, "api.example.com.", realIPv4)
	again := mustFake(t, pool, "api.example.com.", realIPv4)
	other := mustFake(t, pool, "cdn.example.com.", realIPv4)

	if first != again || first == other {
		t.Fatalf("expected one address per name, got %v, %v and %v", first, again, other)
	}
}

func TestPoolIgnoresTheCaseOfNames(t *testing.T) {
	pool, _ := newPoolFixture(maximumFakeAddresses, dualStackNetworks())

	lower := mustFake(t, pool, "api.example.com.", realIPv4)
	upper := mustFake(t, pool, "API.Example.COM.", realIPv4)

	if lower != upper {
		t.Fatalf("expected the same address for both spellings, got %v and %v", lower, upper)
	}
}

func TestPoolSendsAFakeAddressToTheLatestAnswer(t *testing.T) {
	pool, _ := newPoolFixture(maximumFakeAddresses, dualStackNetworks())
	fake := mustFake(t, pool, "api.example.com.", realIPv4)

	mustFake(t, pool, "api.example.com.", otherRealIPv4)

	if real, isKnown := pool.realAddress(fake); !isKnown || real != otherRealIPv4 {
		t.Fatalf("expected %v, got %v known %v", otherRealIPv4, real, isKnown)
	}
}

func TestPoolTakesAddressesAfterTheReservedRangeOfEachNetwork(t *testing.T) {
	pool, _ := newPoolFixture(maximumFakeAddresses, dualStackNetworks())

	ipv4 := mustFake(t, pool, "api.example.com.", realIPv4)
	ipv6 := mustFake(t, pool, "api.example.com.", realIPv6)

	if ipv4 != netip.MustParseAddr("198.18.1.0") || ipv6 != netip.MustParseAddr("fdc6:8b52::100") {
		t.Fatalf("expected the first addresses after the reserved range, got %v and %v", ipv4, ipv6)
	}
}

func TestPoolHasNoIPv6AddressesWithoutAnIPv6Network(t *testing.T) {
	pool, _ := newPoolFixture(maximumFakeAddresses, fakeNetworks{ipv4: fakeIPv4s})

	if fake, isGiven := pool.fakeFor("api.example.com.", realIPv6); isGiven {
		t.Fatalf("expected no IPv6 fake address, got %v", fake)
	}
}

func TestPoolKnowsOnlyTheAddressesItGave(t *testing.T) {
	pool, _ := newPoolFixture(maximumFakeAddresses, dualStackNetworks())

	if real, isKnown := pool.realAddress(fakeIPv4); isKnown {
		t.Fatalf("expected an unknown fake address, got %v", real)
	}
}

func TestPoolForgetsTheLeastRecentlyAnsweredNameWhenFull(t *testing.T) {
	pool, clock := newPoolFixture(2, dualStackNetworks())
	first := mustFake(t, pool, "first.example.com.", realIPv4)
	clock.advance(time.Second)
	second := mustFake(t, pool, "second.example.com.", otherRealIPv4)
	clock.advance(minimumFakeAddressLifetime)

	third := mustFake(t, pool, "third.example.com.", thirdRealIPv4)

	_, isFirstKnown := pool.realAddress(first)
	_, isSecondKnown := pool.realAddress(second)
	if real, _ := pool.realAddress(third); isFirstKnown || !isSecondKnown || real != thirdRealIPv4 {
		t.Fatalf("expected only the first name forgotten, known %v and %v, third leads to %v", isFirstKnown, isSecondKnown, real)
	}
}

func TestPoolDoesNotHandOutAForgottenAddressRightAway(t *testing.T) {
	pool, clock := newPoolFixture(1, dualStackNetworks())
	first := mustFake(t, pool, "first.example.com.", realIPv4)
	clock.advance(minimumFakeAddressLifetime)

	second := mustFake(t, pool, "second.example.com.", otherRealIPv4)

	if second == first {
		t.Fatalf("expected a fresh address instead of the forgotten %v", first)
	}
}

func TestPoolWrapsAroundASmallNetwork(t *testing.T) {
	networks := fakeNetworks{ipv4: netip.MustParsePrefix("198.18.0.0/23")}
	pool, clock := newPoolFixture(maximumFakeAddresses, networks)
	given := map[netip.Addr]bool{}
	for index := range reservedFakeAddressCount {
		given[mustFake(t, pool, fmt.Sprintf("name%d.example.com.", index), realIPv4)] = true
	}
	clock.advance(minimumFakeAddressLifetime)

	_, isGivenWhenExhausted := pool.fakeFor("one.more.example.com.", realIPv4)

	if len(given) != reservedFakeAddressCount || !isGivenWhenExhausted {
		t.Fatalf("expected %d distinct addresses and one more after the oldest expired, got %d and %v",
			reservedFakeAddressCount, len(given), isGivenWhenExhausted)
	}
}

func TestPoolKeepsAnAddressWithOpenConnections(t *testing.T) {
	pool, clock := newPoolFixture(1, dualStackNetworks())
	fake := mustFake(t, pool, "first.example.com.", realIPv4)
	pool.connectionOpened(fake)
	clock.advance(2 * minimumFakeAddressLifetime)

	_, isGivenWhileOpen := pool.fakeFor("second.example.com.", otherRealIPv4)
	pool.connectionClosed(fake)
	_, isGivenAfterClose := pool.fakeFor("second.example.com.", otherRealIPv4)

	if isGivenWhileOpen || !isGivenAfterClose {
		t.Fatalf("expected the address held while open and free after close, got %v and %v", isGivenWhileOpen, isGivenAfterClose)
	}
}

func TestPoolKeepsARecentlyAnsweredAddress(t *testing.T) {
	pool, clock := newPoolFixture(1, dualStackNetworks())
	mustFake(t, pool, "first.example.com.", realIPv4)
	clock.advance(minimumFakeAddressLifetime - time.Second)

	if fake, isGiven := pool.fakeFor("second.example.com.", otherRealIPv4); isGiven {
		t.Fatalf("expected no address while the first answer is recent, got %v", fake)
	}
}

func TestPoolKeepsTheFamiliesApart(t *testing.T) {
	pool, _ := newPoolFixture(1, dualStackNetworks())
	mustFake(t, pool, "first.example.com.", realIPv4)

	if _, isGiven := pool.fakeFor("first.example.com.", realIPv6); !isGiven {
		t.Fatal("expected an IPv6 address next to a full IPv4 family")
	}
}
